// 📁 lib/presentation/thix_sante/common/screens/_components/teleexpertise_content.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../widgets/gradient_button.dart';

class TeleexpertiseContent extends ConsumerStatefulWidget {
  const TeleexpertiseContent({Key? key}) : super(key: key);

  @override
  ConsumerState<TeleexpertiseContent> createState() => _TeleexpertiseContentState();
}

class _TeleexpertiseContentState extends ConsumerState<TeleexpertiseContent> {
  final List<Map<String, dynamic>> _requests = [
    {'doctor': 'Dr. Bernard', 'specialty': 'Dermatologue', 'date': '15/12/2024', 'status': 'pending', 'image': '🩺'},
    {'doctor': 'Dr. Martin', 'specialty': 'Cardiologue', 'date': '20/12/2024', 'status': 'accepted', 'image': '❤️'},
  ];
  String _description = '';
  String? _selectedDoctor;
  final List<String> _doctors = ['Dr. Bernard (Dermatologue)', 'Dr. Martin (Cardiologue)', 'Dr. Petit (Généraliste)'];

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Nouvelle demande
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.grey.shade100),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  '📸 Nouvelle demande d\'avis',
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  value: _selectedDoctor,
                  items: _doctors.map((d) => DropdownMenuItem(value: d, child: Text(d, style: const TextStyle(fontSize: 13)))).toList(),
                  onChanged: (v) => setState(() => _selectedDoctor = v),
                  decoration: InputDecoration(
                    labelText: 'Sélectionner un médecin',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                  ),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  maxLines: 3,
                  decoration: InputDecoration(
                    labelText: 'Description du problème',
                    hintText: 'Décrivez vos symptômes...',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                    contentPadding: const EdgeInsets.all(12),
                  ),
                  style: const TextStyle(fontSize: 13),
                  onChanged: (v) => _description = v,
                ),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey.shade300),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.add_photo_alternate, size: 20, color: Colors.grey),
                      const SizedBox(width: 8),
                      const Text('Ajouter une photo', style: TextStyle(fontSize: 12)),
                      const Spacer(),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade100,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: const Text('0/3', style: TextStyle(fontSize: 10)),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                GradientButton(
                  text: 'Envoyer la demande',
                  onPressed: () {},
                  icon: Icons.send,
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          const Text(
            '📋 Mes demandes',
            style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 12),
          ..._requests.map((req) => Container(
            margin: const EdgeInsets.only(bottom: 10),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: Colors.grey.shade100),
            ),
            child: Row(
              children: [
                Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    color: Colors.blue.shade50,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Center(
                    child: Text(req['image'], style: const TextStyle(fontSize: 28)),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(req['doctor'], style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
                      Text(req['specialty'], style: TextStyle(fontSize: 11, color: Colors.grey.shade600)),
                      Text('Demandé le ${req['date']}', style: TextStyle(fontSize: 10, color: Colors.grey.shade500)),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: req['status'] == 'pending' ? Colors.orange.shade50 : Colors.green.shade50,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    req['status'] == 'pending' ? 'En attente' : 'Accepté',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      color: req['status'] == 'pending' ? Colors.orange : Colors.green,
                    ),
                  ),
                ),
              ],
            ),
          )),
        ],
      ),
    );
  }
}
