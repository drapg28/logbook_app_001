import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:mongo_dart/mongo_dart.dart';

import 'package:logbook_app_001/features/logbook/models/log_models.dart';
import 'package:logbook_app_001/helpers/log_helper.dart';

class MongoService {
  static final MongoService _instance = MongoService._internal();
  factory MongoService() => _instance;
  MongoService._internal();
  Db? _db;
  DbCollection? _collection;

  static const String _src = 'mongo_service.dart';

  Future<DbCollection> _safeCollection() async {
    if (_db == null || !_db!.isConnected || _collection == null) {
      await LogHelper.writeLog(
        'Koleksi belum siap — mencoba reconnect...',
        source: _src,
        level: 3,
      );
      await connect();
    }
    return _collection!;
  }

  Future<void> connect() async {
    try {
      final String? dbUri = dotenv.env['MONGODB_URI'];
      if (dbUri == null || dbUri.isEmpty) {
        throw Exception('MONGODB_URI tidak ditemukan di .env');
      }

      _db = await Db.create(dbUri);
      await _db!.open().timeout(
            const Duration(seconds: 15),
            onTimeout: () => throw Exception(
              'Koneksi Timeout. Periksa IP Whitelist (0.0.0.0/0) atau sinyal.',
            ),
          );

      _collection = _db!.collection('logs');

      await LogHelper.writeLog(
        'DATABASE: Terhubung & Koleksi Siap',
        source: _src,
        level: 2,
      );
    } catch (e) {
      await LogHelper.writeLog(
        'DATABASE: Gagal Koneksi — $e',
        source: _src,
        level: 1,
      );
      rethrow;
    }
  }

  Future<void> close() async {
    if (_db != null) {
      await _db!.close();
      await LogHelper.writeLog(
        'DATABASE: Koneksi ditutup',
        source: _src,
        level: 2,
      );
    }
  }

  String _cleanId(String id) {
    final match = RegExp(r'ObjectId\("([a-f0-9]{24})"\)').firstMatch(id);
    if (match != null) return match.group(1)!;
    return id;
  }

  Future<List<LogModel>> getLogs(String teamId) async {
    try {
      final DbCollection col = await _safeCollection();

      await LogHelper.writeLog(
        'INFO: Fetching data untuk Team: $teamId...',
        source: _src,
        level: 3,
      );

      final List<Map<String, dynamic>> data =
          await col.find(where.eq('teamId', teamId)).toList();

      final List<LogModel> result =
          data.map((json) => LogModel.fromMap(json)).toList();

      await LogHelper.writeLog(
        'INFO: ${result.length} dokumen team $teamId berhasil dimuat',
        source: _src,
        level: 3,
      );

      return result;
    } catch (e) {
      await LogHelper.writeLog(
        'ERROR: Fetch gagal — $e',
        source: _src,
        level: 1,
      );
      return [];
    }
  }

  Future<void> insertLog(LogModel log) async {
    try {
      final DbCollection col = await _safeCollection();

      final map = log.toMap();
      if (log.id != null && log.id!.isNotEmpty) {
        map['_id'] = ObjectId.fromHexString(_cleanId(log.id!));
      } else {
        map['_id'] = ObjectId();
      }

      await col.insertOne(map);

      await LogHelper.writeLog(
        "SUCCESS: Data '${log.title}' tersimpan di Cloud",
        source: _src,
        level: 2,
      );
    } catch (e) {
      await LogHelper.writeLog(
        'ERROR: Insert gagal — $e',
        source: _src,
        level: 1,
      );
      rethrow;
    }
  }

  Future<void> updateLog(LogModel log) async {
    try {
      if (log.id == null || log.id!.isEmpty) {
        throw Exception('ID Log tidak ditemukan untuk proses update');
      }

      final DbCollection col = await _safeCollection();

      final map = log.toMap();
      final objectId = ObjectId.fromHexString(_cleanId(log.id!)); // ← FIX
      map['_id'] = objectId;

      await col.replaceOne(where.id(objectId), map);

      await LogHelper.writeLog(
        "DATABASE: Update '${log.title}' berhasil",
        source: _src,
        level: 2,
      );
    } catch (e) {
      await LogHelper.writeLog(
        'DATABASE: Update gagal — $e',
        source: _src,
        level: 1,
      );
      rethrow;
    }
  }

  Future<void> deleteLog(String id) async {
    try {
      final DbCollection col = await _safeCollection();

      final cleanedId = _cleanId(id); // ← FIX: strip ObjectId("...") dulu
      await col.remove(where.id(ObjectId.fromHexString(cleanedId)));

      await LogHelper.writeLog(
        'DATABASE: Hapus ID $cleanedId berhasil',
        source: _src,
        level: 2,
      );
    } catch (e) {
      await LogHelper.writeLog(
        'DATABASE: Hapus gagal — $e',
        source: _src,
        level: 1,
      );
      rethrow;
    }
  }
}