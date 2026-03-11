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
      rethrow; // Lempar ke Controller agar bisa set isOffline = true
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

  Future<List<LogModel>> getLogs() async {
    try {
      final DbCollection col = await _safeCollection();

      await LogHelper.writeLog(
        'INFO: Fetching semua data dari Cloud...',
        source: _src,
        level: 3,
      );

      final List<Map<String, dynamic>> data = await col.find().toList();
      final List<LogModel> result =
          data.map((json) => LogModel.fromMap(json)).toList();

      await LogHelper.writeLog(
        'INFO: ${result.length} dokumen berhasil dimuat',
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
      await col.insertOne(log.toMap());

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
      if (log.id == null) {
        throw Exception('ID Log tidak ditemukan untuk proses update');
      }

      final DbCollection col = await _safeCollection();
      await col.replaceOne(where.id(log.id!), log.toMap());

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

  Future<void> deleteLog(ObjectId id) async {
    try {
      final DbCollection col = await _safeCollection();
      await col.remove(where.id(id));

      await LogHelper.writeLog(
        'DATABASE: Hapus ID $id berhasil',
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