// lib/presentation/thix_weeding/pages/staff/invités/guest_list_page.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

// CENTRAUX
import '../../../staff/models/thix_weeding_models.dart';
import '../../../staff/providers/thix_weeding_providers.dart';

class GuestListPage extends ConsumerStatefulWidget {
  final String weddingId;
  const GuestListPage({super.key, required this.weddingId});
  @override
  ConsumerState<GuestListPage> createState() => _GuestListPageState();
}

class _GuestListPageState extends ConsumerState<GuestListPage> {
  String _search = '';
  String _filter = 'all';

  @override
  Widget build(BuildContext context) {
    final guestsAsync = ref.watch(guestsProvider(widget.weddingId));

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: Colors.white,
        title: guestsAsync.when(
          data: (list) => Text('Invités - ${list.length}'),
          loading: () => const Text('Invités'),
          error: (_, __) => const Text('Invités'),
        ),
        actions: [
          IconButton(icon: const Icon(Icons.bar_chart), onPressed: () => context.push('/thix-weeding/staff/${widget.weddingId}/rsvp')),
          IconButton(icon: const Icon(Icons.person_add), onPressed: () => context.push('/thix-weeding/staff/${widget.weddingId}/invites/add')),
        ],
      ),
      body: Column(
        children: [
          _SearchField(onChanged: (v) => setState(() => _search = v)),
          _FilterRow(filter: _filter, onChanged: (v) => setState(() => _filter = v)),
          Expanded(
            child: guestsAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, s) => Center(child: Text('Erreur $e')),
              data: (List<GuestModel> guests) {
                var filtered = guests.where((g) {
                  final matchSearch = g.name.toLowerCase().contains(_search.toLowerCase());
                  final matchFilter = _filter == 'all' || g.rsvpStatus == _filter;
                  return matchSearch && matchFilter;
                }).toList();

                if (filtered.isEmpty) return const Center(child: Text('Aucun invité'));

                return RefreshIndicator(
                  onRefresh: () async => ref.invalidate(guestsProvider(widget.weddingId)),
                  child: ListView.separated(
                    padding: const EdgeInsets.all(12),
                    itemCount: filtered.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 8),
                    itemBuilder: (_, i) {
                      final GuestModel g = filtered[i];
                      return _GuestTile(guest: g, onTap: () => context.push('/thix-weeding/staff/${widget.weddingId}/invites/${g.id}'));
                    },
                  ),
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(onPressed: () => context.push('/thix-weeding/staff/${widget.weddingId}/invites/add'), icon: const Icon(Icons.add), label: const Text('Ajouter')),
    );
  }
}

// ================= WIDGETS INTERNES =================

class _SearchField extends StatelessWidget {
  final Function(String) onChanged;
  const _SearchField({required this.onChanged});
  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.all(12),
        child: TextField(
          onChanged: onChanged,
          decoration: InputDecoration(prefixIcon: const Icon(Icons.search), hintText: 'Rechercher invité...', filled: true, fillColor: Colors.white, border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none)),
        ),
      );
}

class _FilterRow extends StatelessWidget {
  final String filter; final Function(String) onChanged;
  const _FilterRow({required this.filter, required this.onChanged});
  @override
  Widget build(BuildContext context) => SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        child: Row(children: [
          _FilterChip(label: 'Tous', selected: filter == 'all', onTap: () => onChanged('all')),
          _FilterChip(label: 'En attente', selected: filter == 'pending', onTap: () => onChanged('pending')),
          _FilterChip(label: 'Confirmés', selected: filter == 'yes' || filter == 'accepted', onTap: () => onChanged('yes')),
          _FilterChip(label: 'Refusés', selected: filter == 'no' || filter == 'declined', onTap: () => onChanged('no')),
        ]),
      );
}

class _GuestTile extends StatelessWidget {
  final GuestModel guest; final VoidCallback onTap;
  const _GuestTile({required this.guest, required this.onTap});
  @override
  Widget build(BuildContext context) => Container(
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)),
        child: ListTile(
          leading: CircleAvatar(backgroundColor: const Color(0xFF0B3B8F).withOpacity(0.1), child: Text(guest.name[0].toUpperCase(), style: const TextStyle(color: Color(0xFF0B3B8F), fontWeight: FontWeight.bold))),
          title: Text(guest.name, style: const TextStyle(fontWeight: FontWeight.bold)),
          subtitle: Text('${guest.groupName} • ${guest.guestsCount} pers • ID: ${guest.id.substring(0, 6)}'),
          trailing: _StatusBadge(status: guest.rsvpStatus),
          onTap: onTap,
        ),
      );
}

class _FilterChip extends StatelessWidget {
  final String label; final bool selected; final VoidCallback onTap;
  const _FilterChip({required this.label, required this.selected, required this.onTap});
  @override
  Widget build(BuildContext context) => Padding(padding: const EdgeInsets.only(right: 8), child: ChoiceChip(label: Text(label), selected: selected, selectedColor: const Color(0xFF0B3B8F).withOpacity(0.15), onSelected: (_) => onTap()));
}

class _StatusBadge extends StatelessWidget {
  final String status;
  const _StatusBadge({required this.status});
  @override
  Widget build(BuildContext context) {
    Color c;
    String t;
    switch (status) {
      case 'yes': case 'accepted': c = Colors.green; t = 'Oui'; break;
      case 'no': case 'declined': c = Colors.red; t = 'Non'; break;
      case 'maybe': c = Colors.orange; t = 'Peut-être'; break;
      default: c = Colors.grey; t = 'En attente';
    }
    return Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4), decoration: BoxDecoration(color: c.withOpacity(0.15), borderRadius: BorderRadius.circular(20)), child: Text(t, style: TextStyle(color: c, fontSize: 10, fontWeight: FontWeight.bold)));
  }
}
