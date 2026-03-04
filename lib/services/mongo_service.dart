import 'package:mongo_dart/mongo_dart.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:logbook_app_001/features/logbook/models/log_models.dart';
import 'package:logbook_app_001/helpers/log_helper.dart';

class MongoService {
  static final MongoService _instance = MongoService._internal();
  Db? _db;
  DbCollection? _collection;
  final String _source = "mongo_service.dart";

  factory MongoService() => _instance;
  MongoService._internal();

  Future<DbCollection> _getSafeCollection() async {
    if (_db == null || !_db!.isConnected || _collection == null) {
      await connect();
    }
    return _collection!;
  }

  Future<void> connect() async {
    try {
      final dbUri = dotenv.env['MONGODB_URI'];
      if (dbUri == null) throw Exception("MONGODB_URI tidak ditemukan");
      _db = await Db.create(dbUri);
      await _db!.open().timeout(const Duration(seconds: 15));
      _collection = _db!.collection('logs');
      await LogHelper.writeLog("DATABASE: Terhubung", source: _source);
    } catch (e) {
      await LogHelper.writeLog("DATABASE: Gagal - $e", source: _source, level: 1);
      rethrow;
    }
  }

  // Task 3: READ data dari Cloud
  Future<List<LogModel>> getLogs() async {
    try {
      final collection = await _getSafeCollection();
      final List<Map<String, dynamic>> data = await collection.find().toList();
      return data.map((json) => LogModel.fromMap(json)).toList();
    } catch (e) {
      await LogHelper.writeLog("FETCH FAILED: $e", source: _source, level: 1);
      return [];
    }
  }

  // Task 3: CREATE data ke Cloud
  Future<void> insertLog(LogModel log) async {
    final collection = await _getSafeCollection();
    await collection.insertOne(log.toMap());
  }

  // Task 3: UPDATE data di Cloud
  Future<void> updateLog(LogModel log) async {
    final collection = await _getSafeCollection();
    if (log.id != null) {
      await collection.replaceOne(where.id(log.id!), log.toMap());
    }
  }

  // Task 3: DELETE data di Cloud
  Future<void> deleteLog(ObjectId id) async {
    final collection = await _getSafeCollection();
    await collection.remove(where.id(id));
  }

  Future<void> close() async {
    await _db?.close();
  }
}