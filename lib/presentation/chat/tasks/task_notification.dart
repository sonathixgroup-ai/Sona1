// lib/presentation/chat/tasks/task_notification.dart
// Notifications pour les rappels de tâche (local push ou snackbar)

import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class TaskNotification {
  static final FlutterLocalNotificationsPlugin _notifications = FlutterLocalNotificationsPlugin();

  static Future<void> init() async {
    const AndroidInitializationSettings android = AndroidInitializationSettings('@mipmap/ic_launcher');
    const DarwinInitializationSettings ios = DarwinInitializationSettings();
    const InitializationSettings settings = InitializationSettings(android: android, iOS: ios);
    await _notifications.initialize(settings);
  }

  static Future<void> showTaskDueNotification(String taskTitle, DateTime dueDate) async {
    const AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
      'task_channel',
      'Rappels de tâches',
      importance: Importance.high,
      priority: Priority.high,
    );
    const NotificationDetails details = NotificationDetails(android: androidDetails);
    await _notifications.show(
      dueDate.millisecondsSinceEpoch % 100000,
      'Tâche à faire : $taskTitle',
      'Échéance prévue ${_formatDate(dueDate)}',
      details,
    );
  }

  static void showInAppNotification(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.task_alt, color: Colors.white),
            const SizedBox(width: 8),
            Expanded(child: Text(message)),
          ],
        ),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  static String _formatDate(DateTime dt) => '${dt.day}/${dt.month}/${dt.year} à ${dt.hour}:${dt.minute}';

  // Planifier une notification locale pour l'échéance
  static Future<void> scheduleTaskReminder(String taskId, String title, DateTime dueDate) async {
    if (dueDate.isBefore(DateTime.now())) return;
    const AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
      'task_channel',
      'Rappels de tâches',
      importance: Importance.high,
    );
    const NotificationDetails details = NotificationDetails(android: androidDetails);
    await _notifications.schedule(
      taskId.hashCode,
      'Tâche : $title',
      'Cette tâche arrive à échéance aujourd\'hui',
      dueDate.subtract(const Duration(hours: 1)),
      details,
    );
  }

  static Future<void> cancelTaskReminder(String taskId) async {
    await _notifications.cancel(taskId.hashCode);
  }
}
