import 'package:flutter/material.dart';
import 'counter_controller.dart';

class CounterView extends StatefulWidget {
  const CounterView({super.key});

  @override
  State<CounterView> createState() => _CounterViewState();
}

class _CounterViewState extends State<CounterView> {
  final CounterController _controller = CounterController();
  final TextEditingController _stepInput = TextEditingController(text: "1");

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("History Logger : task 2")),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Text("Total Counter:", style: TextStyle(color: Colors.grey[700])),
            Text(
              "${_controller.counter}",
              style: const TextStyle(fontSize: 80, fontWeight: FontWeight.bold),
            ),

            const SizedBox(height: 20),

            // Input Step (Task 1)
            TextField(
              controller: _stepInput,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: "Masukkan Nilai Step",
                border: OutlineInputBorder(),
              ),
              onChanged: (v) => _controller.setStep(int.tryParse(v) ?? 1),
            ),

            const SizedBox(height: 30),

            // Daftar Riwayat (Task 2)
            const Align(
              alignment: Alignment.centerLeft,
              child: Text("Riwayat (Maksimal 5):", style: TextStyle(fontWeight: FontWeight.bold)),
            ),
            const Divider(),
            Expanded(
              child: ListView.builder(
                itemCount: _controller.history.length,
                itemBuilder: (context, index) => ListTile(
                  leading: const Icon(Icons.history),
                  title: Text(_controller.history[index]),
                ),
              ),
            ),

            // Tombol Navigasi
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                ElevatedButton(
                  onPressed: () => setState(() => _controller.decrement()),
                  child: const Icon(Icons.remove),
                ),
                ElevatedButton(
                  onPressed: () => setState(() => _controller.reset()),
                  child: const Text("Reset"),
                ),
                ElevatedButton(
                  onPressed: () => setState(() => _controller.increment()),
                  child: const Icon(Icons.add),
                ),
              ],
            )
          ],
        ),
      ),
    );
  }
}