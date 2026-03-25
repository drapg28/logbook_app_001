/// LogEditorPage — Halaman Editor Catatan (SRP)
///
/// Tanggung jawab: HANYA menangani input form dan preview Markdown.
/// Tidak ada logika akses atau logika database di sini.
///
/// SRP : Hanya mengurus form input & navigasi
/// SoC : Simpan data → LogController, akses → AccessControlService
import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:logbook_app_001/features/logbook/log_controller.dart';
import 'package:logbook_app_001/features/logbook/models/log_models.dart';

class LogEditorPage extends StatefulWidget {
  final LogModel? log;
  final int? index;
  final LogController controller;
  final Map<String, String> currentUser;

  const LogEditorPage({
    super.key,
    this.log,
    this.index,
    required this.controller,
    required this.currentUser,
  });

  @override
  State<LogEditorPage> createState() => _LogEditorPageState();
}

class _LogEditorPageState extends State<LogEditorPage> {
  late TextEditingController _titleController;
  late TextEditingController _descController;
  String _selectedCategory = 'Mechanical';
  bool _isPublic = false;

  // Kategori sesuai modul
  static const List<Map<String, dynamic>> _categories = [
    {
      'value': 'Mechanical',
      'icon': Icons.build_circle_outlined,
      'color': Color(0xFF2E7D32),
    },
    {
      'value': 'Electronic',
      'icon': Icons.electrical_services_outlined,
      'color': Color(0xFF1565C0),
    },
    {
      'value': 'Software',
      'icon': Icons.code_outlined,
      'color': Color(0xFF6A1B9A),
    },
  ];

  Map<String, dynamic> get _currentCategoryStyle =>
      _categories.firstWhere((c) => c['value'] == _selectedCategory,
          orElse: () => _categories.first);

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.log?.title ?? '');
    _descController =
        TextEditingController(text: widget.log?.description ?? '');
    _selectedCategory = widget.log?.category ?? 'Mechanical';
    _isPublic = widget.log?.isPublic ?? false;

    _descController.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descController.dispose();
    super.dispose();
  }

  void _save() {
    if (_titleController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Judul tidak boleh kosong!'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    if (widget.log == null) {
      widget.controller.addLog(
        _titleController.text.trim(),
        _descController.text.trim(),
        _selectedCategory,
        widget.currentUser['uid']!,
        widget.currentUser['teamId']!,
        _isPublic,
      );
    } else {
      widget.controller.updateLog(
        widget.index!,
        _titleController.text.trim(),
        _descController.text.trim(),
        _selectedCategory,
        _isPublic,
      );
    }

    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final Color accentColor = _currentCategoryStyle['color'] as Color;

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          backgroundColor: Colors.white,
          foregroundColor: Colors.black,
          elevation: 0,
          title: Text(
            widget.log == null ? 'Catatan Baru' : 'Edit Catatan',
            style: const TextStyle(
                fontWeight: FontWeight.bold, color: Colors.black87),
          ),
          bottom: TabBar(
            indicatorColor: accentColor,
            labelColor: accentColor,
            unselectedLabelColor: Colors.grey,
            tabs: const [
              Tab(text: 'Editor'),
              Tab(text: 'Pratinjau'),
            ],
          ),
          actions: [
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: TextButton.icon(
                onPressed: _save,
                icon: Icon(Icons.save_outlined, color: accentColor),
                label: Text('Simpan',
                    style: TextStyle(
                        color: accentColor, fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
        body: TabBarView(
          children: [
            // ── Tab 1: Editor ─────────────────────────────────────────
            SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Judul
                  TextField(
                    controller: _titleController,
                    decoration: InputDecoration(
                      labelText: 'Judul Catatan',
                      labelStyle: TextStyle(color: accentColor),
                      prefixIcon:
                          Icon(Icons.title, color: accentColor),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: accentColor, width: 2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),

                  DropdownButtonFormField<String>(
                    value: _selectedCategory,
                    decoration: InputDecoration(
                      labelText: 'Kategori',
                      labelStyle: TextStyle(color: accentColor),
                      prefixIcon: Icon(
                        _currentCategoryStyle['icon'] as IconData,
                        color: accentColor,
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: accentColor, width: 2),
                      ),
                    ),
                    items: _categories.map((cat) {
                      final Color catColor = cat['color'] as Color;
                      return DropdownMenuItem<String>(
                        value: cat['value'] as String,
                        child: Row(
                          children: [
                            // Indikator warna kategori
                            Container(
                              width: 12,
                              height: 12,
                              decoration: BoxDecoration(
                                color: catColor,
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 10),
                            Icon(cat['icon'] as IconData,
                                size: 18, color: catColor),
                            const SizedBox(width: 8),
                            Text(
                              cat['value'] as String,
                              style: TextStyle(
                                  color: catColor,
                                  fontWeight: FontWeight.w600),
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                    onChanged: (val) =>
                        setState(() => _selectedCategory = val!),
                  ),
                  const SizedBox(height: 14),

                  // Toggle Publik / Privat
                  Container(
                    decoration: BoxDecoration(
                      color: _isPublic
                          ? accentColor.withOpacity(0.08)
                          : Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: _isPublic
                            ? accentColor.withOpacity(0.3)
                            : Colors.grey.shade300,
                      ),
                    ),
                    child: SwitchListTile(
                      title: Text(
                        _isPublic
                            ? '🌐 Publik — Tim bisa melihat catatan ini'
                            : '🔒 Privat — Hanya kamu yang bisa lihat',
                        style: TextStyle(
                          fontSize: 13,
                          color: _isPublic ? accentColor : Colors.grey,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      value: _isPublic,
                      onChanged: (val) => setState(() => _isPublic = val),
                      activeColor: accentColor,
                      contentPadding:
                          const EdgeInsets.symmetric(horizontal: 12),
                    ),
                  ),
                  const SizedBox(height: 14),

                  // Label deskripsi
                  Row(
                    children: [
                      Icon(Icons.notes_outlined,
                          size: 16, color: Colors.grey.shade500),
                      const SizedBox(width: 6),
                      Text(
                        'Deskripsi (mendukung Markdown)',
                        style: TextStyle(
                            fontSize: 12, color: Colors.grey.shade500),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),

                  // Input deskripsi
                  Container(
                    constraints: const BoxConstraints(minHeight: 200),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade50,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.grey.shade300),
                    ),
                    child: TextField(
                      controller: _descController,
                      maxLines: null,
                      keyboardType: TextInputType.multiline,
                      decoration: const InputDecoration(
                        hintText:
                            '## Judul\n**Teks tebal**, *miring*\n- Poin penting\n\nTulis laporan di sini...',
                        hintStyle:
                            TextStyle(color: Colors.black26, fontSize: 13),
                        border: InputBorder.none,
                        contentPadding: EdgeInsets.all(14),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // ── Tab 2: Pratinjau Markdown ─────────────────────────────
            _descController.text.isEmpty
                ? Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.preview_outlined,
                            size: 60, color: Colors.grey.shade300),
                        const SizedBox(height: 12),
                        Text(
                          'Belum ada konten untuk ditampilkan.\nMulai ketik di tab Editor.',
                          textAlign: TextAlign.center,
                          style: TextStyle(color: Colors.grey.shade400),
                        ),
                      ],
                    ),
                  )
                : Markdown(
                    data: _descController.text,
                    styleSheet: MarkdownStyleSheet(
                      h1: TextStyle(
                          color: accentColor, fontWeight: FontWeight.bold),
                      h2: TextStyle(color: accentColor),
                      strong: TextStyle(color: accentColor),
                    ),
                  ),
          ],
        ),
      ),
    );
  }
}