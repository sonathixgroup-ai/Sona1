// lib/presentation/thix_weeding/pages/staff/staff_dashboard_page.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../thix_weeding/data/repositories/wedding_repository_impl.dart';

final weddingDetailProvider = FutureProvider.family<Map<String,dynamic>, String>((ref, weddingId) async {
  final res = await Supabase.instance.client.from('thix_weeding_weddings').select().eq('id', weddingId).single();
  return res;
});

final dashboardStatsProvider = FutureProvider.family<Map<String,dynamic>, String>((ref, weddingId) async {
  final supa = Supabase.instance.client;
  final invites = await supa.from('thix_weeding_rsvp').select().eq('wedding_id', weddingId).count(CountOption.exact);
  final vendors = await supa.from('thix_weeding_vendors').select().eq('wedding_id', weddingId).count(CountOption.exact);
  final gallery = await supa.from('thix_weeding_gallery').select().eq('wedding_id', weddingId).count(CountOption.exact);
  final guestbook = await supa.from('thix_weeding_guestbook').select().eq('wedding_id', weddingId).count(CountOption.exact);
  final checklist = await supa.from('thix_weeding_checklist').select().eq('wedding_id', weddingId).eq('is_done', false).count(CountOption.exact);
  final messages = await supa.from('thix_weeding_messages').select().eq('wedding_id', weddingId).eq('is_read', false).count(CountOption.exact);
  final budgetRow = await supa.from('thix_weeding_budget').select('total_budget, total_spent').eq('wedding_id', weddingId).maybeSingle();

  return {
    'invites': invites.count,
    'vendors': vendors.count,
    'gallery': gallery.count,
    'guestbook': guestbook.count,
    'checklist': checklist.count,
    'messages': messages.count,
    'totalBudget': (budgetRow?['total_budget'] as num?)?.toDouble()?? 3500000,
    'totalSpent': (budgetRow?['total_spent'] as num?)?.toDouble()?? 0,
  };
});

class StaffDashboardPage extends ConsumerWidget {
  final String weddingId;
  const StaffDashboardPage({super.key, required this.weddingId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final weddingAsync = ref.watch(weddingDetailProvider(weddingId));
    final statsAsync = ref.watch(dashboardStatsProvider(weddingId));

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: Row(children: [const Icon(Icons.menu), const SizedBox(width:12), Text('Mariage+', style: TextStyle(color: const Color(0xFF0B3B8F), fontWeight: FontWeight.w900)), Text('❤️', style: TextStyle(fontSize:12))]),
        actions: [IconButton(onPressed: () {}, icon: Badge(label: Text('3'), child: Icon(Icons.notifications_outlined))), const CircleAvatar(backgroundImage: NetworkImage('https://i.pravatar.cc/100'))],
      ),
      body: weddingAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e,s) => Center(child: Text('Erreur: $e')),
        data: (wedding) {
          final stats = statsAsync.value;
          final weddingDate = DateTime.tryParse(wedding['date']?? '')?? DateTime.now().add(const Duration(days:45));
          final daysLeft = weddingDate.difference(DateTime.now()).inDays;
          final coupleNames = wedding['couple_names']?? 'Jean & Grâce';
          final location = wedding['location_name']?? 'Hilton Yaoundé';
          final dateStr = wedding['date']?? '18 Août 2025';

          return RefreshIndicator(
            onRefresh: () async { ref.invalidate(weddingDetailProvider(weddingId)); ref.invalidate(dashboardStatsProvider(weddingId)); },
            child: ListView(padding: const EdgeInsets.all(16), children: [
              // HEADER CARD - Jean & Grâce
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius:10)]),
                child: Row(children: [
                  Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    const Text('Bonjour 👋', style: TextStyle(color: Colors.grey)),
                    Text(coupleNames, style: const TextStyle(fontSize:22, fontWeight: FontWeight.w900)),
                    const Text('Organisez votre mariage\nen toute sérénité 💖', style: TextStyle(fontSize:12)),
                    const SizedBox(height:16),
                    Row(children: [
                      _InfoChip(icon: Icons.calendar_today, label: 'Date du mariage', value: dateStr),
                      const SizedBox(width:12),
                      _InfoChip(icon: Icons.location_on, label: 'Lieu', value: location),
                    ]),
                    const SizedBox(height:16),
                    const Text('Progression globale', style: TextStyle(fontSize:11)),
                    const SizedBox(height:4),
                    Row(children: [
                      Expanded(child: LinearProgressIndicator(value: 0.65, backgroundColor: Colors.grey[200], color: const Color(0xFF0B3B8F))),
                      const SizedBox(width:8),
                      const Text('65%', style: TextStyle(fontSize:12, fontWeight: FontWeight.bold)),
                    ]),
                    const SizedBox(height:4),
                    const Text('Vous êtes sur la bonne voie! 😊', style: TextStyle(fontSize:11, color: Colors.grey)),
                  ])),
                  Expanded(child: Stack(alignment: Alignment.bottomCenter, children: [
                    ClipRRect(borderRadius: BorderRadius.circular(16), child: Image.network('https://images.unsplash.com/photo-1520854221256-17451ccdf07b?w=400', height:180, fit: BoxFit.cover)),
                    Positioned(bottom:8, child: ElevatedButton.icon(onPressed: () => context.push('/thix-weeding/guest/$weddingId/invitation'), icon: const Icon(Icons.mail_outline, size:16), label: const Text('Voir mon invitation'), style: ElevatedButton.styleFrom(backgroundColor: Colors.white, foregroundColor: const Color(0xFF0B3B8F)))),
                  ])),
                ]),
              ),
              const SizedBox(height:20),
              Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [const Text('Tableau de bord', style: TextStyle(fontWeight: FontWeight.w900, fontSize:16)), OutlinedButton.icon(onPressed: () {}, icon: const Icon(Icons.tune, size:16), label: const Text('Personnaliser'))]),
              const SizedBox(height:12),
              // GRID 4x2
              GridView.count(crossAxisCount:2, shrinkWrap:true, physics: const NeverScrollableScrollPhysics(), childAspectRatio:1.3, crossAxisSpacing:12, mainAxisSpacing:12, children: [
                _DashCard(title:'Invités', subtitle:'Gérez vos invités\net les RSVPs', icon: Icons.people, color: Colors.blue, badge: '${stats?['invites']?? 0}', onTap: () => context.push('/thix-weeding/staff/$weddingId/invites')),
                _DashCard(title:'Prestataires', subtitle:'Gérez vos\nprestataires', icon: Icons.store, color: Colors.purple, badge: '${stats?['vendors']?? 0}', onTap: () => context.push('/thix-weeding/staff/$weddingId/prestataires')),
                _DashCard(title:'Budget', subtitle:'Suivez vos dépenses\net votre budget', icon: Icons.attach_money, color: Colors.green, badge: '${(((stats?['totalSpent']?? 0)/(stats?['totalBudget']?? 1)*100).toInt())}%', onTap: () => context.push('/thix-weeding/staff/$weddingId/budget')),
                _DashCard(title:'Planning', subtitle:'Planifiez les tâches\net événements', icon: Icons.calendar_month, color: Colors.pink, badge: '', onTap: () => context.push('/thix-weeding/staff/$weddingId/planning')),
                _DashCard(title:'Checklist', subtitle:'Suivez toutes vos\ntâches', icon: Icons.checklist, color: Colors.orange, badge: '${stats?['checklist']?? 0}', onTap: () => context.push('/thix-weeding/staff/$weddingId/checklist')),
                _DashCard(title:'Galerie', subtitle:'Photos et vidéos\ndu mariage', icon: Icons.photo, color: Colors.blue, badge: '${stats?['gallery']?? 0}', onTap: () => context.push('/thix-weeding/staff/$weddingId/galerie')),
                _DashCard(title:'Livre d\'or', subtitle:'Messages et vœux\nde vos invités', icon: Icons.favorite_border, color: Colors.pink, badge: '${stats?['guestbook']?? 0}', onTap: () => context.push('/thix-weeding/staff/$weddingId/livre-or')),
                _DashCard(title:'Messages', subtitle:'Discussions avec vos\ninvités & prestataires', icon: Icons.chat_bubble_outline, color: Colors.blue, badge: '${stats?['messages']?? 0}', onTap: () => context.push('/thix-weeding/staff/$weddingId/messages')),
              ]),
              const SizedBox(height:16),
              Row(children: [
                Expanded(child: _PaymentsCard(totalSpent: stats?['totalSpent']?? 0, totalBudget: stats?['totalBudget']?? 3500000, onTap: () => context.push('/thix-weeding/staff/$weddingId/paiements'))),
                const SizedBox(width:12),
                Expanded(child: _CountdownCard(days: daysLeft, dateStr: dateStr)),
              ]),
              const SizedBox(height:80),
            ]),
          );
        },
      ),
    );
  }
}

class _InfoChip extends StatelessWidget {
  final IconData icon; final String label; final String value;
  const _InfoChip({required this.icon, required this.label, required this.value});
  @override Widget build(BuildContext context) => Row(children: [Container(padding: const EdgeInsets.all(8), decoration: BoxDecoration(color: const Color(0xFFEEF2FF), borderRadius: BorderRadius.circular(8)), child: Icon(icon, size:16, color: const Color(0xFF0B3B8F))), const SizedBox(width:8), Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(label, style: const TextStyle(fontSize:10, color: Colors.grey)), Text(value, style: const TextStyle(fontSize:12, fontWeight: FontWeight.bold))])]);
}

class _DashCard extends StatelessWidget {
  final String title; final String subtitle; final IconData icon; final Color color; final String badge; final VoidCallback onTap;
  const _DashCard({required this.title, required this.subtitle, required this.icon, required this.color, required this.badge, required this.onTap});
  @override Widget build(BuildContext context) => InkWell(onTap: onTap, child: Container(padding: const EdgeInsets.all(12), decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)), child: Stack(children: [Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Container(padding: const EdgeInsets.all(8), decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(10)), child: Icon(icon, color: color)), const SizedBox(height:8), Text(title, style: const TextStyle(fontWeight: FontWeight.w900)), const SizedBox(height:4), Text(subtitle, style: const TextStyle(fontSize:11, color: Colors.grey)), const Spacer(), Align(alignment: Alignment.centerRight, child: Icon(Icons.chevron_right, size:16, color: Colors.grey[400]))]), if(badge.isNotEmpty) Positioned(top:0, right:0, child: Container(padding: const EdgeInsets.symmetric(horizontal:6, vertical:2), decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(10)), child: Text(badge, style: const TextStyle(color: Colors.white, fontSize:10, fontWeight: FontWeight.bold))))])));
}

class _PaymentsCard extends StatelessWidget {
  final double totalSpent; final double totalBudget; final VoidCallback onTap;
  const _PaymentsCard({required this.totalSpent, required this.totalBudget, required this.onTap});
  @override Widget build(BuildContext context) => InkWell(onTap: onTap, child: Container(padding: const EdgeInsets.all(16), decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Row(children: [Container(padding: const EdgeInsets.all(8), decoration: BoxDecoration(color: Colors.green.withOpacity(0.1), borderRadius: BorderRadius.circular(10)), child: const Icon(Icons.credit_card, color: Colors.green)), const SizedBox(width:8), Column(crossAxisAlignment: CrossAxisAlignment.start, children: [const Text('Paiements', style: TextStyle(fontWeight: FontWeight.bold)), const Text('Suivez vos paiements\net transactions', style: TextStyle(fontSize:10, color: Colors.grey))]), const Spacer(), Text('${totalSpent.toStringAsFixed(0)} FCFA', style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.green, fontSize:12))]), const SizedBox(height:4), Align(alignment: Alignment.centerRight, child: Text('Total dépensé', style: TextStyle(fontSize:10, color: Colors.grey[600]))), const SizedBox(height:12), LinearProgressIndicator(value: (totalSpent/totalBudget).clamp(0,1), color: Colors.green), const SizedBox(height:4), Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text('Sur ${totalBudget.toStringAsFixed(0)} FCFA', style: const TextStyle(fontSize:10, color: Colors.grey)), const Icon(Icons.chevron_right, size:16)])])));
}

class _CountdownCard extends StatelessWidget {
  final int days; final String dateStr;
  const _CountdownCard({required this.days, required this.dateStr});
  @override Widget build(BuildContext context) => Container(padding: const EdgeInsets.all(16), decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text('J - $days ❤️', style: const TextStyle(fontWeight: FontWeight.w900, fontSize:16)), Text(dateStr, style: const TextStyle(fontSize:11, color: Colors.grey)), const SizedBox(height:12), Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [ _TimeBox(v:'$days', l:'Jours'), _TimeBox(v:'${DateTime.now().hour}', l:'Heures'), _TimeBox(v:'${DateTime.now().minute}', l:'Min'), _TimeBox(v:'${DateTime.now().second}', l:'Sec')]), const SizedBox(height:8), Align(alignment: Alignment.centerRight, child: Image.network('https://cdn-icons-png.flaticon.com/512/833/833472.png', width:60, height:60))]));
}
class _TimeBox extends StatelessWidget {
  final String v; final String l;
  const _TimeBox({required this.v, required this.l});
  @override Widget build(BuildContext context) => Column(children: [Text(v, style: const TextStyle(color: Colors.pink, fontWeight: FontWeight.bold, fontSize:16)), Text(l, style: const TextStyle(fontSize:10, color: Colors.grey))]);
}
