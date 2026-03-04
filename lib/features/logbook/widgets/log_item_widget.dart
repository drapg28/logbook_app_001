import 'package:flutter/material.dart';
import '../models/log_models.dart';

class LogItemWidget extends StatelessWidget {
  final LogModel log;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const LogItemWidget({super.key, required this.log, required this.onEdit, required this.onDelete});

  // Warna kategori [cite: 194]
  Color _getCategoryColor() {
    switch (log.category) {
      case "Pekerjaan": return const Color.fromARGB(255, 255, 252, 104)!;
      case "Pribadi": return const Color.fromARGB(255, 126, 230, 134)!;
      case "Urgent": return const Color.fromARGB(255, 253, 109, 131)!;
      default: return Colors.grey[100]!;
    }
  }

  String _formatDateTime(String dateStr) {
    DateTime dt = DateTime.parse(dateStr);
    return "${dt.day}/${dt.month}/${dt.year} | ${dt.hour}:${dt.minute.toString().padLeft(2, '0')}";
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      color: _getCategoryColor(),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.grey[200]!),
      ),
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
      child: ListTile(
        title: Text(log.title, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(log.description),
            const SizedBox(height: 5),
            Text(_formatDateTime(log.date), style: const TextStyle(fontSize: 11, color: Colors.black54)),
          ],
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(icon: const Icon(Icons.edit, color: Colors.blue), onPressed: onEdit),
            IconButton(icon: const Icon(Icons.delete, color: Colors.red), onPressed: onDelete),
          ],
        ),
      ),
    );
  }
}