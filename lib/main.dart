import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:logbook_app_001/features/onboarding/onboarding_view.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Load ENV saja di sini (cepat), koneksi DB dipindah ke LogView agar tidak blackscreen
  try {
    await dotenv.load(fileName: ".env");
  } catch (e) {
    debugPrint("ENV Load Error: $e");
  }

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Logbook Cloud Samudra',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blueAccent),
        useMaterial3: true,
      ),
      home: const OnboardingView(), 
    );
  }
}