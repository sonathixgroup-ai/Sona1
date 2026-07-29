import 'dart:math';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'education_providers.dart'; // supabaseClientProvider
import '../models/certificate.dart';

String _genHash() {
  const chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
  final rnd = Random.secure();
  return List.generate(24, (_) => chars[rnd.nextInt(chars.length)]).join();
}

// SCALABLE 1M+ : 1 seule requête, pas de boucle N+1
class CertificatesNotifier extends FamilyAsyncNotifier<List<Certificate>, String> {
  @override
  Future<List<Certificate>> build(String userId) async {
    final client = ref.watch(supabaseClientProvider);
    // Direct sur certificates, pas sur formations
    final res = await client.from('certificates')
     .select('id,formation_id,verification_hash,issued_at,formation:formations(id,title,image_url)')
     .eq('user_id', userId)
     .order('issued_at', ascending: false)
     .limit(100); // limite scalable
    return res.map((e) => Certificate.fromJson(e)).toList();
  }

  Future<Certificate?> getByFormation(String formationId) async {
    final client = ref.read(supabaseClientProvider);
    final res = await client.from('certificates')
     .select()
     .eq('user_id', arg)
     .eq('formation_id', formationId)
     .maybeSingle();
    return res == null ? null : Certificate.fromJson(res);
  }

  Future<Certificate?> generateCertificate(String formationId) async {
    final userId = arg;
    final client = ref.read(supabaseClientProvider);
    try {
      // Si tu as une RPC Edge Function, utilise-la. Sinon insert direct (RLS vérifie 100%)
      final res = await client.from('certificates').insert({
        'user_id': userId,
        'formation_id': formationId,
        'verification_hash': _genHash(),
      }).select('id,formation_id,verification_hash,issued_at').single();
      
      final cert = Certificate.fromJson(res);
      // Invalide la liste pour refresh auto
      ref.invalidateSelf();
      return cert;
    } catch (e) {
      // Si déjà existant ou pas 100% complété, la RLS renvoie une erreur
      rethrow;
    }
  }
}

final certificatesProvider = AsyncNotifierProvider.family<CertificatesNotifier, List<Certificate>, String>(CertificatesNotifier.new);

// Pour la page détail certificat
final certificateByIdProvider = FutureProvider.family<Certificate?, String>((ref, String certId) async {
  final client = ref.watch(supabaseClientProvider);
  final res = await client.from('certificates').select().eq('id', certId).maybeSingle();
  return res == null ? null : Certificate.fromJson(res);
});
