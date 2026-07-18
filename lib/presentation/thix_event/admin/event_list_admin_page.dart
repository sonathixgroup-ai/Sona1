// lib/presentation/thix_event/admin/pages/events/event_list_admin_page.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../providers/admin_event_provider.dart';
import '../../widgets/admin_app_bar.dart';
import '../../widgets/admin_paginated_list.dart';
import '../../core/admin_guards.dart';

class EventListAdminPage extends StatefulWidget {
  const EventListAdminPage({super.key});
  @override State<EventListAdminPage> createState() => _EventListAdminPageState();
}

class _EventListAdminPageState extends State<EventListAdminPage> {
  final TextEditingController _searchCtrl = TextEditingController();
  String _selectedCategory = 'all';

  final List<String> _categories = ['all','concert','conférence','sport','festival','théâtre'];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AdminEventProvider>().loadEvents(refresh: true);
    });
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AdminEventProvider>();

    return Scaffold(
      backgroundColor: const Color(0xFFF7FAFF),
      appBar: AdminAppBar(
        title: 'Événements (${provider.eventsState.items.length})',
        actions: [
          IconButton(icon: const Icon(Icons.add, color: Colors.white), onPressed: ()=> context.push('/thix-event/admin/events/create')),
        ],
      ),
      body: Column(
        children: [
          // SEARCH BAR avec debounce déjà géré dans provider
          Padding(
            padding: const EdgeInsets.all(12),
            child: Row(children: [
              Expanded(child: TextField(
                controller: _searchCtrl,
                onChanged: (v)=> provider.searchEvents(v),
                decoration: InputDecoration(
                  hintText: 'Rechercher par titre...',
                  prefixIcon: const Icon(Icons.search, size: 18),
                  filled: true, fillColor: Colors.white,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide(color: Color(0xFFE7EEFC))),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                ),
              )),
              const SizedBox(width: 8),
              DropdownButton<String>(
                value: _selectedCategory,
                items: _categories.map((c)=> DropdownMenuItem(value: c, child: Text(c, style: TextStyle(fontSize: 12)))).toList(),
                onChanged: (v){ setState(()=> _selectedCategory = v!); provider.filterByCategory(v!); },
              )
            ]),
          ),
          Expanded(
            child: AdminPaginatedList(
              state: provider.eventsState,
              onRefresh: ()=> provider.loadEvents(refresh: true),
              onLoadMore: ()=> provider.loadMoreEvents(),
              itemBuilder: (ctx, event, index) => _EventAdminTile(event: event),
            ),
          ),
        ],
      ),
    );
  }
}

class _EventAdminTile extends StatelessWidget {
  final dynamic event;
  const _EventAdminTile({required this.event});

  @override
  Widget build(BuildContext context) {
    final provider = context.read<AdminEventProvider>();
    final dateStr = DateFormat('dd MMM yyyy • HH:mm').format(event.startDate);

    return Dismissible(
      key: Key(event.id),
      direction: DismissDirection.endToStart,
      confirmDismiss: (dir) async {
        final role = await AdminGuard.getCurrentRole();
        if (!AdminGuard.canDelete(role)) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Pas de permission delete')));
          return false;
        }
        return await showDialog<bool>(context: context, builder: (_) => AlertDialog(
          title: const Text('Supprimer ?'), content: Text('Supprimer ${event.title} ? Irréversible.'),
          actions: [TextButton(onPressed: ()=> Navigator.pop(context,false), child: const Text('Annuler')), ElevatedButton(onPressed: ()=> Navigator.pop(context,true), style: ElevatedButton.styleFrom(backgroundColor: Colors.red), child: const Text('Supprimer', style: TextStyle(color: Colors.white)))],
        ))?? false;
      },
      onDismissed: (_) => provider.deleteEvent(event.id),
      background: Container(alignment: Alignment.centerRight, padding: const EdgeInsets.only(right: 20), decoration: BoxDecoration(color: Colors.red, borderRadius: BorderRadius.circular(16)), child: const Icon(Icons.delete, color: Colors.white)),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), border: Border.all(color: const Color(0xFFE7EEFC))),
        child: Row(children: [
          ClipRRect(borderRadius: BorderRadius.circular(10), child: event.imageUrl!= null? Image.network(event.imageUrl!, width: 56, height: 56, fit: BoxFit.cover, errorBuilder: (_,__,___)=> _placeholder()) : _placeholder()),
          const SizedBox(width: 12),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              Expanded(child: Text(event.title, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13, color: Color(0xFF0A1F44)))),
              if (event.isFeatured) Container(padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2), decoration: BoxDecoration(color: const Color(0xFFE3B23C), borderRadius: BorderRadius.circular(6)), child: const Text('STAR', style: TextStyle(fontSize: 8, fontWeight: FontWeight.w900))),
            ]),
            const SizedBox(height: 2),
            Text('$dateStr • ${event.city?? event.location}', style: const TextStyle(fontSize: 11, color: Color(0xFF7386A8))),
            const SizedBox(height: 4),
            Row(children: [
              _badge('${event.price} ${event.priceCurrency}'),
              const SizedBox(width: 6),
              _badge('${event.remainingTickets?? 0}/${event.capacity?? 0} rest.'),
              const Spacer(),
              Switch.adaptive(value: event.isFeatured, onChanged: (v)=> provider.toggleFeatured(event.id, v), activeColor: const Color(0xFF2D6CDF)),
            ])
          ])),
          IconButton(icon: const Icon(Icons.edit, size: 18), onPressed: ()=> context.push('/thix-event/admin/events/create', extra: event)),
        ]),
      ),
    );
  }

  Widget _placeholder()=> Container(width: 56, height: 56, color: const Color(0xFFEFF5FF), child: const Icon(Icons.image, color: Color(0xFF7386A8)));
  Widget _badge(String t)=> Container(padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2), decoration: BoxDecoration(color: const Color(0xFFF7FAFF), borderRadius: BorderRadius.circular(6), border: Border.all(color: const Color(0xFFE7EEFC))), child: Text(t, style: const TextStyle(fontSize: 9, fontWeight: FontWeight.w700)));
}
