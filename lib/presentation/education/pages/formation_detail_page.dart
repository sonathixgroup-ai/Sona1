import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/formation.dart';
import '../models/lesson.dart';
import 'package:thix_id/presentation/education/providers/education_provider.dart'; // ✅ VRAI (sans le "s")
import '../widgets/common/education_empty_state.dart';
import '../widgets/common/education_loading_shimmer.dart';
import '../widgets/formation_detail/formation_module_list.dart';

class FormationDetailPage extends ConsumerWidget {
  final String formationId;
  const FormationDetailPage({super.key, required this.formationId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final formationAsync = ref.watch(formationDetailProvider(formationId));
    final userId = Supabase.instance.client.auth.currentUser?.id;
    final enrollmentAsync = userId == null ? null : ref.watch(enrollmentProvider((userId: userId, formationId: formationId)));

    return formationAsync.when(
      loading: () => const Scaffold(body: EducationLoadingShimmer()),
      error: (e, _) => Scaffold(body: Center(child: Text('Erreur: $e', style: const TextStyle(color: Colors.redAccent)))),
      data: (formation) {
        if (formation == null) {
          return Scaffold(body: EducationEmptyState(title: 'Formation introuvable', subtitle: 'Cette formation n\'existe pas ou a été supprimée.', icon: Icons.school_rounded, buttonText: 'Retourner à la liste', onButtonPressed: () => context.pop()));
        }
        return Scaffold(
          backgroundColor: Colors.grey[50],
          appBar: AppBar(
            title: Text(formation.title, style: const TextStyle(fontWeight: FontWeight.w800, color: Color(0xFF1A1A2E))), 
            backgroundColor: Colors.white, 
            elevation: 0, 
            leading: IconButton(icon: const Icon(Icons.arrow_back_rounded, color: Color(0xFF1A1A2E)), onPressed: () => context.pop())
          ),
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(16), 
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start, 
              children: [
                _buildHeader(formation),
                const SizedBox(height: 16),
                _buildDescription(formation),
                const SizedBox(height: 16),
                _buildInfoRow(formation),
                const SizedBox(height: 24),
                
                // Bouton d'inscription ou de continuation
                _buildEnrollButton(context, ref, formation, enrollmentAsync, userId),
                
                const SizedBox(height: 24),
                FormationModuleList(formation: formation, onLessonTap: (lesson) => _openLesson(context, lesson, enrollmentAsync)),
                const SizedBox(height: 32),
              ]
            )
          ),
        );
      },
    );
  }

  Widget _buildHeader(Formation formation) {
    return Container(
      width: double.infinity, 
      padding: const EdgeInsets.all(16), 
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), boxShadow: [BoxShadow(color: const Color(0xFF0A1F44).withOpacity(0.06), blurRadius: 12, offset: const Offset(0, 4))]), 
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start, 
        children: [
          Text(formation.title, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: Color(0xFF1A1A2E))),
          const SizedBox(height: 12),
          if (formation.instructorName != null && formation.instructorName!.isNotEmpty) 
            Row(children: [const Icon(Icons.person_outline_rounded, size: 16, color: Color(0xFF7386A8)), const SizedBox(width: 6), Text(formation.instructorName!, style: const TextStyle(color: Color(0xFF7386A8), fontSize: 14, fontWeight: FontWeight.w600))]),
          const SizedBox(height: 8),
          Row(
            children: [
              const Icon(Icons.school_rounded, size: 16, color: Color(0xFF7386A8)), 
              const SizedBox(width: 6), 
              Text(formation.category?.name ?? 'Non catégorisé', style: const TextStyle(color: Color(0xFF7386A8), fontSize: 14, fontWeight: FontWeight.w500)), 
              const Spacer(), 
              if (formation.level.isNotEmpty) 
                Container(padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4), decoration: BoxDecoration(color: const Color(0xFF2D6CDF).withOpacity(0.1), borderRadius: BorderRadius.circular(12)), child: Text(formation.level == 'beginner'? 'Débutant' : formation.level == 'intermediate'? 'Intermédiaire' : 'Avancé', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: Color(0xFF2D6CDF))))
            ]
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              const Icon(Icons.access_time_rounded, size: 16, color: Color(0xFF7386A8)), 
              const SizedBox(width: 6), 
              Text('${formation.duration ~/ 60}h ${formation.duration % 60}min', style: const TextStyle(color: Color(0xFF7386A8), fontSize: 14, fontWeight: FontWeight.w500)), 
              const Spacer(), 
              if (formation.price > 0) 
                Text('${formation.price.toInt()} ${formation.currency}', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: Color(0xFF2D6CDF))) 
              else 
                Container(padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4), decoration: BoxDecoration(color: const Color(0xFF10B981).withOpacity(0.1), borderRadius: BorderRadius.circular(12)), child: const Text('Gratuit', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: Color(0xFF10B981))))
            ]
          ),
        ]
      )
    );
  }

  Widget _buildDescription(Formation f) => Container(padding: const EdgeInsets.all(16), decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), boxShadow: [BoxShadow(color: const Color(0xFF0A1F44).withOpacity(0.06), blurRadius: 12, offset: const Offset(0, 4))]), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [const Text('Description', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: Color(0xFF1A1A2E))), const SizedBox(height: 8), Text(f.description, style: const TextStyle(fontSize: 14, height: 1.6, color: Color(0xFF475569)))]));
  
  Widget _buildInfoRow(Formation f) {
    final totalLessons = f.modules?.fold<int>(0, (sum, m) => sum + (m.lessons?.length ?? 0)) ?? 0;
    return Container(padding: const EdgeInsets.all(16), decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), boxShadow: [BoxShadow(color: const Color(0xFF0A1F44).withOpacity(0.06), blurRadius: 12, offset: const Offset(0, 4))]), child: Row(mainAxisAlignment: MainAxisAlignment.spaceAround, children: [
      _info(Icons.people_rounded, '${f.enrollments?.length ?? 0}', 'Élèves'),
      _info(Icons.video_library_rounded, '$totalLessons', 'Leçons'),
      _info(Icons.star_rounded, f.rating.toStringAsFixed(1), 'Note'),
    ]));
  }
  
  Widget _info(IconData i, String v, String l) => Column(children: [Icon(i, color: const Color(0xFF2D6CDF)), const SizedBox(height: 6), Text(v, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: Color(0xFF1A1A2E))), Text(l, style: const TextStyle(fontSize: 12, color: Color(0xFF7386A8), fontWeight: FontWeight.w500))]);

  Widget _buildEnrollButton(BuildContext context, WidgetRef ref, Formation formation, AsyncValue? enrollmentAsync, String? userId) {
    final isEnrolled = enrollmentAsync?.value != null;
    final progress = enrollmentAsync?.value?['progress'] ?? 0.0;
    
    if (isEnrolled) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16), 
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), border: Border.all(color: const Color(0xFFE2E8F0))), 
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Votre progression', style: TextStyle(fontWeight: FontWeight.w700, color: Color(0xFF1A1A2E))),
                Text('${(progress * 100).toInt()}%', style: const TextStyle(fontWeight: FontWeight.w800, color: Color(0xFF2D6CDF))),
              ],
            ),
            const SizedBox(height: 8),
            LinearProgressIndicator(value: (progress as num).toDouble(), backgroundColor: const Color(0xFFF1F5F9), color: const Color(0xFF2D6CDF), borderRadius: BorderRadius.circular(4), minHeight: 8),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity, height: 48, 
              child: ElevatedButton.icon(
                onPressed: () {
                   // Logique pour lancer la dernière leçon en cours (ou ouvrir le premier module)
                },
                icon: const Icon(Icons.play_circle_fill_rounded),
                label: const Text('Continuer l\'apprentissage', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 15)),
                style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF2D6CDF), foregroundColor: Colors.white, elevation: 0, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
              )
            )
          ]
        )
      );
    }
    
    // Cas : L'utilisateur n'est pas encore inscrit
    return SizedBox(
      width: double.infinity, 
      height: 52, 
      child: ElevatedButton(
        onPressed: () {
          if (userId == null) { 
            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Veuillez vous connecter pour vous inscrire.'))); 
            return; 
          }
          // Lancement de la procédure de vérification THIX ID
          _showThixIdVerificationSheet(context, ref, userId, formation.id);
        },
        style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF2D6CDF), foregroundColor: Colors.white, elevation: 0, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))),
        child: const Text('S\'inscrire à cette formation', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
      )
    );
  }

  void _openLesson(BuildContext context, Lesson lesson, AsyncValue? enrollmentAsync) {
    final isEnrolled = enrollmentAsync?.value != null;
    if (!isEnrolled) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Veuillez vous inscrire pour accéder au contenu.')));
      return;
    }
    context.push('/education/lesson/${lesson.id}', extra: {'formationId': formationId, 'moduleId': lesson.moduleId, 'lesson': lesson});
  }

  // ============================================================================
  // LOGIQUE DE SÉCURITÉ : VÉRIFICATION THIX ID
  // ============================================================================
  void _showThixIdVerificationSheet(BuildContext context, WidgetRef ref, String userId, String formationId) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
        child: _ThixIdVerificationWidget(userId: userId, formationId: formationId, ref: ref),
      ),
    );
  }
}

// Widget Stateful pour gérer la saisie et le chargement de la vérification
class _ThixIdVerificationWidget extends StatefulWidget {
  final String userId;
  final String formationId;
  final WidgetRef ref;

  const _ThixIdVerificationWidget({required this.userId, required this.formationId, required this.ref});

  @override
  State<_ThixIdVerificationWidget> createState() => _ThixIdVerificationWidgetState();
}

class _ThixIdVerificationWidgetState extends State<_ThixIdVerificationWidget> {
  final _thixIdController = TextEditingController();
  bool _isVerifying = false;
  String? _errorMessage;

  Future<void> _verifyAndEnroll() async {
    final thixIdInput = _thixIdController.text.trim();
    if (thixIdInput.isEmpty) {
      setState(() => _errorMessage = "Veuillez entrer votre numéro THIX ID.");
      return;
    }

    setState(() {
      _isVerifying = true;
      _errorMessage = null;
    });

    try {
      // 1. VÉRIFICATION DANS SUPABASE
      // ⚠️ IMPORTANT : Adaptez 'profiles' et 'thix_id_number' aux vrais noms de vos tables/colonnes
      final response = await Supabase.instance.client
          .from('profiles')
          .select('id')
          .eq('thix_id_number', thixIdInput) // Colonne contenant le numéro THIX ID
          .eq('id', widget.userId)           // S'assure que cet ID appartient bien à l'utilisateur connecté
          .maybeSingle();

      if (response == null) {
        // Le numéro n'existe pas ou n'appartient pas à cet utilisateur
        setState(() {
          _errorMessage = "Échec de l'authentification : Le numéro THIX ID est invalide ou ne correspond pas à votre compte.";
          _isVerifying = false;
        });
        return;
      }

      // 2. INSCRIPTION SI LE THIX ID EST VALIDE
      final ok = await widget.ref.read(enrollProvider.notifier).enroll(userId: widget.userId, formationId: widget.formationId);
      
      if (mounted) {
        context.pop(); // Ferme le BottomSheet
        if (ok) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Vérification réussie. Inscription validée !'), backgroundColor: Color(0xFF10B981)));
          // Force le rafraîchissement des données d'inscription
          widget.ref.invalidate(enrollmentProvider((userId: widget.userId, formationId: widget.formationId)));
        } else {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Erreur lors de l\'inscription à la formation.'), backgroundColor: Colors.redAccent));
        }
      }
    } catch (e) {
      setState(() {
        _errorMessage = "Erreur de connexion au réseau d'identité. Veuillez réessayer.";
        _isVerifying = false;
      });
    }
  }

  @override
  void dispose() {
    _thixIdController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(padding: const EdgeInsets.all(8), decoration: BoxDecoration(color: const Color(0xFF2D6CDF).withOpacity(0.1), shape: BoxShape.circle), child: const Icon(Icons.security_rounded, color: Color(0xFF2D6CDF))),
              const SizedBox(width: 12),
              const Text('Passerelle de sécurité', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: Color(0xFF1A1A2E))),
            ],
          ),
          const SizedBox(height: 16),
          const Text('Veuillez confirmer votre identité en saisissant votre numéro THIX ID avant de finaliser votre inscription.', style: TextStyle(color: Color(0xFF475569), fontSize: 14, height: 1.5)),
          const SizedBox(height: 24),
          TextField(
            controller: _thixIdController,
            decoration: InputDecoration(
              labelText: 'Numéro THIX ID',
              prefixIcon: const Icon(Icons.badge_rounded, color: Color(0xFF7386A8)),
              filled: true,
              fillColor: const Color(0xFFF8FAFC),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
              focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFF2D6CDF), width: 1.5)),
              errorText: _errorMessage,
            ),
            keyboardType: TextInputType.text,
            textInputAction: TextInputAction.done,
            onSubmitted: (_) => _verifyAndEnroll(),
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton(
              onPressed: _isVerifying ? null : _verifyAndEnroll,
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF1A1A2E), foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))),
              child: _isVerifying 
                  ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                  : const Text('Vérifier et S\'inscrire', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
            ),
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }
}
