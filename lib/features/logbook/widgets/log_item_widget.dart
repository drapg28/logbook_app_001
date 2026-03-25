import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:logbook_app_001/features/logbook/models/log_models.dart';

class LogItemWidget extends StatelessWidget {
  final LogModel log;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;

  const LogItemWidget({
    super.key,
    required this.log,
    required this.onEdit,
    required this.onDelete,
  });

  // ── Konfigurasi Style per Kategori ───────────────────────────────────────
  static const Map<String, _CategoryStyle> _categoryStyles = {
    'Mechanical': _CategoryStyle(
      accent: Color(0xFF2E7D32),
      background: Color(0xFFF1F8E9),
      iconColor: Color(0xFF43A047),
      icon: Icons.build_circle_outlined,
      badgeColor: Color(0xFFDCEDC8),
      badgeText: Color(0xFF2E7D32),
    ),
    'Electronic': _CategoryStyle(
      accent: Color(0xFF1565C0),
      background: Color(0xFFE3F2FD),
      iconColor: Color(0xFF1E88E5),
      icon: Icons.electrical_services_outlined,
      badgeColor: Color(0xFFBBDEFB),
      badgeText: Color(0xFF1565C0),
    ),
    'Software': _CategoryStyle(
      accent: Color(0xFF6A1B9A),
      background: Color(0xFFF3E5F5),
      iconColor: Color(0xFF8E24AA),
      icon: Icons.code_outlined,
      badgeColor: Color(0xFFE1BEE7),
      badgeText: Color(0xFF6A1B9A),
    ),
  };

  _CategoryStyle get _style =>
      _categoryStyles[log.category] ??
      const _CategoryStyle(
        accent: Color(0xFF546E7A),
        background: Color(0xFFF5F5F5),
        iconColor: Color(0xFF78909C),
        icon: Icons.folder_outlined,
        badgeColor: Color(0xFFECEFF1),
        badgeText: Color(0xFF546E7A),
      );

  String _formatShortDate(String dateStr) {
    try {
      final DateTime dt = DateTime.parse(dateStr);
      final Duration diff = DateTime.now().difference(dt);
      if (diff.inSeconds < 60) return 'Baru saja';
      if (diff.inMinutes < 60) return '${diff.inMinutes} mnt lalu';
      if (diff.inHours < 24) return '${diff.inHours} jam lalu';
      if (diff.inDays < 7) return '${diff.inDays} hari lalu';
      return '${dt.day}/${dt.month}/${dt.year}';
    } catch (_) {
      return dateStr;
    }
  }

  @override
  Widget build(BuildContext context) {
    final style = _style;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      decoration: BoxDecoration(
        color: style.background,
        borderRadius: BorderRadius.circular(16),
        border: Border(
          left: BorderSide(color: style.accent, width: 4),
        ),
        boxShadow: [
          BoxShadow(
            color: style.accent.withOpacity(0.08),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Row 1: Ikon + Judul + Visibility ────────────────────────
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: style.badgeColor,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(style.icon, color: style.iconColor, size: 20),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              log.title,
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                color: style.accent,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(width: 4),
                          Icon(
                            log.isPublic ? Icons.public : Icons.lock_outline,
                            size: 13,
                            color: style.accent.withOpacity(0.5),
                          ),
                        ],
                      ),
                      const SizedBox(height: 2),
                      Text(
                        _formatShortDate(log.date),
                        style: TextStyle(
                          fontSize: 11,
                          color: style.accent.withOpacity(0.5),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            // ── Deskripsi (Markdown rendered) ────────────────────────────
            if (log.description.isNotEmpty) ...[
              const SizedBox(height: 10),
              MarkdownBody(
                data: log.description,
                shrinkWrap: true,
                styleSheet: MarkdownStyleSheet(
                  p: TextStyle(
                    fontSize: 12,
                    color: Colors.black54,
                    height: 1.4,
                  ),
                  strong: TextStyle(
                    fontSize: 12,
                    color: style.accent,
                    fontWeight: FontWeight.bold,
                  ),
                  em: TextStyle(
                    fontSize: 12,
                    color: Colors.black45,
                    fontStyle: FontStyle.italic,
                  ),
                  h1: TextStyle(
                    fontSize: 14,
                    color: style.accent,
                    fontWeight: FontWeight.bold,
                  ),
                  h2: TextStyle(
                    fontSize: 13,
                    color: style.accent,
                    fontWeight: FontWeight.w600,
                  ),
                  listBullet: TextStyle(
                    fontSize: 12,
                    color: Colors.black54,
                  ),
                ),
              ),
            ],

            // ── Row 3: Badge Kategori + Tombol Aksi ─────────────────────
            const SizedBox(height: 10),
            Row(
              children: [
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: style.badgeColor,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(style.icon, size: 11, color: style.badgeText),
                      const SizedBox(width: 4),
                      Text(
                        log.category,
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: style.badgeText,
                        ),
                      ),
                    ],
                  ),
                ),
                const Spacer(),
                if (onEdit != null)
                  _ActionButton(
                    icon: Icons.edit_outlined,
                    color: style.accent,
                    background: style.badgeColor,
                    onTap: onEdit!,
                  ),
                if (onDelete != null) ...[
                  const SizedBox(width: 6),
                  _ActionButton(
                    icon: Icons.delete_outline,
                    color: Colors.red.shade400,
                    background: Colors.red.shade50,
                    onTap: onDelete!,
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _CategoryStyle {
  final Color accent;
  final Color background;
  final Color iconColor;
  final IconData icon;
  final Color badgeColor;
  final Color badgeText;

  const _CategoryStyle({
    required this.accent,
    required this.background,
    required this.iconColor,
    required this.icon,
    required this.badgeColor,
    required this.badgeText,
  });
}

class _ActionButton extends StatelessWidget {
  final IconData icon;
  final Color color;
  final Color background;
  final VoidCallback onTap;

  const _ActionButton({
    required this.icon,
    required this.color,
    required this.background,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: background,
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