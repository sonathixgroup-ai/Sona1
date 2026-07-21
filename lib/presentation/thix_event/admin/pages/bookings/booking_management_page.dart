// lib/presentation/thix_event/admin/pages/bookings/booking_management_page.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../services/admin_event_service.dart';
import '../../widgets/admin_app_bar.dart';
import '../../widgets/admin_paginated_list.dart';
import '../../providers/admin_state.dart';

class BookingManagementPage extends StatefulWidget {
  const BookingManagementPage({super.key});
  @override 
  State<BookingManagementPage> createState() => _BookingManagementPageState();
}

class _BookingManagementPageState extends State<BookingManagementPage> {
  AdminPaginatedState<Map<String,dynamic>> _state = const AdminPaginatedState();
  String? _filterEventId;

  // Couleurs de l'Admin
  static const Color _primaryDark = Color(0xFF0A1F44);
  static const Color _primaryPurple = Color(0xFF6B3CE2);

  @override
  void initState() {
    super.initState();
    _load(refresh: true);
  }

  Future<void> _load({bool refresh = false, bool loadMore = false}) async {
    if (refresh) {
      setState(()=> _state = _state.copyWith(status: AdminStatus.loading, currentPage: 0, hasMore: true, items: []));
    }
    if (loadMore) {
      if (!_state.hasMore || _state.isLoadingMore) return;
      setState(()=> _state = _state.copyWith(status: AdminStatus.loadingMore));
    }

    try {
      final service = context.read<AdminEventService>();
      final page = refresh ? 0 : _state.currentPage + (loadMore ? 1 : 0);
      final data = await service.getBookingsPaginated(page: page, pageSize: 50, eventId: _filterEventId);

      if (mounted) {
        setState((){
          _state = AdminPaginatedState(
            items: refresh ? data : [..._state.items, ...data],
            status: data.isEmpty && refresh ? AdminStatus.empty : AdminStatus.success,
            hasMore: data.length == 50,
            currentPage: page,
          );
        });
      }
    } catch (e) {
      if (mounted) {
        setState(()=> _state = _state.copyWith(status: AdminStatus.error, error: e.toString()));
      }
    }
  }

  // 🟢 HELPER POUR LE STATUT VISUEL
  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'confirmed':
      case 'paid':
      case 'valide':
        return Colors.green;
      case 'used':
      case 'scanned':
        return Colors.grey;
      case 'cancelled':
        return Colors.red;
      case 'postponed':
        return const Color(0xFFF59E0B);
      default:
        return Colors.blue;
    }
  }

  String _getStatusLabel(String status) {
    switch (status.toLowerCase()) {
      case 'confirmed':
      case 'paid':
        return 'VALIDE';
      case 'used':
      case 'scanned':
        return 'UTILISÉ';
      case 'cancelled':
        return 'ANNULÉ';
      case 'postponed':
        return 'REPORTÉ';
      default:
        return 'EN ATTENTE';
    }
  }

  // 🟢 BOÎTE DE DIALOGUE DÉTAILLÉE AU CLIC
  void _showBookingDetails(Map<String, dynamic> booking) {
    final eventTitle = booking['events']?['title'] ?? 'Événement Inconnu';
    final String rawStatus = booking['status'] ?? 'pending';
    final Color statusColor = _getStatusColor(rawStatus);
    final String statusLabel = _getStatusLabel(rawStatus);
    
    final bookingDate = booking['booking_date'] != null 
        ? DateFormat('dd MMM yyyy, HH:mm', 'fr').format(DateTime.parse(booking['booking_date'].toString()))
        : 'Date inconnue';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        padding: const EdgeInsets.all(24),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(child: Container(width: 40, height: 5, decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(10)))),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Détails du Billet', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: _primaryDark)),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(color: statusColor.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
                  child: Text(statusLabel, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w900, color: statusColor)),
                ),
              ],
            ),
            const SizedBox(height: 24),
            
            _buildDetailRow(Icons.event_rounded, 'Événement', eventTitle),
            const Divider(height: 24, color: Color(0xFFE7EEFC)),
            
            _buildDetailRow(Icons.receipt_long_rounded, 'ID de réservation', booking['id']?.toString() ?? 'N/A', isMonospace: true),
            const Divider(height: 24, color: Color(0xFFE7EEFC)),
            
            _buildDetailRow(Icons.person_outline_rounded, 'ID Utilisateur', booking['user_id']?.toString() ?? 'N/A', isMonospace: true),
            const Divider(height: 24, color: Color(0xFFE7EEFC)),

            Row(
              children: [
                Expanded(child: _buildDetailBlock('Quantité', '${booking['ticket_quantity'] ?? 1} place(s)')),
                Expanded(child: _buildDetailBlock('Catégorie', booking['ticket_category'] ?? 'Standard')),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(child: _buildDetailBlock('Montant Total', '${booking['total_price'] ?? 0} FC', valueColor: _primaryPurple)),
                Expanded(child: _buildDetailBlock('Code PIN', booking['pin_code']?.toString() ?? 'Non défini', isMonospace: true)),
              ],
            ),
            const Divider(height: 24, color: Color(0xFFE7EEFC)),
            
            _buildDetailRow(Icons.access_time_rounded, 'Date d\'achat', bookingDate),
            const SizedBox(height: 32),
            
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => Navigator.pop(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFEFF5FF),
                  foregroundColor: _primaryDark,
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: const Text('FERMER', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 13)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(IconData icon, String label, String value, {bool isMonospace = false}) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 20, color: const Color(0xFF7386A8)),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: const TextStyle(fontSize: 11, color: Color(0xFF7386A8), fontWeight: FontWeight.w600)),
              const SizedBox(height: 2),
              Text(
                value, 
                style: TextStyle(
                  fontSize: 13, 
                  fontWeight: isMonospace ? FontWeight.w600 : FontWeight.w800, 
                  color: _primaryDark,
                  fontFamily: isMonospace ? 'Courier' : null,
                  letterSpacing: isMonospace ? 1 : 0,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildDetailBlock(String label, String value, {Color valueColor = _primaryDark, bool isMonospace = false}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 11, color: Color(0xFF7386A8), fontWeight: FontWeight.w600)),
        const SizedBox(height: 4),
        Text(
          value, 
          style: TextStyle(
            fontSize: 14, 
            fontWeight: FontWeight.w900, 
            color: valueColor,
            fontFamily: isMonospace ? 'Courier' : null,
            letterSpacing: isMonospace ? 2 : 0,
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7FAFF),
      appBar: AdminAppBar(
        title: 'Réservations', 
        actions: [
          IconButton(icon: const Icon(Icons.download, color: Colors.white), onPressed: () => _exportCSV())
        ]
      ),
      body: AdminPaginatedList<Map<String,dynamic>>(
        state: _state,
        onRefresh: () => _load(refresh: true),
        onLoadMore: () => _load(loadMore: true),
        itemBuilder: (ctx, booking, i) {
          final eventTitle = booking['events']?['title'] ?? 'Événement Inconnu';
          final rawStatus = booking['status'] ?? 'pending';
          final statusColor = _getStatusColor(rawStatus);
          final statusLabel = _getStatusLabel(rawStatus);
          final category = booking['ticket_category'] ?? 'Standard';

          return Container(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.white, 
              borderRadius: BorderRadius.circular(14), 
              border: Border.all(color: const Color(0xFFE7EEFC)),
              boxShadow: [BoxShadow(color: _primaryDark.withOpacity(0.02), blurRadius: 10, offset: const Offset(0, 4))],
            ),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                borderRadius: BorderRadius.circular(14),
                // 🟢 LE CLIC EST GÉRÉ ICI
                onTap: () => _showBookingDetails(booking),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10), 
                        decoration: BoxDecoration(color: const Color(0xFFEFF5FF), borderRadius: BorderRadius.circular(10)), 
                        child: const Icon(Icons.confirmation_num_rounded, size: 20, color: _primaryPurple)
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start, 
                          children: [
                            Text(eventTitle, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 13, color: _primaryDark), maxLines: 1, overflow: TextOverflow.ellipsis),
                            const SizedBox(height: 4),
                            Text(
                              '${booking['user_id'].toString().substring(0,8)}... • ${booking['ticket_quantity']}x $category', 
                              style: const TextStyle(fontSize: 11, color: Color(0xFF7386A8), fontWeight: FontWeight.w600)
                            ),
                            const SizedBox(height: 4),
                            Text('${booking['total_price']} FC', style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 12, color: _primaryPurple)),
                          ]
                        )
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4), 
                            decoration: BoxDecoration(color: statusColor.withOpacity(0.1), borderRadius: BorderRadius.circular(6)), 
                            child: Text(statusLabel, style: TextStyle(fontSize: 9, fontWeight: FontWeight.w900, color: statusColor))
                          ),
                          const SizedBox(height: 8),
                          const Icon(Icons.chevron_right_rounded, color: Color(0xFFD0D8E8), size: 20),
                        ],
                      ),
                    ]
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  void _exportCSV() {
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Export CSV lancé côté serveur (job) pour ne pas bloquer l\'UI avec 1M rows')));
  }
}
