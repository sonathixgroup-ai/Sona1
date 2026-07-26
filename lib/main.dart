import 'package:flutter/material.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        backgroundColor: const Color(0xFF0B3D91),
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('THIX ID CENTRAL', style: TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.w900)),
              const SizedBox(height: 12),
              const Text('UNE IDENTITÉ VÉRIFIÉE\navenir de confiance', textAlign: TextAlign.center, style: TextStyle(color: Color(0xFFF7C948), fontWeight: FontWeight.w700)),
              const SizedBox(height: 24),
              ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: Color(0xFFF7C948)),
                onPressed: () {},
                child: const Text('TEST OK - APP MARCHE', style: TextStyle(color: Color(0xFF0B3D91), fontWeight: FontWeight.w900)),
              ),
              const SizedBox(height: 12),
              const Text('BY SONATHIX GROUP', style: TextStyle(color: Colors.white54, fontSize: 11, letterSpacing: 1.2)),
            ],
          ),
        ),
      ),
    );
  }
}
