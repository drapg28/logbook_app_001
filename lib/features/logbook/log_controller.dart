import 'package:flutter/material.dart';
import 'package:mongo_dart/mongo_dart.dart';
import 'package:logbook_app_001/features/logbook/models/log_models.dart';
import 'package:logbook_app_001/services/mongo_service.dart';
import 'package:logbook_app_001/helpers/log_helper.dart';

class LogController {
  // Tetap pakai ValueNotifier agar reaktivitas UI tidak berubah
  final ValueNotifier<List<LogModel>> logsNotifier = ValueNotifier<List<LogModel>>([]);

  List<LogModel> get logs => logsNotifier.value;

  // Task 3: Load dari Cloud saat aplikasi dibuka
  Future<void> loadFromCloud() async {
    final cloudData = await MongoService().getLogs();
    logsNotifier.value = cloudData;
  }

  // Task 3: Tambah data ke Cloud dan update UI
  Future<void> addLog(String title, String desc, String category) async {
    final newLog = LogModel(
      id: ObjectId(),
      title: title,
      description: desc,
      category: category,
      date: DateTime.now().toString(),
    );

    await MongoService().insertLog(newLog);
    await loadFromCloud(); // Refresh data dari Cloud
    await LogHelper.writeLog("SUCCESS: Data tersimpan di Cloud", source: "log_controller.dart");
  }

  // Task 3: Update data di Cloud
  Future<void> updateLog(int index, String title, String desc, String category) async {
    final oldLog = logs[index];
    final updatedLog = LogModel(
      id: oldLog.id, // ID lama wajib dibawa agar tidak buat data baru
      title: title,
      description: desc,
      category: category,
      date: oldLog.date,
    );

    await MongoService().updateLog(updatedLog);
    await loadFromCloud();
  }

  // Task 3: Hapus data dari Cloud
  Future<void> removeLog(int index) async {
    final targetId = logs[index].id;
    if (targetId != null) {
      await MongoService().deleteLog(targetId);
      await loadFromCloud();
    }
  }
}