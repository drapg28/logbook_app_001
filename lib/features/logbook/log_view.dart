import 'package:flutter/material.dart';

import 'package:logbook_app_001/features/auth/login_view.dart';
import 'package:logbook_app_001/features/logbook/log_controller.dart';
import 'package:logbook_app_001/features/logbook/log_editor_page.dart';
import 'package:logbook_app_001/features/logbook/models/log_models.dart';
import 'package:logbook_app_001/features/logbook/widgets/log_item_widget.dart';
import 'package:logbook_app_001/services/access_control_service.dart';

class LogView extends StatefulWidget {
  final Map<String, String> currentUser;
  const LogView({super.key, required this.currentUser});

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
    _controller.dispose(); 
    super.dispose();
  }

  Future<void> _startSession() async {
    setState(() => _isLoading = true);
    await _controller.loadLogs(widget.currentUser['teamId']!);
    _controller.startConnectivityListener(widget.currentUser['teamId']!);
    if (mounted) setState(() => _isLoading = false);
  }

  // ── PULL-TO-REFRESH ──────────────────────────────────────────────────────
  Future<void> _onRefresh() async {
    try {
      await _controller.loadLogs(widget.currentUser['teamId']!);
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

  void _goToEditor({int? index, LogModel? log}) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => LogEditorPage(
          log: log,
          index: index,
          controller: _controller,
          currentUser: widget.currentUser,
        ),
      ),
    );
  }


  @override
  Widget build(BuildContext context) {
    final String currentUid  = widget.currentUser['uid']!;
    final String currentRole = widget.currentUser['role']!;
    final String username    = widget.currentUser['username']!;

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
              'Logbook: $username',
              style: const TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
          ],
        ),
        actions: [
          // Badge role pengguna
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 4),
            child: Chip(
              label: Text(currentRole,
                  style: const TextStyle(fontSize: 11, color: Colors.white)),
              backgroundColor:
                  currentRole == 'Ketua' ? Colors.blueAccent : Colors.grey,
              padding: EdgeInsets.zero,
            ),
          ),
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
                          horizontal: 16, vertical: 10),
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
                        if (_controller.isOffline && allLogs.isEmpty) return _buildOffline();

                        // SRP: filter & visibility diserahkan ke Controller
                        final List<LogModel> logs =
                            _controller.getVisibleLogs(currentUid, _searchQuery);

                        if (allLogs.isEmpty) return _buildEmpty();
                        if (logs.isEmpty) return _buildNoResult();

                        return ListView.builder(
                          padding:
                              const EdgeInsets.only(top: 8, bottom: 90),
                          itemCount: logs.length,
                          itemBuilder: (ctx, i) {
                            final int realIndex = allLogs.indexOf(logs[i]);
                            final bool isOwner =
                                logs[i].authorId == currentUid;

                            // RBAC via AccessControlService
                            final bool canEdit =
                                AccessControlService.canPerform(
                              currentRole,
                              AccessControlService.actionUpdate,
                              isOwner: isOwner,
                            );
                            final bool canDelete =
                                AccessControlService.canPerform(
                              currentRole,
                              AccessControlService.actionDelete,
                              isOwner: isOwner,
                            );

                            return Dismissible(
                              key: Key(logs[i].id.toString()),
                              direction: canDelete
                                  ? DismissDirection.endToStart
                                  : DismissDirection.none,
                              background: Container(
                                margin: const EdgeInsets.symmetric(
                                    horizontal: 16, vertical: 5),
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
                                onEdit: canEdit
                                    ? () => _goToEditor(
                                        index: realIndex, log: logs[i])
                                    : null,
                                onDelete: canDelete
                                    ? () => _controller.removeLog(realIndex)
                                    : null,
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
        onPressed: _isLoading ? null : () => _goToEditor(),
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
        Text('Belum ada data tersimpan di perangkat.\nTarik ke bawah untuk mencoba lagi.',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.grey)),
      ]),
    ),
  ],
);

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
                    style: TextStyle(
                        fontSize: 16, fontWeight: FontWeight.bold)),
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
                    style: TextStyle(
                        fontSize: 16, fontWeight: FontWeight.bold)),
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