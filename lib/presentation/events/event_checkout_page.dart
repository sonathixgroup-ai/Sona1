import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../models/event_item.dart';
import '../../services/event_service.dart';

class EventCheckoutPage extends StatefulWidget {
  final EventItem event;
  final int tickets;
  final String attendeeThixId;
  final String attendeeName;
  final String? attendeeEmail;
  final String? attendeePhone;
  final String? note;

  const EventCheckoutPage({
    super.key,
    required this.event,
    required this.tickets,
    required this.attendeeThixId,
    required this.attendeeName,
    this.attendeeEmail,
    this.attendeePhone,
    this.note,
  });

  @override
  State<EventCheckoutPage> createState() =>
      _EventCheckoutPageState();
}

class _EventCheckoutPageState
    extends State<EventCheckoutPage> {
  late EventService _eventService;

  final _promoController =
      TextEditingController();

  bool _loading = false;

  double? _discountPercent;

  @override
  void initState() {
    super.initState();

    _eventService = EventService(
      Supabase.instance.client,
    );
  }

  @override
  void dispose() {
    _promoController.dispose();
    super.dispose();
  }

  double get subtotal {
    return widget.event.price *
        widget.tickets;
  }

  double get discountAmount {
    if (_discountPercent == null) {
      return 0;
    }

    return subtotal *
        (_discountPercent! / 100);
  }

  double get total {
    return subtotal - discountAmount;
  }

  Future<void> _applyPromoCode() async {
    final code =
        _promoController.text.trim();

    if (code.isEmpty) return;

    final discount =
        await _eventService
            .validatePromoCode(
      code,
      widget.event.id,
    );

    if (!mounted) return;

    if (discount == null) {
      ScaffoldMessenger.of(context)
          .showSnackBar(
        const SnackBar(
          content: Text(
            'Code promo invalide',
          ),
        ),
      );
      return;
    }

    setState(() {
      _discountPercent = discount;
    });

    ScaffoldMessenger.of(context)
        .showSnackBar(
      SnackBar(
        content: Text(
          'Réduction $discount%',
        ),
      ),
    );
  }

  Future<void> _completeCheckout() async {
    final user =
        Supabase.instance.client.auth.currentUser;

    if (user == null) {
      ScaffoldMessenger.of(context)
          .showSnackBar(
        const SnackBar(
          content: Text(
            'Veuillez vous connecter',
          ),
        ),
      );
      return;
    }

    setState(() {
      _loading = true;
    });

    try {
      final ticketCode =
          await _eventService
              .createRegistration(
        {
          'event_id': widget.event.id,
          'attendee_thix_id':
              widget.attendeeThixId,
          'attendee_name':
              widget.attendeeName,
          'attendee_email':
              widget.attendeeEmail,
          'attendee_phone':
              widget.attendeePhone,
          'tickets': widget.tickets,
          'amount_paid': total,
          'note': widget.note,
          'ticket_code':
              'THIX-${DateTime.now().millisecondsSinceEpoch}',
        },
        userId: user.id,
      );

      if (!mounted) return;

      ScaffoldMessenger.of(context)
          .showSnackBar(
        const SnackBar(
          content: Text(
            'Paiement validé',
          ),
        ),
      );

      context.go('/events');
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context)
          .showSnackBar(
        SnackBar(
          content: Text(
            e.toString(),
          ),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _loading = false;
        });
      }
    }
  }

  Widget _buildPriceRow(
    String label,
    String value, {
    bool bold = false,
  }) {
    return Padding(
      padding:
          const EdgeInsets.symmetric(
        vertical: 6,
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                fontWeight: bold
                    ? FontWeight.bold
                    : FontWeight.normal,
              ),
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontWeight: bold
                  ? FontWeight.bold
                  : FontWeight.normal,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final event = widget.event;

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Paiement',
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding:
              const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment:
                CrossAxisAlignment.start,
            children: [
              Card(
                child: Padding(
                  padding:
                      const EdgeInsets.all(
                          16),
                  child: Column(
                    crossAxisAlignment:
                        CrossAxisAlignment
                            .start,
                    children: [
                      Text(
                        event.title,
                        style:
                            const TextStyle(
                          fontSize: 18,
                          fontWeight:
                              FontWeight.bold,
                        ),
                      ),
                      const SizedBox(
                          height: 8),
                      Text(
                        event.location,
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(
                  height: 20),

              TextField(
                controller:
                    _promoController,
                decoration:
                    InputDecoration(
                  labelText:
                      'Code promo',
                  border:
                      const OutlineInputBorder(),
                  suffixIcon:
                      TextButton(
                    onPressed:
                        _applyPromoCode,
                    child: const Text(
                      'Appliquer',
                    ),
                  ),
                ),
              ),

              const SizedBox(
                  height: 24),

              const Text(
                'Résumé',
                style: TextStyle(
                  fontWeight:
                      FontWeight.bold,
                  fontSize: 18,
                ),
              ),

              const SizedBox(
                  height: 12),

              Card(
                child: Padding(
                  padding:
                      const EdgeInsets.all(
                          16),
                  child: Column(
                    children: [
                      _buildPriceRow(
                        'Billets',
                        widget.tickets
                            .toString(),
                      ),
                      _buildPriceRow(
                        'Sous-total',
                        '\$${subtotal.toStringAsFixed(2)}',
                      ),
                      _buildPriceRow(
                        'Réduction',
                        '-\$${discountAmount.toStringAsFixed(2)}',
                      ),
                      const Divider(),
                      _buildPriceRow(
                        'Total',
                        '\$${total.toStringAsFixed(2)}',
                        bold: true,
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(
                  height: 30),

              Container(
                padding:
                    const EdgeInsets.all(
                        16),
                decoration:
                    BoxDecoration(
                  color:
                      Colors.blue.shade50,
                  borderRadius:
                      BorderRadius
                          .circular(12),
                ),
                child: const Column(
                  crossAxisAlignment:
                      CrossAxisAlignment
                          .start,
                  children: [
                    Text(
                      'Paiement THIX',
                      style: TextStyle(
                        fontWeight:
                            FontWeight
                                .bold,
                      ),
                    ),
                    SizedBox(height: 8),
                    Text(
                      'Intégrez ici Stripe, Orange Money, Airtel Money, M-Pesa ou PayPal.',
                    ),
                  ],
                ),
              ),

              const SizedBox(
                  height: 30),

              SizedBox(
                width:
                    double.infinity,
                height: 55,
                child:
                    ElevatedButton.icon(
                  onPressed:
                      _loading
                          ? null
                          : _completeCheckout,
                  icon: _loading
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child:
                              CircularProgressIndicator(
                            strokeWidth:
                                2,
                          ),
                        )
                      : const Icon(
                          Icons.payment,
                        ),
                  label: const Text(
                    'Confirmer et payer',
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
