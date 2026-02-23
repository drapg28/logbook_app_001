import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:logbook_app_001/features/onboarding/onboarding_view.dart';
import 'log_controller.dart';
import 'models/log_models.dart';
import 'widgets/log_item_widget.dart';

class LogView extends StatefulWidget {
  final String username;
  const LogView({super.key, required this.username});

  @override
  State<LogView> createState() => _LogViewState();
}

class _LogViewState extends State<LogView> {
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _contentController = TextEditingController();

  @override
  void initState() {
    super.initState();
    Future.microtask(() => context.read<LogController>().initUser(widget.username));
  }

  void _showSnackBar(String message, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  void _showDeleteConfirmation(int index) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        title: const Text("Hapus Catatan", style: TextStyle(fontWeight: FontWeight.bold)),
        content: const Text("Tindakan ini tidak dapat dibatalkan."),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("Batal")),
          ElevatedButton(
            onPressed: () {
              context.read<LogController>().removeLog(index);
              Navigator.pop(context);
              _showSnackBar("Catatan dihapus", Colors.redAccent);
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
            child: const Text("Hapus"),
          ),
        ],
      ),
    );
  }

  void _showLogDialog({int? index, LogModel? log}) {
    if (log != null) {
      _titleController.text = log.title;
      _contentController.text = log.description;
    } else {
      _titleController.clear();
      _contentController.clear();
    }

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        title: Text(log == null ? "Catatan Baru" : "Edit Catatan", style: const TextStyle(fontWeight: FontWeight.bold)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _titleController, 
              decoration: InputDecoration(labelText: "Judul", border: OutlineInputBorder(borderRadius: BorderRadius.circular(12))),
            ),
            const SizedBox(height: 15),
            TextField(
              controller: _contentController, 
              maxLines: 3,
              decoration: InputDecoration(labelText: "Isi Deskripsi", border: OutlineInputBorder(borderRadius: BorderRadius.circular(12))),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("Batal")),
          SizedBox(
            width: 100,
            child: ElevatedButton(
              onPressed: () {
                final ctrl = context.read<LogController>();
                if (log == null) {
                  ctrl.addLog(_titleController.text, _contentController.text);
                  _showSnackBar("Berhasil disimpan", Colors.green);
                } else {
                  ctrl.updateLog(index!, _titleController.text, _contentController.text);
                  _showSnackBar("Berhasil diperbarui", Colors.blueAccent);
                }
                Navigator.pop(context);
              },
              style: ElevatedButton.styleFrom(backgroundColor: Colors.blueAccent, foregroundColor: Colors.white),
              child: Text(log == null ? "Simpan" : "Update"),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<LogController>();

    return Scaffold(
      backgroundColor: Colors.white, 
      appBar: AppBar(
        title: Text("Logbook: ${widget.username}", style: const TextStyle(fontWeight: FontWeight.bold)),
        centerTitle: true,
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.redAccent),
            onPressed: () => Navigator.pushAndRemoveUntil(
              context,
              MaterialPageRoute(builder: (context) => const OnboardingView()),
              (route) => false,
            ),
          ),
        ],
      ),
      body: ValueListenableBuilder<List<LogModel>>(
        valueListenable: controller.logsNotifier,
        builder: (context, currentLogs, child) {
          if (currentLogs.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.notes_rounded, size: 80, color: Colors.grey[300]),
                  const SizedBox(height: 16),
                  Text("Belum ada aktivitas", style: TextStyle(color: Colors.grey[400], fontSize: 18)),
                ],
              ),
            );
          }
          
          return ListView.builder(
            padding: const EdgeInsets.only(top: 10, bottom: 80),
            itemCount: currentLogs.length,
            itemBuilder: (context, index) {
              final log = currentLogs[index];
              return LogItemWidget(
                log: log,
                onEdit: () => _showLogDialog(index: index, log: log),
                onDelete: () => _showDeleteConfirmation(index),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showLogDialog(),
        backgroundColor: Colors.blueAccent,
        foregroundColor: Colors.white,
        elevation: 4,
        child: const Icon(Icons.add_rounded, size: 30),
      ),
    );
  }
}