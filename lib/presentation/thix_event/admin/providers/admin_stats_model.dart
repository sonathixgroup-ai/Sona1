// lib/presentation/thix_event/admin/providers/admin_stats_model.dart
class AdminStats {
  final int totalEvents;
  final int totalBookings;
  final int totalSeatsSold;
  final int waitingQueue;
  final double totalRevenue;
  final int todayBookings;

  const AdminStats({
    this.totalEvents = 0,
    this.totalBookings = 0,
    this.totalSeatsSold = 0,
    this.waitingQueue = 0,
    this.totalRevenue = 0,
    this.todayBookings = 0,
  });

  factory AdminStats.fromJson(Map<String, dynamic> json) {
    return AdminStats(
      totalEvents: json['total_events'] ?? 0,
      totalBookings: json['total_bookings'] ?? 0,
      totalSeatsSold: json['total_seats_sold'] ?? 0,
      waitingQueue: json['waiting_queue'] ?? 0,
      totalRevenue: (json['total_revenue'] ?? 0).toDouble(),
      todayBookings: json['today_bookings'] ?? 0,
    );
  }

  static AdminStats empty() => const AdminStats();
}
