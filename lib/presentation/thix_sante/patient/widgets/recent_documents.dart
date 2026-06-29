// 📁 lib/presentation/thix_sante/patient/widgets/recent_documents.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../common/widgets/section_title.dart';

class RecentDocuments extends ConsumerWidget {
  const RecentDocuments({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // À connecter à patientDocumentsProvider
    final documents = [
      {'name': 'Ordonnance Dr Martin', 'date': '10/12/2024', 'icon': Icons.receipt},
      {'name': 'Analyse sanguine', 'date': '05/12/2024', 'icon': Icons.science},
      {'name': 'Radio thorax', 'date': '20/11/2024', 'icon': Icons.image},
    ];

    if (documents.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      children: [
        const SectionTitle(title: 'Documents récents', seeAllText: 'Voir tout', showDivider: false),
        const SizedBox(height: 8),
        ListView.separated(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: documents.length,
          separatorBuilder: (_, __) => const SizedBox(height: 8),
          itemBuilder: (context, index) {
            final doc = documents[index];
            return Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: Colors.grey.shade100),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.green.shade50,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(doc['icon'] as IconData, size: 20, color: Colors.green),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(doc['name']!, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500)),
                        Text(doc['date']!, style: TextStyle(fontSize: 10, color: Colors.grey.shade500)),
                      ],
                    ),
                  ),
                  const Icon(Icons.chevron_right, size: 18, color: Colors.grey),
                ],
              ),
            );
          },
        ),
      ],
    );
  }
}
