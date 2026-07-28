import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../providers/event_provider.dart';
import '../../models/event_booking.dart';

class _ThixColors {
  static const bg = Color(0xFF050508);
  static const surface = Color(0xFF0C0C12);
  static const surfaceAlt = Color(0xFF111118);
  static const cardBorder = Color(0x14FFFFFF);
  static const cardBorderStrong = Color(0x26FFFFFF);
  static const primary = Color(0xFFFF0A54);
  static const textSecondary = Color(0x99FFFFFF);
  static const textMuted = Color(0x66FFFFFF);
}

class MyTicketsPage extends ConsumerStatefulWidget {
  const MyTicketsPage({super.key});
  @override
  ConsumerState<MyTicketsPage> createState() => _MyTicketsPageState();
}

class _MyTicketsPageState extends ConsumerState<MyTicketsPage> {
  List<EventBooking> _tickets = [];
  bool _loading = true;

  @override
  void initState() { super.initState(); _load(); }

  Future<void> _load() async {
    try {
      final t = await ref.read(eventServiceProvider).getMyTickets();
      if (mounted) setState(() { _tickets = t; _loading = false; });
    } catch (_) { if (mounted) setState(() => _loading = false); }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _ThixColors.bg,
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(52),
        child: ClipRRect(
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
            child: AppBar(
              backgroundColor: _ThixColors.bg.withOpacity(0.85),
              elevation: 0,
              leading: Padding(padding: const EdgeInsets.all(8), child: InkWell(onTap: () => context.go('/thix-event'), child: Container(decoration: BoxDecoration(color: Colors.white.withOpacity(0.06), shape: BoxShape.circle, border: Border.all(color: _ThixColors.cardBorder)), child: const Icon(Icons.arrow_back_rounded, color: Colors.white, size: 18)))),
              title: const Text('Mes billets', style: TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w800)),
              centerTitle: true,
            ),
          ),
        ),
      ),
      body: _loading
         ? const Center(child: CircularProgressIndicator(color: _ThixColors.primary))
          : _tickets.isEmpty
             ? _empty()
              : RefreshIndicator(
                  color: _ThixColors.primary,
                  backgroundColor: _ThixColors.surface,
                  onRefresh: () async => _load(),
                  child: ListView.builder(
                    physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
                    itemCount: _tickets.length,
                    itemBuilder: (_, i) => _card(_tickets[i]),
                  ),
                ),
    );
  }

  Widget _card(EventBooking ticket) {
    final upcoming = DateTime.now().isBefore(ticket.eventDate);
    return GestureDetector(
      onTap: () => context.push('/thix-event/ticket/${ticket.id}'),
      child: Container(
        margin: const EdgeInsets.only(bottom: 14),
        decoration: BoxDecoration(color: _ThixColors.surface, borderRadius: BorderRadius.circular(20), border: Border.all(color: _ThixColors.cardBorder)),
        clipBehavior: Clip.antiAlias,
        child: Column(children: [
          Padding(padding: const EdgeInsets.all(12), child: Row(children: [
            ClipRRect(borderRadius: BorderRadius.circular(12), child: ticket.eventImageUrl!= null && ticket.eventImageUrl!.isNotEmpty? Image.network(ticket.eventImageUrl!, width: 72, height: 72, fit: BoxFit.cover, errorBuilder: (_, __, ___) => Container(width: 72, height: 72, color: _ThixColors.surfaceAlt, child: const Icon(Icons.confirmation_num_rounded, color: _ThixColors.textMuted))) : Container(width: 72, height: 72, decoration: BoxDecoration(color: _ThixColors.primary.withOpacity(0.12), borderRadius: BorderRadius.circular(12)), child: const Icon(Icons.confirmation_num_rounded, color: _ThixColors.primary))),
            const SizedBox(width: 12),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3), decoration: BoxDecoration(color: upcoming? Colors.green.withOpacity(0.12) : Colors.white.withOpacity(0.06), borderRadius: BorderRadius.circular(8), border: Border.all(color: upcoming? Colors.green.withOpacity(0.2) : _ThixColors.cardBorder)), child: Text(upcoming? 'À VENIR' : 'TERMINÉ', style: TextStyle(fontSize: 9, fontWeight: FontWeight.w800, color: upcoming? Colors.green : _ThixColors.textMuted))),
              const SizedBox(height: 8),
              Text(ticket.eventTitle, maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w800, height: 1.2)),
              const SizedBox(height: 4),
              Text(DateFormat('dd MMM yyyy • HH:mm', 'fr').format(ticket.eventDate), style: const TextStyle(color: _ThixColors.textMuted, fontSize: 11, fontWeight: FontWeight.w500)),
            ])),
            Container(height: 32, width: 32, decoration: BoxDecoration(color: Colors.white.withOpacity(0.06), shape: BoxShape.circle, border: Border.all(color: _ThixColors.cardBorder)), child: const Icon(Icons.arrow_outward_rounded, size: 14, color: Colors.white)),
          ])),
          Container(padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10), decoration: BoxDecoration(color: _ThixColors.surfaceAlt, border: Border(top: BorderSide(color: _ThixColors.cardBorder))), child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            Row(children: [const Icon(Icons.sell_rounded, size: 12, color: _ThixColors.textSecondary), const SizedBox(width: 6), Text('${ticket.ticketQuantity} billet(s)', style: const TextStyle(color: _ThixColors.textSecondary, fontSize: 11, fontWeight: FontWeight.w600))]),
            Text('${ticket.totalPrice.toInt()} FC', style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w900)),
          ])),
        ]),
      ),
    );
  }

  Widget _empty() {
    return Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
      Container(padding: const EdgeInsets.all(20), decoration: BoxDecoration(color: _ThixColors.surface, shape: BoxShape.circle, border: Border.all(color: _ThixColors.cardBorder)), child: const Icon(Icons.local_activity_rounded, size: 32, color: _ThixColors.textMuted)),
      const SizedBox(height: 14),
      const Text('Aucun billet', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 15)),
      const SizedBox(height: 6),
      const Text('Vos réservations apparaîtront ici', style: TextStyle(color: _ThixColors.textMuted, fontSize: 12)),
      const SizedBox(height: 18),
      ElevatedButton(onPressed: () => context.go('/thix-event'), style: ElevatedButton.styleFrom(backgroundColor: Colors.white, foregroundColor: Colors.black, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(23)), padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 10)), child: const Text('Découvrir', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 12))),
    ]));
  }
}
