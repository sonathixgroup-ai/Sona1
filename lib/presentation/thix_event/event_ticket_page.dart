// lib/presentation/thix_event/event_ticket_page.dart
import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/intl.dart';

class _ThixColors {
  static const Color primary = Color(0xFF6B3CE2);
  static const Color darkText = Color(0xFF1E1B4B);
  static const Color mutedText = Color(0xFF8B8BA7);
}

class EventTicketPage extends StatefulWidget {
  final String bookingId;

  const EventTicketPage({super.key, required this.bookingId});

  @override
  State<EventTicketPage> createState() => _EventTicketPageState();
}

class _EventTicketPageState extends State<EventTicketPage> {
  bool _isLoading = true;
  Map<String, dynamic>? _bookingData;
  Map<String, dynamic>? _eventData;

  @override
  void initState() {
    super.initState();
    _fetchTicketData();
  }

  Future<void> _fetchTicketData() async {
    try {
      final supabase = Supabase.instance.client;
      // Récupère la réservation ET les infos de l'événement lié
      final response = await supabase
          .from('event_bookings')
          .select('*, events(*)')
          .eq('id', widget.bookingId)
          .single();

      setState(() {
        _bookingData = response;
        _eventData = response['events'];
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('Erreur chargement ticket: $e');
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(backgroundColor: _ThixColors.primary, body: Center(child: CircularProgressIndicator(color: Colors.white)));
    }

    if (_bookingData == null || _eventData == null) {
      return Scaffold(
        appBar: AppBar(backgroundColor: Colors.transparent, elevation: 0),
        body: const Center(child: Text("Billet introuvable")),
      );
    }

    final eventTitle = _eventData!['title'] ?? 'Événement';
    final eventDate = _eventData!['date'] != null 
        ? DateFormat('dd MMMM yyyy, HH:mm', 'fr').format(DateTime.parse(_eventData!['date'])) 
        : 'Date inconnue';
    final location = _eventData!['location'] ?? 'Lieu inconnu';
    final imageUrl = _eventData!['image_url'];
    final quantity = _bookingData!['ticket_quantity'] ?? 1;
    // Le QR Code contiendra cet ID unique pour le scan à la porte
    final qrData = _bookingData!['id'].toString(); 

    return Scaffold(
      backgroundColor: _ThixColors.primary,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close_rounded, color: Colors.white),
          onPressed: () => context.go('/thix-event'), // Retour à l'accueil
        ),
        title: const Text('Votre Billet', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800)),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        child: Column(
          children: [
            // 🎟️ LE BILLET
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(24),
                boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.2), blurRadius: 20, offset: const Offset(0, 10))],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // HAUT : Flyer de l'événement
                  if (imageUrl != null)
                    ClipRRect(
                      borderRadius: const BorderRadius.only(topLeft: Radius.circular(24), topRight: Radius.circular(24)),
                      child: Image.network(imageUrl, height: 160, width: double.infinity, fit: BoxFit.cover),
                    )
                  else
                    Container(
                      height: 120,
                      decoration: const BoxDecoration(
                        color: Color(0xFF3B1D82),
                        borderRadius: BorderRadius.only(topLeft: Radius.circular(24), topRight: Radius.circular(24)),
                      ),
                      child: const Center(child: Icon(Icons.event, size: 50, color: Colors.white54)),
                    ),
                  
                  // MILIEU : Informations du ticket
                  Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(eventTitle, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: _ThixColors.darkText)),
                        const SizedBox(height: 16),
                        _buildInfoRow(Icons.calendar_today_rounded, 'Date & Heure', eventDate),
                        const SizedBox(height: 12),
                        _buildInfoRow(Icons.location_on_rounded, 'Lieu', location),
                        const SizedBox(height: 20),
                        Row(
                          children: [
                            Expanded(child: _buildTicketDetail('Billet(s)', '$quantity')),
                            Expanded(child: _buildTicketDetail('Type', 'Standard')), // À lier avec vos data
                            Expanded(child: _buildTicketDetail('Statut', 'PAYÉ', color: Colors.green)),
                          ],
                        ),
                      ],
                    ),
                  ),

                  // LIGNE DE DÉCOUPE (Effet visuel ticket)
                  Stack(
                    children: [
                      const Divider(color: Colors.grey, height: 1, thickness: 1, indent: 20, endIndent: 20), // Pointillés idéaux ici
                      Positioned(left: -10, top: -10, child: Container(height: 20, width: 20, decoration: const BoxDecoration(color: _ThixColors.primary, shape: BoxShape.circle))),
                      Positioned(right: -10, top: -10, child: Container(height: 20, width: 20, decoration: const BoxDecoration(color: _ThixColors.primary, shape: BoxShape.circle))),
                    ],
                  ),

                  // BAS : QR CODE PROPRE
                  Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: const Color(0xFFEEE9FF), width: 2),
                          ),
                          child: QrImageView(
                            data: qrData,
                            version: QrVersions.auto,
                            size: 160.0,
                            foregroundColor: _ThixColors.darkText,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Text('Ticket ID: ${qrData.split('-').first.toUpperCase()}', style: const TextStyle(fontSize: 12, color: _ThixColors.mutedText, fontWeight: FontWeight.bold, letterSpacing: 2)),
                        const SizedBox(height: 4),
                        const Text('Présentez ce QR code à l\'entrée', style: TextStyle(fontSize: 11, color: _ThixColors.mutedText)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),
            
            // Boutons d'action
            OutlinedButton.icon(
              onPressed: () {}, // Logique pour sauvegarder l'image/PDF
              icon: const Icon(Icons.download_rounded),
              label: const Text('Télécharger le billet'),
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.white,
                side: const BorderSide(color: Colors.white, width: 1.5),
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 18, color: _ThixColors.mutedText),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: const TextStyle(fontSize: 11, color: _ThixColors.mutedText, fontWeight: FontWeight.w600)),
              const SizedBox(height: 2),
              Text(value, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: _ThixColors.darkText)),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildTicketDetail(String label, String value, {Color color = _ThixColors.darkText}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 10, color: _ThixColors.mutedText, fontWeight: FontWeight.w600)),
        const SizedBox(height: 4),
        Text(value, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w900, color: color)),
      ],
    );
  }
}
