// 📁 lib/presentation/thix_sante/patient/widgets/health_tips_carousel.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../common/widgets/section_title.dart';

class HealthTipsCarousel extends ConsumerWidget {
  const HealthTipsCarousel({Key? key}) : super(key: key);

  final List<Map<String, String>> tips = const [
    {'title': '5 conseils pour rester en bonne santé', 'duration': '3 min', 'icon': '💪'},
    {'title': 'Alimentation équilibrée : les bases', 'duration': '4 min', 'icon': '🥗'},
    {'title': 'Gérer le stress au quotidien', 'duration': '3 min', 'icon': '🧘'},
    {'title': 'Prévention : un geste qui sauve', 'duration': '2 min', 'icon': '🩺'},
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Column(
      children: [
        const SectionTitle(title: 'Pour vous', seeAllText: 'Voir tout', showDivider: false),
        const SizedBox(height: 8),
        SizedBox(
          height: 110,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: tips.length,
            separatorBuilder: (_, __) => const SizedBox(width: 12),
            itemBuilder: (context, index) {
              final tip = tips[index];
              return Container(
                width: 180,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: Colors.grey.shade100),
                ),
                child: Row(
                  children: [
                    Text(tip['icon']!, style: const TextStyle(fontSize: 28)),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            tip['title']!,
                            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            tip['duration']!,
                            style: TextStyle(fontSize: 10, color: Colors.grey.shade500),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}
