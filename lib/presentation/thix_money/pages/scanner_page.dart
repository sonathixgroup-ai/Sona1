// lib/presentation/thix_money/pages/scanner_page.dart
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../services/qr_service.dart';

class ScannerPage extends StatefulWidget {
  const ScannerPage({super.key});
  @override
  State<ScannerPage> createState() => _ScannerPageState();
}

class _ScannerPageState extends State<ScannerPage> {
  final _manualCtrl = TextEditingController();

  void _onScan(String raw) {
    final data = QrService.decodeThixQr(raw);
    if (data == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('QR invalide')));
      return;
    }
    if (data['thix_id']!= null) {
      context.push('/thix-money/send', extra: {'thix_id': data['thix_id'], 'name': data['name']});
    } else if (data['phone']!= null) {
      context.push('/thix-money/send', extra: {'phone': data['phone']});
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Scanner THIX ID')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(children: [
          Container(height: 300, decoration: BoxDecoration(color: Colors.black12, borderRadius: BorderRadius.circular(16), border: Border.all(color: Colors.blue)), child: const Center(child: Icon(Icons.qr_code_scanner, size: 120, color: Colors.black26))),
          const SizedBox(height: 16),
          const Text('Scannez le QR THIX ID d\'un utilisateur pour lui envoyer de l\'argent instantanément. Vérification en base automatique.', textAlign: TextAlign.center, style: TextStyle(color: Colors.grey)),
          const SizedBox(height: 24),
          TextField(controller: _manualCtrl, decoration: const InputDecoration(labelText: 'Ou saisir THIX ID / Téléphone manuellement', border: OutlineInputBorder())),
          const SizedBox(height: 12),
          SizedBox(width: double.infinity, child: ElevatedButton(onPressed: () => _onScan(_manualCtrl.text), child: const Text('Vérifier et envoyer'))),
        ]),
      ),
    );
  }
}
