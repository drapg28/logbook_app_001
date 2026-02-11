import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'counter_controller.dart';

class CounterView extends StatefulWidget {
  const CounterView({super.key});

  @override
  State<CounterView> createState() => _CounterViewState();
}

class _CounterViewState extends State<CounterView> {
  final TextEditingController _stepController = TextEditingController(text: "1");

  @override
  void dispose() {
    _stepController.dispose();
    super.dispose();
  }

  void _showResetDialog(CounterController controller) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text("Konfirmasi Reset"),
          content: const Text("Yakin ingin menghapus semua hitungan dan riwayat?"),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Batal"),
            ),
            ElevatedButton(
              onPressed: () {
                controller.reset();
                Navigator.pop(context);
                
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text("Data berhasil dibersihkan!"),
                    behavior: SnackBarBehavior.floating,
                    duration: Duration(seconds: 2),
                  ),
                );
              },
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red[50]),
              child: const Text("Ya, Reset", style: TextStyle(color: Colors.red)),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<CounterController>();

    return Scaffold(
      appBar: AppBar(
        title: const Text("Logbook Counter Samudra"),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            // --- DISPLAY COUNTER UTAMA ---
            Text("Total Hitungan:", style: TextStyle(color: Colors.grey[700])),
            Text(
              "${controller.counter}",
              style: const TextStyle(
                fontSize: 80, 
                fontWeight: FontWeight.bold,
                color: Colors.blueAccent,
              ),
            ),

            const SizedBox(height: 20),

            TextField(
              controller: _stepController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: "Nilai Step (Lompatan)",
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.bolt),
              ),
              onChanged: (value) {
                final parsed = int.tryParse(value);
                controller.setStep(parsed ?? 0);
              },
            ),

            const SizedBox(height: 30),

            // --- HEADER RIWAYAT ---
            const Align(
              alignment: Alignment.centerLeft,
              child: Text(
                "5 Aktivitas Terakhir:", 
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
            const Divider(thickness: 1),

            // --- DAFTAR RIWAYAT ---
            Expanded(
              child: ListView.builder(
                itemCount: controller.history.length,
                itemBuilder: (context, index) {
                  final log = controller.history[index];
                
                  final isIncrement = log.type == ActionType.increment;
                  final actionStr = isIncrement ? "Tambah" : "Kurang";
                  final itemColor = isIncrement ? Colors.green : Colors.red;
                  
                  final time = "${log.timestamp.hour}:${log.timestamp.minute.toString().padLeft(2, '0')}";

                  return ListTile(
                    leading: Icon(Icons.history, color: itemColor),
                    title: Text(
                      "$actionStr ${log.value}",
                      style: TextStyle(color: itemColor, fontWeight: FontWeight.bold),
                    ),
                    subtitle: Text("Dilakukan pada jam $time"),
                  );
                },
              ),
            ),

            // --- TOMBOL AKSI  ---
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                IconButton.filled(
                  onPressed: controller.decrement,
                  icon: const Icon(Icons.remove),
                  style: IconButton.styleFrom(backgroundColor: Colors.red),
                ),
                ElevatedButton.icon(
                  onPressed: () => _showResetDialog(controller),
                  icon: const Icon(Icons.refresh),
                  label: const Text("RESET"),
                  style: ElevatedButton.styleFrom(foregroundColor: Colors.red),
                ),
                IconButton.filled(
                  onPressed: controller.increment,
                  icon: const Icon(Icons.add),
                  style: IconButton.styleFrom(backgroundColor: Colors.green),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}