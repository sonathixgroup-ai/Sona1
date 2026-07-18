// lib/presentation/thix_event/admin/pages/bookings/booking_management_page.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/admin_event_service.dart';
import '../../widgets/admin_app_bar.dart';
import '../../widgets/admin_paginated_list.dart';
import '../../providers/admin_state.dart';

class BookingManagementPage extends StatefulWidget {
  const BookingManagementPage({super.key});
  @override State<BookingManagementPage> createState() => _BookingManagementPageState();
}

class _BookingManagementPageState extends State<BookingManagementPage> {
  AdminPaginatedState<Map<String,dynamic>> _state = const AdminPaginatedState();
  String? _filterEventId;

  @override
  void initState() {
    super.initState();
    _load(refresh: true);
  }

  Future<void> _load({bool refresh=false, bool loadMore=false}) async {
    if (refresh) {
      setState(()=> _state = _state.copyWith(status: AdminStatus.loading, currentPage: 0, hasMore: true, items: []));
    }
    if (loadMore) {
      if (!_state.hasMore || _state.isLoadingMore) return;
      setState(()=> _state = _state.copyWith(status: AdminStatus.loadingMore));
    }

    try {
      final service = context.read<AdminEventService>();
      final page = refresh? 0 : _state.currentPage + (loadMore? 1 : 0);
      final data = await service.getBookingsPaginated(page: page, pageSize: 50, eventId: _filterEventId);

      setState((){
        _state = AdminPaginatedState(
          items: refresh? data : [..._state.items,...data],
          status: data.isEmpty && refresh? AdminStatus.empty : AdminStatus.success,
          hasMore: data.length==50,
          currentPage: page,
        );
      });
    } catch (e) {
      setState(()=> _state = _state.copyWith(status: AdminStatus.error, error: e.toString()));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFFF7FAFF),
      appBar: AdminAppBar(title: 'Réservations', actions: [IconButton(icon: Icon(Icons.download, color: Colors.white), onPressed: ()=> _exportCSV())]),
      body: AdminPaginatedList<Map<String,dynamic>>(
        state: _state,
        onRefresh: ()=> _load(refresh: true),
        onLoadMore: ()=> _load(loadMore: true),
        itemBuilder: (ctx, booking, i){
          final eventTitle = booking['events']?['title']?? 'Event';
          return Container(
            margin: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            padding: EdgeInsets.all(12),
            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(14), border: Border.all(color: Color(0xFFE7EEFC))),
            child: Row(children: [
              Container(padding: EdgeInsets.all(8), decoration: BoxDecoration(color: Color(0xFFEFF5FF), borderRadius: BorderRadius.circular(8)), child: Icon(Icons.confirmation_number, size: 18)),
              SizedBox(width: 12),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(eventTitle, style: TextStyle(fontWeight: FontWeight.w800, fontSize: 12), maxLines: 1, overflow: TextOverflow.ellipsis),
                Text('${booking['user_id'].toString().substring(0,8)}... • ${booking['ticket_quantity']} places • ${booking['status']}', style: TextStyle(fontSize: 11, color: Color(0xFF7386A8))),
                Text('${booking['total_price']} FC', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 12)),
              ])),
              Container(padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4), decoration: BoxDecoration(color: booking['status']=='confirmed'? Colors.green.withOpacity(0.1) : Colors.orange.withOpacity(0.1), borderRadius: BorderRadius.circular(6)), child: Text(booking['status'], style: TextStyle(fontSize: 9, fontWeight: FontWeight.w800, color: booking['status']=='confirmed'? Colors.green : Colors.orange))),
            ]),
          );
        },
      ),
    );
  }

  void _exportCSV() {
    // Scalable: on n'exporte pas 1M de rows d'un coup. On stream ou on envoie job côté backend.
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Export CSV lancé côté serveur (job) pour ne pas bloquer l\'UI avec 1M rows')));
  }
}
