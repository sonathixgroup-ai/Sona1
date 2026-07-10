// lib/presentation/mon_pays/cards/agency_card.dart

import 'package:flutter/material.dart';
import '../models/agency_model.dart';
import '../utils/mon_pays_colors.dart';
import '../utils/mon_pays_text_styles.dart';

class AgencyCard extends StatelessWidget {
  final Agency agency;
  final VoidCallback? onTap;

  const AgencyCard({Key? key, required this.agency, this.onTap})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Card(
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Container(
          padding: const EdgeInsets.all(8),
          width: 100,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.network(
                  agency.logoUrl ?? 'https://via.placeholder.com/80',
                  height: 50,
                  width: 50,
                  fit: BoxFit.contain,
                  errorBuilder: (_, __, ___) => const Icon(
                    Icons.account_balance,
                    size: 40,
                    color: MonPaysColors.primaryRed,
                  ),
                ),
              ),
              const SizedBox(height: 6),
              Text(
                agency.name,
                style: MonPaysTextStyles.caption.copyWith(
                  fontWeight: FontWeight.w600,
                  color: MonPaysColors.primaryBlue,
                  fontSize: 11,
                ),
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
