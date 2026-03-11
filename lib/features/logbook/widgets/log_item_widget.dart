import 'package:flutter/material.dart';
import 'package:logbook_app_001/features/logbook/models/log_models.dart';

class LogItemWidget extends StatelessWidget {
  final LogModel log;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const LogItemWidget({
    super.key,
    required this.log,
    required this.onEdit,
    required this.onDelete,
  });

  Color _getCardColor() {
    switch (log.category) {
      case 'Pekerjaan':
      case 'Proyek':
        return const Color(0xFFFFF176);
      case 'Pribadi':
        return const Color(0xFF81C784);
      case 'Urgent':
        return const Color(0xFFE57373);
      default:
        return const Color(0xFFE0E0E0);
    }
  }

  Color _getTextColor() {
    switch (log.category) {
      case 'Urgent':
        return Colors.white;
      default:
        return Colors.black87;
    }
  }

  String _formatShortDate(String dateStr) {
    try {
      final DateTime dt = DateTime.parse(dateStr);
      final Duration diff = DateTime.now().difference(dt);

      if (diff.inSeconds < 60) return 'Baru saja';
      if (diff.inMinutes < 60) return '${diff.inMinutes} menit yang lalu';
      if (diff.inHours < 24) return '${diff.inHours} jam yang lalu';
      if (diff.inDays < 7) return '${diff.inDays} hari yang lalu';

      final String time =
          '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
      return '${dt.day}/${dt.month}/${dt.year} | $time';
    } catch (_) {
      return dateStr;
    }
  }

  @override
  Widget build(BuildContext context) {
    final Color cardColor = _getCardColor();
    final Color textColor = _getTextColor();

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 5),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: cardColor.withOpacity(0.5),
            blurRadius: 6,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(14, 12, 6, 12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    log.title,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: textColor,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 3),
                  if (log.description.isNotEmpty)
                    Text(
                      log.description,
                      style: TextStyle(
                        fontSize: 12,
                        color: textColor.withOpacity(0.85),
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  const SizedBox(height: 5),
                  Text(
                    _formatShortDate(log.date),
                    style: TextStyle(
                      fontSize: 11,
                      color: textColor.withOpacity(0.65),
                    ),
                  ),
                ],
              ),
            ),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _ActionButton(
                  icon: Icons.edit,
                  color: Colors.blue.shade700,
                  onTap: onEdit,
                ),
                const SizedBox(width: 4),
                _ActionButton(
                  icon: Icons.delete,
                  color: Colors.red.shade700,
                  onTap: onDelete,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const _ActionButton({
    required this.icon,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white.withOpacity(0.4),
      borderRadius: BorderRadius.circular(8),
      child: InkWell(
        borderRadius: BorderRadius.circular(8),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(7),
          child: Icon(icon, size: 18, color: color),
        ),
      ),
    );
  }
}