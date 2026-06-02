// ============================================================================
// FICHIER : lib/presentation/events/event_register_page.dart
// ============================================================================

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../models/event_item.dart';
import '../../services/event_service.dart';

class EventRegisterPage extends StatefulWidget {
  final EventItem event;

  const EventRegisterPage({
    super.key,
    required this.event,
  });

  @override
  State<EventRegisterPage> createState() => _EventRegisterPageState();
}

class _EventRegisterPageState extends State<EventRegisterPage> {
  final _formKey = GlobalKey<FormState>();
  final _thixIdController = TextEditingController();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _noteController = TextEditingController();

  bool _loading = false;
  int _tickets = 1;

  late EventService _eventService;

  @override
  void initState() {
    super.initState();
    _eventService = EventService(Supabase.instance.client);
  }

  @override
  void dispose() {
    _thixIdController.dispose();
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  double get _totalPrice {
    final price = widget.event.price ?? 0;
    return price * _tickets;
  }

  Future<void> _register() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final user = Supabase.instance.client.auth.currentUser;

    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Veuillez vous connecter'),
        ),
      );
      return;
    }

    setState(() {
      _loading = true;
    });

    try {
      final success = await _eventService.registerForEvent(
        userId: user.id,
        eventId: widget.event.id,
      );

      if (!success) {
        throw Exception('Vous êtes déjà inscrit ou une erreur est survenue.');
      }

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Réservation effectuée avec succès'),
          backgroundColor: Colors.green,
        ),
      );

      // Redirection vers le dashboard des billets
      context.go(AppRoutes.userEventsDashboard);
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.toString()),
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

  @override
  Widget build(BuildContext context) {
    final event = widget.event;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Réservation'),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Informations de l'événement
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.blue.shade50,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        event.title,
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(event.location),
                      const SizedBox(height: 4),
                      Text(
                        event.priceLabel,
                        style: const TextStyle(
                          color: Colors.blue,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 24),

                // THIX ID
                const Text(
                  'THIX ID *',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _thixIdController,
                  decoration: const InputDecoration(
                    border: OutlineInputBorder(),
                    hintText: 'Votre THIX ID',
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Champ obligatoire';
                    }
                    return null;
                  },
                ),

                const SizedBox(height: 16),

                // Nom complet
                const Text(
                  'Nom complet *',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _nameController,
                  decoration: const InputDecoration(
                    border: OutlineInputBorder(),
                    hintText: 'Votre nom complet',
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Champ obligatoire';
                    }
                    return null;
                  },
                ),

                const SizedBox(height: 16),

                // Email
                const Text('Email'),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  decoration: const InputDecoration(
                    border: OutlineInputBorder(),
                    hintText: 'votre@email.com',
                  ),
                ),

                const SizedBox(height: 16),

                // Téléphone
                const Text('Téléphone'),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _phoneController,
                  keyboardType: TextInputType.phone,
                  decoration: const InputDecoration(
                    border: OutlineInputBorder(),
                    hintText: '+243 XX XXX XXXX',
                  ),
                ),

                const SizedBox(height: 24),

                // Nombre de billets
                const Text(
                  'Nombre de billets',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    IconButton(
                      onPressed: () {
                        if (_tickets > 1) {
                          setState(() {
                            _tickets--;
                          });
                        }
                      },
                      icon: const Icon(Icons.remove_circle),
                    ),
                    Text(
                      _tickets.toString(),
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    IconButton(
                      onPressed: () {
                        setState(() {
                          _tickets++;
                        });
                      },
                      icon: const Icon(Icons.add_circle),
                    ),
                  ],
                ),

                const SizedBox(height: 24),

                // Note
                TextFormField(
                  controller: _noteController,
                  maxLines: 3,
                  decoration: const InputDecoration(
                    border: OutlineInputBorder(),
                    labelText: 'Note (optionnelle)',
                    hintText: 'Allergies, besoins spécifiques...',
                  ),
                ),

                const SizedBox(height: 24),

                // Montant total
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey.shade300),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Montant total',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      Text(
                        '${_totalPrice.toStringAsFixed(2)} USD',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.blue,
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 32),

                // Bouton de réservation
                SizedBox(
                  width: double.infinity,
                  height: 55,
                  child: ElevatedButton(
                    onPressed: _loading ? null : _register,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                      foregroundColor: Colors.white,
                    ),
                    child: _loading
                        ? const CircularProgressIndicator()
                        : const Text(
                            'Confirmer la réservation',
                            style: TextStyle(fontSize: 16),
                          ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
