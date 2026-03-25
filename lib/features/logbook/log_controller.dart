import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:hive/hive.dart';
import 'package:mongo_dart/mongo_dart.dart' show ObjectId;

import 'package:logbook_app_001/features/logbook/models/log_models.dart';
import 'package:logbook_app_001/helpers/log_helper.dart';
import 'package:logbook_app_001/services/mongo_service.dart';

class LogController {
  final ValueNotifier<List<LogModel>> logsNotifier =
      ValueNotifier<List<LogModel>>([]);

  // Referensi ke Hive box (offline storage)
  final Box<LogModel> _box = Hive.box<LogModel>('offline_logs');

  bool isOffline = false;

  static const String _src = 'log_controller.dart';

  // Connectivity listener untuk background sync otomatis
  StreamSubscription? _connectivitySub;
  String _currentTeamId = '';

  // ── SRP: Filter & Visibility Logic (dipindah dari View ke Controller) ──

  /// Mengembalikan list log yang boleh dilihat oleh [currentUid]
  /// sesuai aturan privacy (isPublic atau milik sendiri),
  /// lalu difilter berdasarkan [searchQuery].
  List<LogModel> getVisibleLogs(String currentUid, String searchQuery) {
    // Tampilkan: milik sendiri ATAU berstatus publik
    final visible = logsNotifier.value
        .where((log) => log.authorId == currentUid || log.isPublic)
        .toList();

    if (searchQuery.isEmpty) return visible;

    // FIX: search juga ngecek description, bukan cuma title
    // Strip karakter Markdown dulu biar "**tebal**" bisa ditemukan lewat "tebal"
    return visible.where((log) {
      final titleMatch = log.title.toLowerCase().contains(searchQuery);
      // Hapus simbol markdown: **, *, ##, __, [], (), dll
      final plainDesc = log.description
          .replaceAll(RegExp(r'[*#_\[\]()~`>]'), '')
          .toLowerCase();
      final descMatch = plainDesc.contains(searchQuery);
      return titleMatch || descMatch;
    }).toList();
  }

  // ── Connectivity Listener ──────────────────────────────────────────────

  /// Mulai memantau perubahan koneksi internet.
  /// Saat internet kembali aktif → otomatis sync dari Cloud.
  void startConnectivityListener(String teamId) {
    _currentTeamId = teamId;
    _connectivitySub = Connectivity().onConnectivityChanged.listen((result) {
      if (result != ConnectivityResult.none && isOffline) {
        LogHelper.writeLog(
          'CONNECTIVITY: Internet kembali aktif — memulai sync...',
          source: _src,
          level: 2,
        );
        loadLogs(_currentTeamId);
      }
    });
  }

  /// Hentikan listener saat halaman di-dispose untuk mencegah memory leak
  void dispose() {
    _connectivitySub?.cancel();
  }

  // ── LOAD DATA (Offline-First Strategy) ───────────────────────────────

  Future<void> loadLogs(String teamId) async {
    _currentTeamId = teamId;

    // Langkah 1: Tampilkan data Hive dulu (instan, tanpa internet)
    final localData = _box.values
        .where((log) => log.teamId == teamId)
        .toList();
    logsNotifier.value = localData;

    // Langkah 2: Sync dari Cloud di background
    try {
      await MongoService().connect().timeout(
            const Duration(seconds: 15),
            onTimeout: () => throw Exception(
              'Koneksi Cloud Timeout. Periksa sinyal atau IP Whitelist.',
            ),
          );

      isOffline = false;
      final cloudData = await MongoService().getLogs(teamId);

      // Update Hive dengan data terbaru dari Cloud
      await _box.clear();
      for (final log in cloudData) {
        await _box.add(log);
      }

      logsNotifier.value = cloudData;

      await LogHelper.writeLog(
        'SYNC: Data berhasil diperbarui dari Atlas',
        source: _src,
        level: 2,
      );
    } catch (e) {
      isOffline = true;
      await LogHelper.writeLog(
        'OFFLINE: Menggunakan data cache lokal — $e',
        source: _src,
        level: 1,
      );
    }
  }

  // ── ADD DATA (Instant Local + Background Cloud) ───────────────────────

  Future<void> addLog(
    String title,
    String description,
    String category,
    String authorId,
    String teamId,
    bool isPublic,
  ) async {
    final LogModel newLog = LogModel(
      id: ObjectId().oid,
      title: title,
      description: description,
      category: category,
      date: DateTime.now().toIso8601String(),
      authorId: authorId,
      teamId: teamId,
      isPublic: isPublic,
    );

    // ACTION 1: Simpan ke Hive (Instan)
    await _box.add(newLog);
    logsNotifier.value = [...logsNotifier.value, newLog];

    // ACTION 2: Kirim ke MongoDB Atlas (Background)
    try {
      await MongoService().insertLog(newLog);
      await LogHelper.writeLog(
        "SUCCESS: '${newLog.title}' tersinkron ke Cloud",
        source: _src,
      );
    } catch (e) {
      await LogHelper.writeLog(
        'WARNING: Data tersimpan lokal, akan sinkron saat online — $e',
        source: _src,
        level: 1,
      );
    }
  }

  // ── UPDATE DATA ────────────────────────────────────────────────────────

  Future<void> updateLog(
    int index,
    String title,
    String description,
    String category,
    bool isPublic,
  ) async {
    final LogModel oldLog = logsNotifier.value[index];
    final LogModel updatedLog = LogModel(
      id: oldLog.id,
      title: title,
      description: description,
      category: category,
      date: oldLog.date,
      authorId: oldLog.authorId,
      teamId: oldLog.teamId,
      isPublic: isPublic,
    );

    // Update di Hive
    final hiveIndex =
        _box.values.toList().indexWhere((l) => l.id == oldLog.id);
    if (hiveIndex >= 0) await _box.putAt(hiveIndex, updatedLog);

    final newList = List<LogModel>.from(logsNotifier.value);
    newList[index] = updatedLog;
    logsNotifier.value = newList;

    // Update ke Cloud (background)
    try {
      await MongoService().updateLog(updatedLog);
      await LogHelper.writeLog(
        "SUCCESS: Update '${oldLog.title}' berhasil",
        source: _src,
        level: 2,
      );
    } catch (e) {
      await LogHelper.writeLog(
        'ERROR: Gagal update ke Cloud — $e',
        source: _src,
        level: 1,
      );
    }
  }

  // ── DELETE DATA ────────────────────────────────────────────────────────

  Future<void> removeLog(int index) async {
    final LogModel target = logsNotifier.value[index];

    if (target.id == null) {
      await LogHelper.writeLog(
        'ERROR: ID null, tidak bisa hapus',
        source: _src,
        level: 1,
      );
      return;
    }

    // Hapus dari Hive
    final hiveIndex =
        _box.values.toList().indexWhere((l) => l.id == target.id);
    if (hiveIndex >= 0) await _box.deleteAt(hiveIndex);

    final newList = List<LogModel>.from(logsNotifier.value)..removeAt(index);
    logsNotifier.value = newList;

    // Hapus dari Cloud (background)
    try {
      await MongoService().deleteLog(target.id!);
      await LogHelper.writeLog(
        "SUCCESS: Hapus '${target.title}' berhasil",
        source: _src,
        level: 2,
      );
    } catch (e) {
      await LogHelper.writeLog(
        'ERROR: Gagal hapus dari Cloud — $e',
        source: _src,
        level: 1,
      );
    }
  }
}