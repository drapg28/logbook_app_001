import 'package:flutter/material.dart';
import 'package:logbook_app_001/features/logbook/log_controller.dart';
import 'package:logbook_app_001/features/logbook/models/log_models.dart';
import 'package:logbook_app_001/features/logbook/widgets/log_item_widget.dart';
import 'package:logbook_app_001/helpers/log_helper.dart';
import 'package:logbook_app_001/services/mongo_service.dart';
import 'package:logbook_app_001/features/auth/login_view.dart';

class LogView extends StatefulWidget {
  final String username;
  const LogView({super.key, required this.username});

  @override
  State<LogView> createState() => _LogViewState();
}

class _LogViewState extends State<LogView> {
  late LogController _controller;
  bool _isInit = false;

  @override
  void initState() {
    super.initState();
    _controller = LogController();
    _startCloudSession();
  }

  // Menangani koneksi database di dalam UI agar tidak blackscreen di awal
  Future<void> _startCloudSession() async {
    try {
      await MongoService().connect(); // Koneksi dilakukan di sini
      await _controller.loadFromCloud();
    } catch (e) {
      LogHelper.writeLog("Cloud Session Error: $e", source: "log_view.dart", level: 1);
    } finally {
      if (mounted) setState(() => _isInit = true);
    }
  }

  // Fitur: Salam berdasarkan waktu
  String _getGreeting() {
    var hour = DateTime.now().hour;
    if (hour < 12) return "Selamat Pagi";
    if (hour < 17) return "Selamat Siang";
    return "Selamat Malam";
  }

  // --- DIALOG INPUT DENGAN DROPDOWN KATEGORI ---
  void _showLogDialog({int? index, LogModel? log}) {
    final titleController = TextEditingController(text: log?.title);
    final descController = TextEditingController(text: log?.description);
    String selectedCategory = log?.category ?? "Pribadi";
    final List<String> categories = ["Pribadi", "Pekerjaan", "Urgent"];

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
          title: Text(log == null ? "Tambah Catatan" : "Edit Catatan"),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(controller: titleController, decoration: const InputDecoration(labelText: "Judul")),
                const SizedBox(height: 10),
                DropdownButtonFormField<String>(
                  value: selectedCategory,
                  decoration: const InputDecoration(labelText: "Kategori"),
                  items: categories.map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
                  onChanged: (val) => setDialogState(() => selectedCategory = val!),
                ),
                TextField(controller: descController, decoration: const InputDecoration(labelText: "Deskripsi"), maxLines: 3),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text("Batal")),
            ElevatedButton(
              onPressed: () async {
                if (titleController.text.isNotEmpty) {
                  if (log == null) {
                    await _controller.addLog(titleController.text, descController.text, selectedCategory);
                  } else {
                    await _controller.updateLog(index!, titleController.text, descController.text, selectedCategory);
                  }
                  if (mounted) Navigator.pop(context);
                }
              },
              child: const Text("Simpan"),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(_getGreeting(), style: const TextStyle(fontSize: 14, color: Colors.grey)),
            Text(widget.username, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.red),
            onPressed: () {
              // Perbaikan blackscreen logout: pakai pushAndRemoveUntil
              Navigator.pushAndRemoveUntil(
                context, 
                MaterialPageRoute(builder: (context) => const LoginView()), 
                (route) => false
              );
            },
          ),
        ],
      ),
      body: !_isInit 
          ? const Center(child: CircularProgressIndicator()) // Ganti blackscreen dengan loading
          : ValueListenableBuilder<List<LogModel>>(
              valueListenable: _controller.logsNotifier,
              builder: (context, currentLogs, child) {
                if (currentLogs.isEmpty) {
                  return const Center(child: Text("Belum ada catatan di Cloud."));
                }
                return ListView.builder(
                  padding: const EdgeInsets.only(top: 10, bottom: 80),
                  itemCount: currentLogs.length,
                  itemBuilder: (context, index) {
                    final log = currentLogs[index];
                    // Fitur: Swipe to Delete menggunakan Dismissible
                    return Dismissible(
                      key: Key(log.id.toString()),
                      direction: DismissDirection.endToStart,
                      background: Container(
                        alignment: Alignment.centerRight,
                        padding: const EdgeInsets.only(right: 20),
                        color: Colors.red,
                        child: const Icon(Icons.delete, color: Colors.white),
                      ),
                      onDismissed: (dir) => _controller.removeLog(index),
                      child: LogItemWidget(
                        log: log,
                        onEdit: () => _showLogDialog(index: index, log: log),
                        onDelete: () => _controller.removeLog(index),
                      ),
                    );
                  },
                );
              },
            ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showLogDialog(),
        label: const Text("Catatan Baru"),
        icon: const Icon(Icons.add),
        backgroundColor: Colors.blueAccent,
        foregroundColor: Colors.white,
      ),
    );
  }
}