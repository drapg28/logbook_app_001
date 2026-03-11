import 'dart:developer' as dev;
import 'dart:io';

import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:intl/intl.dart';

class LogHelper {
  static Future<void> writeLog(
    String message, {
    String source = "Unknown",
    int level = 2,
  }) async {
    final int configLevel =
        int.tryParse(dotenv.env['LOG_LEVEL'] ?? '2') ?? 2;

    if (level > configLevel) return;

    final String muteRaw = dotenv.env['LOG_MUTE'] ?? '';
    final List<String> muteList =
        muteRaw.split(',').map((e) => e.trim()).toList();

    if (muteList.contains(source)) return;
    try {
      final String timestamp = DateFormat('HH:mm:ss').format(DateTime.now());
      final String label = _getLabel(level);
      final String color = _getColor(level);

      dev.log(
        message,
        name: source,
        time: DateTime.now(),
        level: level * 100,
      );

      print('$color[$timestamp][$label][$source] -> $message\x1B[0m');

      await _writeToFile(message, source, label);
    } catch (e) {
      dev.log('Logging failed: $e', name: 'SYSTEM', level: 1000);
    }
  }

  static Future<void> _writeToFile(
    String message,
    String source,
    String label,
  ) async {
    try {
      final String dateFile = DateFormat('dd-MM-yyyy').format(DateTime.now());
      final String timeStr = DateFormat('HH:mm:ss').format(DateTime.now());

      final Directory logsDir =
          Directory('${Directory.current.path}/logs');

      if (!await logsDir.exists()) {
        await logsDir.create(recursive: true);
      }

      final File logFile = File('${logsDir.path}/$dateFile.log');
      final String entry = '[$timeStr][$label][$source] -> $message\n';

      await logFile.writeAsString(entry, mode: FileMode.append);
    } catch (_) {
      
    }
  }


  static String _getLabel(int level) {
    switch (level) {
      case 1:
        return 'ERROR';
      case 2:
        return 'INFO';
      case 3:
        return 'VERBOSE';
      default:
        return 'LOG';
    }
  }

  static String _getColor(int level) {
    switch (level) {
      case 1:
        return '\x1B[31m'; // Merah
      case 2:
        return '\x1B[32m'; // Hijau
      case 3:
        return '\x1B[34m'; // Biru
      default:
        return '\x1B[0m';
    }
  }
}