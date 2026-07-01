// presentation/thix_sante/patient/details/patient_notifications_page.dart
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:thix_id/auth/auth_controller.dart';
import 'package:thix_id/presentation/thix_sante/shared/models/health_models.dart';
import 'package:thix_id/presentation/thix_sante/shared/services/health_services.dart';

class PatientNotificationsPage extends StatefulWidget {
  const PatientNotificationsPage({super.key});

  @override
  State<PatientNotificationsPage> createState() =>
      _PatientNotificationsPageState();
}

class _PatientNotificationsPageState
    extends State<PatientNotificationsPage> {
  final HealthService _healthService = HealthService.instance;
  List<NotificationItem> _notifications = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadNotifications();
  }

  Future<void> _loadNotifications() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final user = AuthController.instance.currentUser;
      if (user == null) {
        throw Exception('Utilisateur non connecté');
      }
      final patientId = user.id;

      // Récupérer les alertes sanitaires
      final alerts = await _healthService.fetchHealthAlerts(patientId);

      // Récupérer les rendez-vous à venir (pour les rappels)
      final appointments = await _healthService.fetchUpcomingAppointments(
        patientId,
      );

      // Récupérer les médicaments actifs (pour les rappels de prise)
      final medications = await _healthService.fetchMedications(
        patientId,
        activeOnly: true,
      );

      // Construire la liste des notifications
      final items = <NotificationItem>[];

      // 1. Alertes sanitaires
      items.addAll(
        alerts.map((alert) => NotificationItem.fromHealthAlert(alert)),
      );

      // 2. Rappels de rendez-vous (prochains rendez-vous dans les 48h)
      for (final appt in appointments) {
        final diff = appt.date.difference(DateTime.now());
        if (diff.inHours <= 48 && diff.inHours > 0) {
          items.add(NotificationItem(
            id: 'appt_${appt.id}',
            title: 'Rendez-vous avec ${appt.doctorName}',
            body:
                'Prévu le ${DateFormat('dd/MM/yyyy à HH:mm').format(appt.date)}',
            type: NotificationType.appointment,
            date: appt.date,
            isRead: false,
            action: '/sante/patient/appointment/${appt.id}',
          ));
        }
      }

      // 3. Rappels de médicaments (ceux avec rappels configurés)
      for (final med in medications) {
        if (med.reminders.isNotEmpty) {
          final now = DateTime.now();
          final currentTime = TimeOfDay.fromDateTime(now);
          for (final reminder in med.reminders) {
            if (!reminder.isEnabled) continue;
            // Calculer la prochaine date de rappel
            final nextDate = _nextReminderDate(now, reminder);
            if (nextDate != null && nextDate.difference(now).inHours <= 24) {
              items.add(NotificationItem(
                id: 'med_${med.id}_${reminder.id}',
                title: 'Rappel : ${med.name}',
                body: '${med.dosage} - ${reminder.timeString}',
                type: NotificationType.medication,
                date: nextDate,
                isRead: false,
                action: '/sante/patient/medication/${med.id}',
              ));
            }
          }
        }
      }

      // Trier par date (plus récent en premier)
      items.sort((a, b) => b.date.compareTo(a.date));

      setState(() {
        _notifications = items;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  DateTime? _nextReminderDate(DateTime now, MedicationReminder reminder) {
    final today = DateTime(now.year, now.month, now.day);
    final reminderTime = DateTime(
      today.year,
      today.month,
      today.day,
      reminder.time.hour,
      reminder.time.minute,
    );

    // Vérifier si le rappel doit être aujourd'hui
    if (reminder.shouldRemindToday() && reminderTime.isAfter(now)) {
      return reminderTime;
    }

    // Sinon, chercher le prochain jour de la semaine où le rappel est actif
    for (int i = 1; i <= 7; i++) {
      final nextDay = today.add(Duration(days: i));
      if (reminder.daysOfWeek.contains(nextDay.weekday % 7)) {
        return DateTime(
          nextDay.year,
          nextDay.month,
          nextDay.day,
          reminder.time.hour,
          reminder.time.minute,
        );
      }
    }
    return null;
  }

  Future<void> _markAsRead(NotificationItem item) async {
    setState(() {
      final index = _notifications.indexWhere((n) => n.id == item.id);
      if (index != -1) {
        _notifications[index] = item.copyWith(isRead: true);
      }
    });
  }

  Future<void> _deleteNotification(NotificationItem item) async {
    setState(() {
      _notifications.removeWhere((n) => n.id == item.id);
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Notification supprimée'),
        backgroundColor: Colors.orange,
      ),
    );
  }

  Future<void> _markAllAsRead() async {
    setState(() {
      _notifications = _notifications.map((n) => n.copyWith(isRead: true)).toList();
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Toutes les notifications marquées comme lues'),
        backgroundColor: Colors.green,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final unreadCount = _notifications.where((n) => !n.isRead).length;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Notifications'),
        backgroundColor: const Color(0xFF2563FF),
        foregroundColor: Colors.white,
        actions: [
          if (unreadCount > 0)
            IconButton(
              icon: const Icon(Icons.done_all),
              onPressed: _markAllAsRead,
              tooltip: 'Tout marquer comme lu',
            ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadNotifications,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.error_outline, size: 48, color: Colors.red),
                      const SizedBox(height: 8),
                      Text('Erreur : $_error'),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: _loadNotifications,
                        child: const Text('Réessayer'),
                      ),
                    ],
                  ),
                )
              : _notifications.isEmpty
                  ? const Center(
                      child: Padding(
                        padding: EdgeInsets.all(24),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.notifications_none,
                              size: 64,
                              color: Colors.grey,
                            ),
                            SizedBox(height: 16),
                            Text(
                              'Aucune notification',
                              style: TextStyle(
                                fontSize: 16,
                                color: Colors.grey,
                              ),
                            ),
                            SizedBox(height: 8),
                            Text(
                              'Vous serez informé des nouvelles alertes.',
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey,
                              ),
                            ),
                          ],
                        ),
                      ),
                    )
                  : Column(
                      children: [
                        // En-tête avec nombre de notifications
                        Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 8,
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                '${_notifications.length} notification(s)',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.grey[600],
                                ),
                              ),
                              if (unreadCount > 0)
                                Text(
                                  '$unreadCount non lue(s)',
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: Colors.blue[700],
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                            ],
                          ),
                        ),
                        Expanded(
                          child: RefreshIndicator(
                            onRefresh: _loadNotifications,
                            child: ListView.builder(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 8,
                              ),
                              itemCount: _notifications.length,
                              itemBuilder: (context, index) {
                                final notification = _notifications[index];
                                return _NotificationCard(
                                  notification: notification,
                                  onTap: () {
                                    _markAsRead(notification);
                                    if (notification.action != null) {
                                      context.push(notification.action!);
                                    }
                                  },
                                  onDismiss: _deleteNotification,
                                );
                              },
                            ),
                          ),
                        ),
                      ],
                    ),
    );
  }
}

// ============================================================
// Modèle de notification
// ============================================================
enum NotificationType { alert, appointment, medication, general }

class NotificationItem {
  final String id;
  final String title;
  final String body;
  final NotificationType type;
  final DateTime date;
  final bool isRead;
  final String? action;

  NotificationItem({
    required this.id,
    required this.title,
    required this.body,
    required this.type,
    required this.date,
    this.isRead = false,
    this.action,
  });

  factory NotificationItem.fromHealthAlert(HealthAlert alert) {
    return NotificationItem(
      id: alert.id,
      title: alert.title,
      body: alert.description,
      type: NotificationType.alert,
      date: alert.date,
      isRead: alert.isRead,
      action: alert.actionUrl,
    );
  }

  NotificationItem copyWith({
    String? id,
    String? title,
    String? body,
    NotificationType? type,
    DateTime? date,
    bool? isRead,
    String? action,
  }) {
    return NotificationItem(
      id: id ?? this.id,
      title: title ?? this.title,
      body: body ?? this.body,
      type: type ?? this.type,
      date: date ?? this.date,
      isRead: isRead ?? this.isRead,
      action: action ?? this.action,
    );
  }
}

// ============================================================
// Carte de notification
// ============================================================
class _NotificationCard extends StatelessWidget {
  final NotificationItem notification;
  final VoidCallback onTap;
  final Function(NotificationItem) onDismiss;

  const _NotificationCard({
    required this.notification,
    required this.onTap,
    required this.onDismiss,
  });

  @override
  Widget build(BuildContext context) {
    return Dismissible(
      key: Key(notification.id),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 16),
        decoration: BoxDecoration(
          color: Colors.red,
          borderRadius: BorderRadius.circular(16),
        ),
        child: const Icon(Icons.delete, color: Colors.white),
      ),
      onDismissed: (_) => onDismiss(notification),
      child: Card(
        margin: const EdgeInsets.only(bottom: 10),
        elevation: notification.isRead ? 0 : 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: notification.isRead
              ? BorderSide.none
              : const BorderSide(color: Color(0xFF2563FF), width: 1.5),
        ),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: _typeColor(notification.type).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    _typeIcon(notification.type),
                    color: _typeColor(notification.type),
                    size: 22,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        notification.title,
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: notification.isRead
                              ? FontWeight.w500
                              : FontWeight.w700,
                          color: notification.isRead
                              ? Colors.grey[700]
                              : Colors.black,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        notification.body,
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.grey[600],
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 6),
                      Text(
                        _formatDate(notification.date),
                        style: TextStyle(
                          fontSize: 11,
                          color: Colors.grey[500],
                        ),
                      ),
                    ],
                  ),
                ),
                if (!notification.isRead)
                  Container(
                    width: 10,
                    height: 10,
                    decoration: const BoxDecoration(
                      color: Color(0xFF2563FF),
                      shape: BoxShape.circle,
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Color _typeColor(NotificationType type) {
    switch (type) {
      case NotificationType.alert:
        return Colors.red;
      case NotificationType.appointment:
        return Colors.blue;
      case NotificationType.medication:
        return Colors.green;
      case NotificationType.general:
        return Colors.orange;
    }
  }

  IconData _typeIcon(NotificationType type) {
    switch (type) {
      case NotificationType.alert:
        return Icons.warning;
      case NotificationType.appointment:
        return Icons.calendar_today;
      case NotificationType.medication:
        return Icons.medication;
      case NotificationType.general:
        return Icons.info;
    }
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final diff = now.difference(date);

    if (diff.inMinutes < 1) return 'À l\'instant';
    if (diff.inMinutes < 60) return 'Il y a ${diff.inMinutes} min';
    if (diff.inHours < 24) return 'Il y a ${diff.inHours} h';
    if (diff.inDays == 1) return 'Hier';
    if (diff.inDays < 7) return 'Il y a ${diff.inDays} jours';
    return DateFormat('dd/MM/yyyy').format(date);
  }
}
