import 'package:flutter/material.dart';

import 'package:logbook_app_001/features/auth/login_view.dart';
import 'package:logbook_app_001/features/logbook/log_controller.dart';
import 'package:logbook_app_001/features/logbook/models/log_models.dart';
import 'package:logbook_app_001/features/logbook/widgets/log_item_widget.dart';

class LogView extends StatefulWidget {
  final String username;
  const LogView({super.key, required this.username});

  @override
  State<LogView> createState() => _LogViewState();
}

class _LogViewState extends State<LogView> {
  late LogController _controller;
  bool _isLoading = true;

  // ── SEARCH ──────────────────────────────────────────────────────────────
  final TextEditingController _searchCtrl = TextEditingController();
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _controller = LogController();
    _searchCtrl.addListener(() {
      setState(() => _searchQuery = _searchCtrl.text.toLowerCase().trim());
    });
    Future.microtask(_startSession);
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _startSession() async {
    setState(() => _isLoading = true);
    await _controller.initSession();
    if (mounted) setState(() => _isLoading = false);
  }

  // Filter list berdasarkan query pencarian (by judul)
  List<LogModel> _filtered(List<LogModel> all) {
    if (_searchQuery.isEmpty) return all;
    return all
        .where((log) => log.title.toLowerCase().contains(_searchQuery))
        .toList();
  }

  // ── PULL-TO-REFRESH ──────────────────────────────────────────────────────
  Future<void> _onRefresh() async {
    try {
      await _controller.refreshSession();
      if (mounted) setState(() {});
    } catch (_) {
      if (mounted) {
        setState(() {});
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Row(children: [
              Icon(Icons.wifi_off, color: Colors.white),
              SizedBox(width: 10),
              Text('Gagal terhubung. Periksa koneksi internet kamu.'),
            ]),
            backgroundColor: Colors.orange,
            duration: Duration(seconds: 3),
          ),
        );
      }
    }
  }

  String _getGreeting() {
    final int h = DateTime.now().hour;
    if (h < 12) return 'Selamat Pagi';
    if (h < 17) return 'Selamat Siang';
    return 'Selamat Malam';
  }

  // ── DIALOG TAMBAH / EDIT ─────────────────────────────────────────────────
  void _showLogDialog({int? index, LogModel? log}) {
    final titleCtrl = TextEditingController(text: log?.title);
    final descCtrl = TextEditingController(text: log?.description);
    String selectedCategory = log?.category ?? 'Pribadi';
    const List<String> categories = ['Pribadi', 'Proyek', 'Urgent'];

    showDialog(
      context: context,
      builder: (_) => StatefulBuilder(
        builder: (ctx, set) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Text(log == null ? 'Tambah Catatan' : 'Edit Catatan'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: titleCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Judul',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  value: selectedCategory,
                  decoration: const InputDecoration(
                    labelText: 'Kategori',
                    border: OutlineInputBorder(),
                  ),
                  items: categories
                      .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                      .toList(),
                  onChanged: (val) => set(() => selectedCategory = val!),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: descCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Deskripsi',
                    border: OutlineInputBorder(),
                  ),
                  maxLines: 3,
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Batal'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blueAccent,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              onPressed: () async {
                if (titleCtrl.text.trim().isNotEmpty) {
                  if (log == null) {
                    await _controller.addLog(
                      titleCtrl.text.trim(),
                      descCtrl.text.trim(),
                      selectedCategory,
                    );
                  } else {
                    await _controller.updateLog(
                      index!,
                      titleCtrl.text.trim(),
                      descCtrl.text.trim(),
                      selectedCategory,
                    );
                  }
                  if (mounted) Navigator.pop(ctx);
                }
              },
              child: const Text('Simpan'),
            ),
          ],
        ),
      ),
    );
  }

  // ── BUILD ─────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(_getGreeting(),
                style: const TextStyle(fontSize: 12, color: Colors.grey)),
            Text(
              'Logbook: ${widget.username}',
              style: const TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.red),
            onPressed: () => Navigator.pushAndRemoveUntil(
              context,
              MaterialPageRoute(builder: (_) => const LoginView()),
              (route) => false,
            ),
          ),
        ],
        // Offline Banner
        bottom: _controller.isOffline
            ? PreferredSize(
                preferredSize: const Size.fromHeight(36),
                child: Container(
                  width: double.infinity,
                  color: Colors.orange.shade700,
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.wifi_off, color: Colors.white, size: 16),
                      SizedBox(width: 8),
                      Text(
                        'Offline Mode — Tarik ke bawah untuk mencoba lagi',
                        style: TextStyle(color: Colors.white, fontSize: 12),
                      ),
                    ],
                  ),
                ),
              )
            : null,
      ),

      body: _isLoading
          ? _buildLoading()
          : Column(
              children: [
                // ── SEARCH BAR ─────────────────────────────────────────
                Container(
                  color: Colors.white,
                  padding: const EdgeInsets.fromLTRB(16, 10, 16, 12),
                  child: TextField(
                    controller: _searchCtrl,
                    decoration: InputDecoration(
                      hintText: 'Cari berdasarkan judul...',
                      hintStyle: const TextStyle(fontSize: 13),
                      prefixIcon: const Icon(Icons.search, size: 20),
                      suffixIcon: _searchQuery.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.close, size: 18),
                              onPressed: () {
                                _searchCtrl.clear();
                                setState(() => _searchQuery = '');
                              },
                            )
                          : null,
                      filled: true,
                      fillColor: const Color(0xFFF0F4FF),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 10,
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(30),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                ),

                // ── LIST AREA ──────────────────────────────────────────
                Expanded(
                  child: RefreshIndicator(
                    onRefresh: _onRefresh,
                    color: Colors.blueAccent,
                    child: ValueListenableBuilder<List<LogModel>>(
                      valueListenable: _controller.logsNotifier,
                      builder: (context, allLogs, _) {
                        if (_controller.isOffline) return _buildOffline();

                        final List<LogModel> logs = _filtered(allLogs);

                        if (allLogs.isEmpty) return _buildEmpty();
                        if (logs.isEmpty) return _buildNoResult();

                        return ListView.builder(
                          padding: const EdgeInsets.only(top: 8, bottom: 90),
                          itemCount: logs.length,
                          itemBuilder: (ctx, i) {
                            // Cari index asli untuk operasi edit/delete
                            final int realIndex = allLogs.indexOf(logs[i]);
                            return Dismissible(
                              key: Key(logs[i].id.toString()),
                              direction: DismissDirection.endToStart,
                              background: Container(
                                margin: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 5,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.red,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                alignment: Alignment.centerRight,
                                padding: const EdgeInsets.only(right: 20),
                                child: const Icon(Icons.delete,
                                    color: Colors.white),
                              ),
                              onDismissed: (_) =>
                                  _controller.removeLog(realIndex),
                              child: LogItemWidget(
                                log: logs[i],
                                onEdit: () => _showLogDialog(
                                    index: realIndex, log: logs[i]),
                                onDelete: () =>
                                    _controller.removeLog(realIndex),
                              ),
                            );
                          },
                        );
                      },
                    ),
                  ),
                ),
              ],
            ),

      floatingActionButton: FloatingActionButton.extended(
        onPressed: _controller.isOffline || _isLoading
            ? null
            : () => _showLogDialog(),
        icon: const Icon(Icons.add),
        label: const Text('Catatan Baru'),
        backgroundColor:
            _controller.isOffline ? Colors.grey : Colors.blueAccent,
        foregroundColor: Colors.white,
      ),
    );
  }

  // ── STATE WIDGETS ─────────────────────────────────────────────────────────

  Widget _buildLoading() => const Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('Menghubungkan ke MongoDB Atlas...',
                style: TextStyle(color: Colors.grey)),
          ],
        ),
      );

  Widget _buildOffline() => ListView(
        children: const [
          SizedBox(height: 100),
          Center(
            child: Column(children: [
              Icon(Icons.cloud_off, size: 72, color: Colors.orange),
              SizedBox(height: 16),
              Text('Tidak ada koneksi internet',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              SizedBox(height: 8),
              Text('Tarik ke bawah untuk mencoba lagi.',
                  style: TextStyle(color: Colors.grey)),
            ]),
          ),
        ],
      );

  // Empty state: belum ada catatan sama sekali
  Widget _buildEmpty() => ListView(
        children: [
          const SizedBox(height: 100),
          Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.note_add_outlined,
                    size: 72, color: Colors.blue.shade200),
                const SizedBox(height: 16),
                const Text('Belum Ada Catatan',
                    style:
                        TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                const Text(
                  "Ketuk tombol '+' di bawah untuk mulai\nmenulis jurnal pertamamu.",
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.grey, fontSize: 13),
                ),
              ],
            ),
          ),
        ],
      );

  // No result state: pencarian tidak menemukan hasil
  Widget _buildNoResult() => ListView(
        children: const [
          SizedBox(height: 100),
          Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.search_off, size: 72, color: Colors.grey),
                SizedBox(height: 16),
                Text('Pencarian Tidak Ditemukan',
                    style:
                        TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                SizedBox(height: 8),
                Text(
                  'Coba gunakan kata kunci judul yang berbeda.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.grey, fontSize: 13),
                ),
              ],
            ),
          ),
        ],
      );
}