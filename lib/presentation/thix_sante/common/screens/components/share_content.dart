// 📁 lib/presentation/thix_sante/common/screens/_components/share_content.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../services/supabase/supabase_storage.dart';
import '../../widgets/gradient_button.dart';
import '../../widgets/pill_badge.dart';

class ShareContent extends ConsumerStatefulWidget {
  const ShareContent({Key? key}) : super(key: key);

  @override
  ConsumerState<ShareContent> createState() => _ShareContentState();
}

class _ShareContentState extends ConsumerState<ShareContent> {
  final List<Map<String, dynamic>> _sharedWith = [
    {'name': 'Dr. Martin', 'role': 'Médecin traitant', 'access': 'Complet', 'expires': null},
    {'name': 'Dr. Bernard', 'role': 'Cardiologue', 'access': 'Complet', 'expires': null},
    {'name': 'Pharmacie Dubois', 'role': 'Pharmacie', 'access': 'Ordonnances', 'expires': null},
  ];
  String _selectedAccess = 'Complet';
  DateTime? _expiryDate;
  String _shareLink = '';

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Nouveau partage
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
                  '🔗 Partager mon dossier',
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  decoration: InputDecoration(
                    labelText: 'Email du médecin ou pharmacien',
                    hintText: 'medecin@exemple.com',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                  ),
                  style: const TextStyle(fontSize: 13),
                ),
                const SizedBox(height: 12),
                // Niveau d'accès
                const Text('Niveau d\'accès', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500)),
                const SizedBox(height: 6),
                Row(
                  children: [
                    _buildAccessChip('Complet', 'Complet'),
                    const SizedBox(width: 8),
                    _buildAccessChip('Lecture seule', 'Lecture seule'),
                    const SizedBox(width: 8),
                    _buildAccessChip('Ordonnances', 'Ordonnances'),
                  ],
                ),
                const SizedBox(height: 12),
                // Date d'expiration
                GestureDetector(
                  onTap: () async {
                    final picked = await showDatePicker(
                      context: context,
                      initialDate: DateTime.now().add(const Duration(days: 30)),
                      firstDate: DateTime.now(),
                      lastDate: DateTime(2030),
                    );
                    if (picked != null) setState(() => _expiryDate = picked);
                  },
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey.shade300),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.calendar_today, size: 16),
                        const SizedBox(width: 8),
                        Text(
                          _expiryDate == null ? 'Expiration (optionnel)' : 'Expire le ${_expiryDate!.day}/${_expiryDate!.month}/${_expiryDate!.year}',
                          style: TextStyle(fontSize: 12, color: _expiryDate == null ? Colors.grey.shade500 : Colors.black),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                GradientButton(
                  text: 'Envoyer l\'invitation',
                  onPressed: () {},
                  icon: Icons.send,
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          // Lien de partage
          const Text(
            '📎 Lien de partage sécurisé',
            style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.grey.shade50,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    _shareLink.isEmpty ? 'thix-sante.com/share/xxxxx' : _shareLink,
                    style: TextStyle(fontSize: 11, color: _shareLink.isEmpty ? Colors.grey.shade500 : Colors.blue),
                  ),
                ),
                if (_shareLink.isEmpty)
                  GradientButton(
                    text: 'Générer',
                    onPressed: () {
                      setState(() {
                        _shareLink = 'thix-sante.com/share/${DateTime.now().millisecondsSinceEpoch}';
                      });
                    },
                    width: 80,
                    height: 36,
                  )
                else
                  Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.copy, size: 18),
                        onPressed: () => ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Lien copié'))),
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete_outline, size: 18),
                        onPressed: () => setState(() => _shareLink = ''),
                      ),
                    ],
                  ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          // Partages actifs
          const Text(
            '👥 Personnes avec accès',
            style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 12),
          ..._sharedWith.map((s) => Container(
            margin: const EdgeInsets.only(bottom: 10),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey.shade100),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.blue.shade50,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(s['role'] == 'Pharmacie' ? Icons.medication : Icons.local_hospital, size: 18, color: Colors.blue),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(s['name'], style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
                      Text(s['role'], style: TextStyle(fontSize: 10, color: Colors.grey.shade600)),
                    ],
                  ),
                ),
                PillBadge.info(s['access']),
                IconButton(
                  icon: const Icon(Icons.delete_outline, size: 18),
                  onPressed: () {},
                ),
              ],
            ),
          )),
        ],
      ),
    );
  }

  Widget _buildAccessChip(String label, String value) {
    final isSelected = _selectedAccess == value;
    return GestureDetector(
      onTap: () => setState(() => _selectedAccess = value),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? Colors.green : Colors.grey.shade100,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          label,
          style: TextStyle(fontSize: 11, color: isSelected ? Colors.white : Colors.grey.shade700),
        ),
      ),
    );
  }
}
