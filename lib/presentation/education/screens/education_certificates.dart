// lib/presentation/education/screens/education_certificates.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:thix_id/presentation/education/providers/certificate_provider.dart';
import 'package:thix_id/presentation/education/models/certificate.dart';
import 'package:thix_id/presentation/education/widgets/common/education_empty_state.dart';
import 'package:thix_id/presentation/education/widgets/common/education_loading_shimmer.dart';

class EducationCertificates extends StatefulWidget {
  const EducationCertificates({super.key});

  @override
  State<EducationCertificates> createState() => _EducationCertificatesState();
}

class _EducationCertificatesState extends State<EducationCertificates> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadCertificates();
    });
  }

  Future<void> _loadCertificates() async {
    final userId = Supabase.instance.client.auth.currentUser?.id;
    if (userId == null) return;
    final provider = context.read<CertificateProvider>();
    await provider.loadCertificates(userId);
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<CertificateProvider>();
    final certificates = provider.certificates;

    return Scaffold(
      backgroundColor: const Color(0xFFF7FAFF),
      appBar: AppBar(
        title: const Text(
          'Mes Certificats',
          style: TextStyle(fontWeight: FontWeight.w800, color: Color(0xFF1A1A2E)),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: Color(0xFF1A1A2E)),
          onPressed: () => context.pop(),
        ),
      ),
      body: provider.isLoading
          ? const EducationLoadingShimmer()
          : certificates.isEmpty
              ? EducationEmptyState(
                  title: 'Aucun certificat',
                  subtitle: 'Terminez une formation certifiante pour obtenir votre certificat',
                  icon: Icons.workspace_premium_rounded,
                  buttonText: 'Voir les formations',
                  onButtonPressed: () => context.push('/education'),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: certificates.length,
                  itemBuilder: (context, index) {
                    final cert = certificates[index];
                    return _CertificateCard(certificate: cert);
                  },
                ),
    );
  }
}

class _CertificateCard extends StatelessWidget {
  final Certificate certificate;

  const _CertificateCard({required this.certificate});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => context.push(
        '/education/certificate/${certificate.id}',
        extra: certificate,
      ),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFE7EEFC)),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF0A1F44).withOpacity(0.04),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF2D6CDF), Color(0xFF123B7A)],
                ),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.verified_rounded, color: Colors.white, size: 28),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Certificat',
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF1A1A2E),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Délivré le ${_formatDate(certificate.issuedAt)}',
                    style: const TextStyle(fontSize: 12, color: Color(0xFF7386A8)),
                  ),
                  Text(
                    'ID: ${certificate.verificationHash.substring(0, 8)}...',
                    style: const TextStyle(fontSize: 11, color: Color(0xFF7386A8)),
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right_rounded, color: Color(0xFF7386A8)),
          ],
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    final months = ['jan', 'fév', 'mar', 'avr', 'mai', 'juin', 'juil', 'août', 'sep', 'oct', 'nov', 'déc'];
    return '${date.day} ${months[date.month - 1]} ${date.year}';
  }
}
