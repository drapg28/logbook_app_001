import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:logbook_app_001/features/onboarding/onboarding_view.dart'; 
import 'counter_controller.dart';

class CounterView extends StatefulWidget {
  final String username;
  const CounterView({super.key, required this.username});

  @override
  State<CounterView> createState() => _CounterViewState();
}

class _CounterViewState extends State<CounterView> {
  final TextEditingController _stepController = TextEditingController(text: "1");

  @override
  void initState() {
    super.initState();
    Future.microtask(() => 
      context.read<CounterController>().initUser(widget.username)
    );
  }

  String _getGreeting() {
    var hour = DateTime.now().hour;
    if (hour >= 5 && hour < 11) return "Selamat Pagi";
    if (hour >= 11 && hour < 15) return "Selamat Siang";
    if (hour >= 15 && hour < 18) return "Selamat Sore";
    return "Selamat Malam";
  }

  @override
  void dispose() {
    _stepController.dispose();
    super.dispose();
  }

  void _showLogoutDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text("Konfirmasi Logout"),
          content: const Text("Apakah Anda yakin ingin keluar?"),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Batal"),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(builder: (context) => const OnboardingView()),
                  (route) => false,
                );
              },
              child: const Text("Ya, Keluar", style: TextStyle(color: Colors.red)),
            ),
          ],
        );
      },
    );
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
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text("${_getGreeting()}, ${widget.username}"), 
        centerTitle: true,
        elevation: 0,
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: _showLogoutDialog,
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 25, vertical: 10),
        child: Column(
          children: [
            const SizedBox(height: 10),
            Text("Total Hitungan:", style: TextStyle(color: Colors.grey[600], fontSize: 16)),
            Text(
              "${controller.counter}",
              style: const TextStyle(
                fontSize: 100, 
                fontWeight: FontWeight.bold,
                color: Colors.blueAccent,
              ),
            ),

            const SizedBox(height: 30),

            TextField(
              controller: _stepController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: "Nilai Step (Lompatan)",
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.bolt, color: Colors.grey),
              ),
              onChanged: (value) {
                final parsed = int.tryParse(value);
                controller.setStep(parsed ?? 1);
              },
            ),

            const SizedBox(height: 30),

            const Align(
              alignment: Alignment.centerLeft,
              child: Text(
                "5 Aktivitas Terakhir:", 
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
            ),
            const Divider(thickness: 1, height: 20),

            Expanded(
              child: ListView.builder(
                itemCount: controller.history.length,
                itemBuilder: (context, index) {
                  final log = controller.history[index];
                  final isIncrement = log.type == ActionType.increment;
                  final itemColor = isIncrement ? Colors.green : Colors.red;

                  return ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: Icon(Icons.history, color: itemColor, size: 20),
                    title: Text(
                      "User ${log.username} ${isIncrement ? 'menambah' : 'mengurang'} ${log.value}",
                      style: TextStyle(
                        color: itemColor, 
                        fontWeight: FontWeight.bold
                      ),
                    ),
                    trailing: Text(
                      "${log.timestamp.hour}:${log.timestamp.minute.toString().padLeft(2, '0')}",
                      style: const TextStyle(color: Colors.grey),
                    ),
                  );
                },
              ),
            ),

            Padding(
              padding: const EdgeInsets.only(bottom: 20),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  IconButton.filled(
                    onPressed: () => controller.decrement(widget.username),
                    icon: const Icon(Icons.remove, size: 30),
                    style: IconButton.styleFrom(backgroundColor: Colors.red),
                  ),
                  OutlinedButton.icon(
                    onPressed: () => _showResetDialog(controller),
                    icon: const Icon(Icons.refresh, size: 18),
                    label: const Text("RESET"),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.red,
                      side: const BorderSide(color: Colors.red),
                    ),
                  ),
                  IconButton.filled(
                    onPressed: () => controller.increment(widget.username),
                    icon: const Icon(Icons.add, size: 30),
                    style: IconButton.styleFrom(backgroundColor: Colors.green),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}