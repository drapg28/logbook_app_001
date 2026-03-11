import 'package:flutter/foundation.dart';
import 'package:mongo_dart/mongo_dart.dart';

import 'package:logbook_app_001/features/logbook/models/log_models.dart';
import 'package:logbook_app_001/helpers/log_helper.dart';
import 'package:logbook_app_001/services/mongo_service.dart';

class LogController {
  final ValueNotifier<List<LogModel>> logsNotifier =
      ValueNotifier<List<LogModel>>([]);

  bool isOffline = false;

  static const String _src = 'log_controller.dart';

  Future<void> initSession() async {
    try {
      await LogHelper.writeLog(
        'UI: Memulai inisialisasi sesi Cloud...',
        source: _src,
      );

      await MongoService().connect().timeout(
            const Duration(seconds: 15),
            onTimeout: () => throw Exception(
              'Koneksi Cloud Timeout. Periksa sinyal atau IP Whitelist.',
            ),
          );

      isOffline = false;
      await loadFromCloud();

      await LogHelper.writeLog(
        'UI: Sesi Cloud berhasil — data dimuat ke Notifier',
        source: _src,
      );
    } catch (e) {
      isOffline = true;
      await LogHelper.writeLog(
        'UI: Gagal inisialisasi (Offline Mode) — $e',
        source: _src,
        level: 1,
      );
    }
  }

  Future<void> refreshSession() async {
    try {
      await MongoService().connect().timeout(
            const Duration(seconds: 15),
            onTimeout: () => throw Exception(
              'Koneksi Cloud Timeout. Periksa sinyal atau IP Whitelist.',
            ),
          );

      isOffline = false;
      await loadFromCloud();

      await LogHelper.writeLog(
        'Refresh berhasil — data diperbarui dari Cloud',
        source: _src,
      );
    } catch (e) {
      isOffline = true;
      await LogHelper.writeLog(
        'Refresh gagal (Offline) — $e',
        source: _src,
        level: 1,
      );
      rethrow;
    }
  }


  Future<void> loadFromCloud() async {
    final List<LogModel> cloudData = await MongoService().getLogs();
    logsNotifier.value = cloudData;
  }

  Future<void> addLog(
    String title,
    String description,
    String category,
  ) async {
    final LogModel newLog = LogModel(
      id: ObjectId(),
      title: title,
      description: description,
      category: category,
      date: DateTime.now().toIso8601String(),
    );

    try {
      await MongoService().insertLog(newLog);
      await loadFromCloud(); // Sinkronisasi langsung dari Cloud

      await LogHelper.writeLog(
        "SUCCESS: Tambah data '${newLog.title}'",
        source: _src,
      );
    } catch (e) {
      await LogHelper.writeLog(
        'ERROR: Gagal tambah data — $e',
        source: _src,
        level: 1,
      );
    }
  }

  Future<void> updateLog(
    int index,
    String title,
    String description,
    String category,
  ) async {
    final LogModel oldLog = logsNotifier.value[index];
    final LogModel updatedLog = LogModel(
      id: oldLog.id,
      title: title,
      description: description,
      category: category,
      date: oldLog.date, // Pertahankan tanggal asli
    );

    try {
      await MongoService().updateLog(updatedLog);
      await loadFromCloud();

      await LogHelper.writeLog(
        "SUCCESS: Update '${oldLog.title}' berhasil",
        source: _src,
        level: 2,
      );
    } catch (e) {
      await LogHelper.writeLog(
        'ERROR: Gagal update — $e',
        source: _src,
        level: 1,
      );
    }
  }

  Future<void> removeLog(int index) async {
    final LogModel target = logsNotifier.value[index];

    if (target.id == null) {
      await LogHelper.writeLog(
        'ERROR: ID null, tidak bisa hapus dari Cloud',
        source: _src,
        level: 1,
      );
      return;
    }

    try {
      await MongoService().deleteLog(target.id!);
      await loadFromCloud();

      await LogHelper.writeLog(
        "SUCCESS: Hapus '${target.title}' berhasil",
        source: _src,
        level: 2,
      );
    } catch (e) {
      await LogHelper.writeLog(
        'ERROR: Gagal hapus — $e',
        source: _src,
        level: 1,
      );
    }
  }
}