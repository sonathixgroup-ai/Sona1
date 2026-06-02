import 'package:flutter/material.dart';

class ThixSantePage extends StatelessWidget {
  const ThixSantePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FC),
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // ========== EN-TÊTE ==========
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.local_hospital, color: Colors.blue, size: 32),
                      const SizedBox(width: 8),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: const [
                          Text(
                            "THIX SANTÉ",
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF0F172A),
                            ),
                          ),
                          Text(
                            "Votre santé, notre priorité.",
                            style: TextStyle(fontSize: 11, color: Color(0xFF64748B)),
                          ),
                        ],
                      ),
                    ],
                  ),
                  Row(
                    children: [
                      _IconWithBadge(
                        icon: Icons.notifications_none,
                        hasBadge: true,
                        onTap: () {},
                      ),
                      const SizedBox(width: 12),
                      const CircleAvatar(
                        radius: 18,
                        backgroundImage: NetworkImage("https://i.pravatar.cc/150"),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // ========== BANNIÈRE HÉRO ==========
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF135EF2), Color(0xFF1FD6C1)],
                  ),
                  borderRadius: BorderRadius.circular(24),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      "Bonjour, Michel 🥰",
                      style: TextStyle(color: Colors.white, fontSize: 14),
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      "Votre santé\nentre de bonnes mains",
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        height: 1.2,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      "Consultez, suivez et prenez soin de votre santé au quotidien.",
                      style: TextStyle(color: Colors.white, fontSize: 12),
                    ),
                    const SizedBox(height: 20),
                    ElevatedButton.icon(
                      onPressed: () {},
                      icon: const Icon(Icons.folder, size: 16),
                      label: const Text("Dossier de santé"),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: Colors.black,
                        elevation: 0,
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // ========== MENU RAPIDE (6 icônes) ==========
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: const [
                  _QuickAction(icon: Icons.calendar_month, label: "Rendez-vous"),
                  _QuickAction(icon: Icons.medical_services, label: "Consultation"),
                  _QuickAction(icon: Icons.science, label: "Examens"),
                  _QuickAction(icon: Icons.medication, label: "Ordonnances"),
                  _QuickAction(icon: Icons.favorite, label: "Urgences"),
                  _QuickAction(icon: Icons.more_horiz, label: "Plus"),
                ],
              ),
              const SizedBox(height: 24),

              // ========== RÉSUMÉ DE SANTÉ ==========
              _SectionHeader(title: "Résumé de santé"),
              const SizedBox(height: 12),
              Row(
                children: const [
                  Expanded(child: _HealthStatCard(title: "Consultations", value: "12", subtitle: "Cette année", color: Color(0xFFEFF6FF))),
                  SizedBox(width: 10),
                  Expanded(child: _HealthStatCard(title: "Examens", value: "7", subtitle: "Complètes", color: Color(0xFFECFDF5))),
                  SizedBox(width: 10),
                  Expanded(child: _HealthStatCard(title: "Médicaments", value: "3", subtitle: "En cours", color: Color(0xFFF5F3FF))),
                  SizedBox(width: 10),
                  Expanded(child: _HealthStatCard(title: "RDV", value: "2", subtitle: "À venir", color: Color(0xFFFFF7ED))),
                ],
              ),
              const SizedBox(height: 28),

              // ========== SERVICES SANTÉ (grille 2 colonnes) ==========
              _SectionHeader(title: "Services santé"),
              const SizedBox(height: 12),
              GridView.count(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisCount: 2,
                childAspectRatio: 3.5,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                children: const [
                  _ServiceItem(
                    icon: Icons.child_care,
                    title: "Santé des enfants",
                    subtitle: "Suivez la santé de vos enfants",
                  ),
                  _ServiceItem(
                    icon: Icons.vaccines,
                    title: "Carnet de vaccination",
                    subtitle: "Consultez et gérez les vaccins",
                  ),
                  _ServiceItem(
                    icon: Icons.pregnant_woman,
                    title: "Suivi grossesses",
                    subtitle: "Suivez votre grossesse pas à pas",
                  ),
                  _ServiceItem(
                    icon: Icons.health_and_safety,
                    title: "Assurance santé",
                    subtitle: "Protégez votre santé",
                  ),
                  _ServiceItem(
                    icon: Icons.assured_workload,
                    title: "Assurance",
                    subtitle: "Découvrez nos solutions",
                  ),
                  _ServiceItem(
                    icon: Icons.more_horiz,
                    title: "Plus de services",
                    subtitle: "Découvrez tous nos services",
                  ),
                ],
              ),
              const SizedBox(height: 28),

              // ========== SERVICES RAPIDES (grille 2×4) ==========
              _SectionHeader(title: "Services rapides"),
              const SizedBox(height: 12),
              GridView.count(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisCount: 2,
                childAspectRatio: 3.2,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                children: const [
                  _QuickServiceTile(icon: Icons.person, title: "Consulter un médecin", subtitle: "Parlez à un professionnel"),
                  _QuickServiceTile(icon: Icons.folder_open, title: "Dossier médical", subtitle: "Accédez à votre dossier"),
                  _QuickServiceTile(icon: Icons.science, title: "Résultats d’examens", subtitle: "Consultez vos analyses"),
                  _QuickServiceTile(icon: Icons.medication, title: "Mes ordonnances", subtitle: "Gérez et renouvelez"),
                  _QuickServiceTile(icon: Icons.local_hospital, title: "Trouver un hôpital", subtitle: "Le plus proche"),
                  _QuickServiceTile(icon: Icons.local_pharmacy, title: "Trouver un médicament", subtitle: "Vérifiez la disponibilité"),
                  _QuickServiceTile(icon: Icons.storefront, title: "Pharmacies proches", subtitle: "Trouvez la pharmacie"),
                  _QuickServiceTile(icon: Icons.emergency, title: "Urgences proches", subtitle: "Services 24/7"),
                ],
              ),
              const SizedBox(height: 28),

              // ========== ASSURANCE SANTÉ (bannière) ==========
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 6)],
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: const Color(0xFFEFF6FF),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: const Icon(Icons.security, color: Color(0xFF2563EB), size: 28),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: const [
                          Text(
                            "Assurance santé",
                            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Color(0xFF0F172A)),
                          ),
                          SizedBox(height: 4),
                          Text(
                            "Bénéficiez d’une couverture complète adaptée à vos besoins.",
                            style: TextStyle(fontSize: 12, color: Color(0xFF64748B)),
                          ),
                        ],
                      ),
                    ),
                    const Icon(Icons.arrow_forward_ios_rounded, size: 14, color: Colors.grey),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // ========== ASSURANCE (ligne simple) ==========
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 6)],
                ),
                child: Row(
                  children: const [
                    Icon(Icons.verified_user, color: Color(0xFF10B981), size: 24),
                    SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        "Protégez-vous et vos proches avec nos solutions d'assurance.",
                        style: TextStyle(fontSize: 13, color: Color(0xFF0F172A)),
                      ),
                    ),
                    Icon(Icons.arrow_forward_ios_rounded, size: 14, color: Colors.grey),
                  ],
                ),
              ),
              const SizedBox(height: 28),

              // ========== POUR VOUS (articles horizontaux) ==========
              _SectionHeader(title: "Pour vous"),
              const SizedBox(height: 12),
              SizedBox(
                height: 240,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  children: const [
                    _HealthArticle(
                      title: "Conseil santé",
                      subtitle: "5 conseils pour rester en bonne santé",
                      readTime: "3 min de lecture",
                    ),
                    _HealthArticle(
                      title: "Nutrition",
                      subtitle: "Alimentation équilibrée : les bases",
                      readTime: "3 min de lecture",
                    ),
                    _HealthArticle(
                      title: "Bien-être",
                      subtitle: "Gérer le stress au quotidien",
                      readTime: "3 min de lecture",
                    ),
                    _HealthArticle(
                      title: "Prévention",
                      subtitle: "Prévention : un geste qui sauve",
                      readTime: "2 min de lecture",
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // ========== BANNIÈRE URGENCE ==========
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFF1F0),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: const Color(0xFFFEE2E2)),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: const Icon(Icons.local_hospital, color: Color(0xFFEF4444), size: 28),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: const [
                          Text(
                            "Besoin d’aide immédiate ?",
                            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Color(0xFF0F172A)),
                          ),
                          SizedBox(height: 4),
                          Text(
                            "Contactez les urgences en un clic",
                            style: TextStyle(fontSize: 12, color: Color(0xFF64748B)),
                          ),
                        ],
                      ),
                    ),
                    ElevatedButton.icon(
                      onPressed: () {},
                      icon: const Icon(Icons.call, size: 16),
                      label: const Text("Appeler 15"),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFEF4444),
                        foregroundColor: Colors.white,
                        elevation: 0,
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 80),
            ],
          ),
        ),
      ),
    );
  }
}

// ========== COMPOSANTS ==========

class _IconWithBadge extends StatelessWidget {
  final IconData icon;
  final bool hasBadge;
  final VoidCallback onTap;

  const _IconWithBadge({required this.icon, this.hasBadge = false, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Container(
          width: 36,
          height: 36,
          decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
          child: IconButton(
            padding: EdgeInsets.zero,
            onPressed: onTap,
            icon: Icon(icon, size: 20, color: const Color(0xFF1E293B)),
          ),
        ),
        if (hasBadge)
          Positioned(
            top: 6,
            right: 6,
            child: Container(
              width: 8,
              height: 8,
              decoration: const BoxDecoration(color: Colors.green, shape: BoxShape.circle),
            ),
          ),
      ],
    );
  }
}

class _QuickAction extends StatelessWidget {
  final IconData icon;
  final String label;

  const _QuickAction({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
            boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 4)],
          ),
          child: Icon(icon, color: const Color(0xFF2563EB), size: 22),
        ),
        const SizedBox(height: 6),
        Text(label, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w500, color: Color(0xFF475569))),
      ],
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;

  const _SectionHeader({required this.title});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          title,
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
        ),
        const Text(
          "Voir tout",
          style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.blue),
        ),
      ],
    );
  }
}

class _HealthStatCard extends StatelessWidget {
  final String title, value, subtitle;
  final Color color;

  const _HealthStatCard({required this.title, required this.value, required this.subtitle, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade100),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: color.computeLuminance() > 0.5 ? Colors.black : Colors.white)),
          const SizedBox(height: 6),
          Text(value, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Color(0xFF0F172A))),
          const SizedBox(height: 4),
          Text(subtitle, style: const TextStyle(fontSize: 8, color: Color(0xFF94A3B8))),
        ],
      ),
    );
  }
}

class _ServiceItem extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;

  const _ServiceItem({required this.icon, required this.title, required this.subtitle});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.01), blurRadius: 4)],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(color: Colors.blue.shade50, borderRadius: BorderRadius.circular(12)),
            child: Icon(icon, size: 18, color: Colors.blue),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF0F172A))),
                Text(subtitle, style: const TextStyle(fontSize: 10, color: Color(0xFF64748B)), maxLines: 1, overflow: TextOverflow.ellipsis),
              ],
            ),
          ),
          const Icon(Icons.arrow_forward_ios_rounded, size: 12, color: Colors.grey),
        ],
      ),
    );
  }
}

class _QuickServiceTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;

  const _QuickServiceTile({required this.icon, required this.title, required this.subtitle});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.01), blurRadius: 4)],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(color: Colors.grey.shade100, borderRadius: BorderRadius.circular(10)),
            child: Icon(icon, size: 16, color: const Color(0xFF2563EB)),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF0F172A))),
                Text(subtitle, style: const TextStyle(fontSize: 9, color: Color(0xFF64748B)), maxLines: 1, overflow: TextOverflow.ellipsis),
              ],
            ),
          ),
          const Icon(Icons.arrow_forward_ios_rounded, size: 10, color: Colors.grey),
        ],
      ),
    );
  }
}

class _HealthArticle extends StatelessWidget {
  final String title;
  final String subtitle;
  final String readTime;

  const _HealthArticle({required this.title, required this.subtitle, required this.readTime});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 180,
      margin: const EdgeInsets.only(right: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 6)],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            height: 100,
            decoration: BoxDecoration(
              color: Colors.grey.shade200,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(18)),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFF0F172A))),
                const SizedBox(height: 6),
                Text(subtitle, style: const TextStyle(fontSize: 12, color: Color(0xFF475569))),
                const SizedBox(height: 8),
                Row(
                  children: [
                    const Icon(Icons.access_time, size: 12, color: Colors.grey),
                    const SizedBox(width: 4),
                    Text(readTime, style: const TextStyle(fontSize: 10, color: Colors.grey)),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
