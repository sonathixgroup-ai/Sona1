// lib/presentation/network/widgets/opportunities_section.dart
import 'package:flutter/material.dart';
import 'package:thix_id/presentation/network/models/opportunity_model.dart';

class OpportunitiesSection extends StatelessWidget {
  final List<OpportunityModel> opportunities;
  const OpportunitiesSection({Key? key, required this.opportunities}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (opportunities.isEmpty) return const SizedBox.shrink();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Suggestions pour vous', style: TextStyle(fontWeight: FontWeight.w900)),
        const SizedBox(height: 8),
        SizedBox(
          height: 140,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: opportunities.length,
            separatorBuilder: (_, __) => const SizedBox(width: 12),
            itemBuilder: (context, index) {
              final o = opportunities[index];
              return SizedBox(
                width: 260,
                child: Card(
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text(o.title, style: const TextStyle(fontWeight: FontWeight.w800)),
                      const SizedBox(height: 8),
                      Text(o.company, style: const TextStyle(color: Colors.grey)),
                      const Spacer(),
                      ElevatedButton(onPressed: () {}, child: const Text('Voir'))
                    ]),
                  ),
                ),
              );
            },
          ),
        )
      ],
    );
  }
}
