import 'package:flutter/material.dart';
import 'counter_view.dart'; // Mengimpor 'wajah' yang baru kita buat

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'LogBook : t2 ver',
      debugShowCheckedModeBanner: false, // Biar gak ada tulisan 'Debug' di pojok HP
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
        useMaterial3: true,
      ),
      // Di sini kuncinya: kita panggil CounterView() sebagai halaman utama
      home: const CounterView(), 
    );
  }
}