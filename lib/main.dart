import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'counter_controller.dart';
import 'counter_view.dart';

void main() {
  runApp(
    ChangeNotifierProvider(
      create: (_) => CounterController(),
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      debugShowCheckedModeBanner: false,
      home: CounterView(),
    );
  }
}
