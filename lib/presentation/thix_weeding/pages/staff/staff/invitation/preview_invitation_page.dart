// lib/presentation/thix_weeding/pages/staff/invitation/preview_invitation_page.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:go_router/go_router.dart';
import 'package:share_plus/share_plus.dart';

final weddingInvitationProvider = FutureProvider.family<Map<String,dynamic>, String>((ref, weddingId) async {
  return await Supabase.instance.client.from('thix_weeding_weddings').select().eq('id', weddingId).single();
});

class PreviewInvitationPage extends ConsumerWidget {
  final String weddingId;
  const PreviewInvitationPage({super.key, required this.weddingId});

  @override Widget build(BuildContext context, WidgetRef ref){
    final async = ref.watch(weddingInvitationProvider(weddingId));
    return Scaffold(
      backgroundColor: const Color(0xFFF8F5F0),
      appBar: AppBar(title: const Text('Aperçu invitation'), backgroundColor: Colors.white, actions: [
        IconButton(icon: const Icon(Icons.edit), onPressed: ()=> context.push('/thix-weeding/staff/$weddingId/parametres')),
      ]),
      body: async.when(
        loading: ()=> const Center(child: CircularProgressIndicator()),
        error: (e,s)=> Center(child: Text('Erreur $e')),
        data: (w){
          final bride = w['bride_name']??'Mariée';
          final groom = w['groom_name']??'Marié';
          final date = w['wedding_date']??'Date à définir';
          final venue = w['venue']??'Lieu à définir';
          final invitationUrl = 'https://thix.id/w/$weddingId';
          return ListView(padding: const EdgeInsets.all(20), children: [
            // CARD INVITATION - DESIGN PROD
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(24),
                boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.08), blurRadius: 20, offset: const Offset(0,10))],
                border: Border.all(color: const Color(0xFFE8D5C4), width:1),
              ),
              child: Column(children: [
                const Text('Nous nous marions !', style: TextStyle(fontFamily:'Serif', letterSpacing:2, fontSize:12, color: Colors.grey)),
                const SizedBox(height:20),
                Text('$bride', style: const TextStyle(fontSize:32, fontWeight: FontWeight.w900, fontFamily:'Serif')),
                const Text('&', style: TextStyle(fontSize:24, color: Color(0xFFD4A373))),
                Text('$groom', style: const TextStyle(fontSize:32, fontWeight: FontWeight.w900, fontFamily:'Serif')),
                const SizedBox(height:20),
                Container(height:1, width:60, color: const Color(0xFFE8D5C4)),
                const SizedBox(height:20),
                Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                  const Icon(Icons.calendar_today, size:16, color: Color(0xFF0B3B8F)),
                  const SizedBox(width:6),
                  Text(date.toString(), style: const TextStyle(fontWeight: FontWeight.bold)),
                ]),
                const SizedBox(height:8),
                Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                  const Icon(Icons.location_on, size:16, color: Color(0xFF0B3B8F)),
                  const SizedBox(width:6),
                  Flexible(child: Text(venue, style: const TextStyle(fontWeight: FontWeight.w500), textAlign: TextAlign.center)),
                ]),
                const SizedBox(height:24),
                Text('ID Invitation: $weddingId', style: const TextStyle(fontSize:10, color: Colors.grey, letterSpacing:1)),
              ]),
            ),
            const SizedBox(height:24),
            Container(padding: const EdgeInsets.all(16), decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const Text('Lien d\'invitation public', style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height:8),
              SelectableText(invitationUrl, style: const TextStyle(color: Colors.blue, fontSize:13)),
              const SizedBox(height:12),
              Row(children: [
                Expanded(child: FilledButton.icon(onPressed: () async {
                  await Supabase.instance.client.from('thix_weeding_weddings').update({'invitation_published': true}).eq('id', weddingId);
                  ref.invalidate(weddingInvitationProvider(weddingId));
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Invitation publiée')));
                }, icon: const Icon(Icons.public), label: Text(w['invitation_published']==true?'Déjà publiée':'Publier'))),
                const SizedBox(width:12),
                Expanded(child: OutlinedButton.icon(onPressed: ()=> Share.share('Vous êtes invités au mariage de $bride & $groom le $date à $venue \n$invitationUrl'), icon: const Icon(Icons.share), label: const Text('Partager'))),
              ]),
            ])),
            const SizedBox(height:16),
            const Text('Chaque invité recevra un lien unique avec son propre ID: https://thix.id/w/$weddingId?guest=UUID', style: TextStyle(fontSize:11, color: Colors.grey), textAlign: TextAlign.center),
          ]);
        },
      ),
    );
  }
}
