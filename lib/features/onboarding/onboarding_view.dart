import 'package:flutter/material.dart';
import 'package:logbook_app_001/features/auth/login_view.dart';

class OnboardingView extends StatefulWidget {
  const OnboardingView({super.key});
  @override
  State<OnboardingView> createState() => _OnboardingViewState();
}

class _OnboardingViewState extends State<OnboardingView> {
  int _step = 1;

  final List<Map<String, String>> _data = [
    {"img": "assets/onboarding1.png", "title": "Pantau Progres", "desc": "Catat aktivitas harianmu dengan mudah dan cepat."},
    {"img": "assets/onboarding2.png", "title": "Data Aman", "desc": "Semua riwayat tersimpan otomatis di perangkatmu."},
    {"img": "assets/onboarding3.png", "title": "Mulai Sekarang", "desc": "Kelola produktivitasmu lebih baik dari sebelumnya."},
  ];

  void _nextStep() {
    setState(() {
      if (_step < 3) {
        _step++;
      } else {
        Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const LoginView()));
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(30.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Image.asset(_data[_step - 1]["img"]!, height: 250, errorBuilder: (c, e, s) => const Icon(Icons.image, size: 200, color: Colors.grey)),
              const SizedBox(height: 40),
              Text(
                _data[_step - 1]["title"]!,
                style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.blueAccent),
              ),
              const SizedBox(height: 15),
              Text(
                _data[_step - 1]["desc"]!,
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 16, color: Colors.grey[600]),
              ),
              const SizedBox(height: 40),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(3, (i) => Container(
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  width: _step == (i + 1) ? 25 : 10,
                  height: 10,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(5),
                    color: _step == (i + 1) ? Colors.blueAccent : Colors.grey[300],
                  ),
                )),
              ),
              const SizedBox(height: 50),
              SizedBox(
                width: double.infinity,
                height: 55,
                child: ElevatedButton(
                  onPressed: _nextStep,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blueAccent,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    elevation: 0,
                  ),
                  child: Text(_step < 3 ? "Lanjut" : "Mulai Sekarang", style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}