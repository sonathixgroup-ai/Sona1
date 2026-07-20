// lib/presentation/thix_event/widgets/seat_legend.dart
import 'package:flutter/material.dart';

// 🟢 IMPORTEZ VOTRE PACKAGE DE TRADUCTION ICI
// Ex: import 'package:easy_localization/easy_localization.dart';
// Ex: import 'package:flutter_gen/gen_l10n/app_localizations.dart';

class _ThixColors {
  static const Color primary = Color(0xFF6B3CE2);
  static const Color darkText = Color(0xFF1E1B4B);
  static const Color border = Color(0xFFEEE9FF);
  
  static const Color seatAvailable = Color(0xFF10B981); 
  static const Color seatReserved = Color(0xFFF59E0B); 
  static const Color seatSold = Color(0xFFEF4444); 
}

class SeatLegend extends StatelessWidget {
  const SeatLegend({super.key});

  @override
  Widget build(BuildContext context) {
    // 🟢 INITIALISEZ VOTRE TRADUCTION ICI (si vous utilisez le standard Flutter)
    // final l10n = AppLocalizations.of(context)!;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      margin: const EdgeInsets.symmetric(horizontal: 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _ThixColors.border, width: 1.5),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 10, offset: const Offset(0, 4)),
        ],
      ),
      child: Wrap(
        spacing: 16,
        runSpacing: 12,
        alignment: WrapAlignment.center,
        children: [
          // 🟢 REMPLACEZ LE TEXTE FRANÇAIS PAR VOS VARIABLES DE TRADUCTION
          // Exemple easy_localization : label: 'seat_available'.tr()
          // Exemple standard : label: l10n.seatAvailable
          
          _LegendItem(color: _ThixColors.seatAvailable, label: 'Disponible'), 
          _LegendItem(color: _ThixColors.primary, label: 'Sélectionnée'), 
          _LegendItem(color: _ThixColors.seatReserved, label: 'Réservée (15min)'),
          _LegendItem(color: _ThixColors.seatSold, label: 'Vendue'),
        ],
      ),
    );
  }
}

class _LegendItem extends StatelessWidget {
  final Color color;
  final String label;

  const _LegendItem({required this.color, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 18,
          height: 18,
          decoration: BoxDecoration(
            color: color.withOpacity(0.12),
            border: Border.all(color: color, width: 2),
            borderRadius: BorderRadius.circular(6),
          ),
        ),
        const SizedBox(width: 8),
        Text(
          label, 
          style: const TextStyle(
            fontSize: 11, 
            fontWeight: FontWeight.w700, 
            color: _ThixColors.darkText,
          ),
        ),
      ],
    );
  }
}
