// lib/presentation/chat/message_reminder/message_reminder.dart
// Permet de programmer un rappel sur un message (ex: "me rappeler dans 1h")

import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class MessageReminder {
  static final FlutterLocalNotificationsPlugin _notifications = FlutterLocalNotificationsPlugin();

  static Future<void> init() async {
    const AndroidInitializationSettings android = AndroidInitializationSettings('@mipmap/ic_launcher');
    const DarwinInitializationSettings ios = DarwinInitializationSettings();
    const InitializationSettings settings = InitializationSettings(android: android, iOS: ios);
    await _notifications.initialize(settings);
  }

  static Future<void> scheduleReminder({
    required String messageId,
    required String conversationId,
    required String messagePreview,
    required DateTime remindAt,
  }) async {
    const AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
      'reminder_channel',
      'Rappels de messages',
      importance: Importance.high,
    );
    const NotificationDetails details = NotificationDetails(android: androidDetails);
    await _notifications.schedule(
      messageId.hashCode,
      'Rappel de message',
      messagePreview,
      remindAt,
      details,
    );
  }

  static Future<void> cancelReminder(String messageId) async {
    await _notifications.cancel(messageId.hashCode);
  }

  static Future<void> showReminderPicker(BuildContext context, String messageId, String conversationId, String messagePreview) async {
    final DateTime? selectedDate = await showDatePicker(
      context: context,
      initialDate: DateTime.now().add(const Duration(hours: 1)),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 30)),
    );
    if (selectedDate == null) return;
    final TimeOfDay? selectedTime = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
    );
    if (selectedTime == null) return;
    final remindAt = DateTime(selectedDate.year, selectedDate.month, selectedDate.day, selectedTime.hour, selectedTime.minute);
    await scheduleReminder(
      messageId: messageId,
      conversationId: conversationId,
      messagePreview: messagePreview.length > 50 ? '${messagePreview.substring(0, 50)}...' : messagePreview,
      remindAt: remindAt,
    );
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Rappel programmé pour le ${_formatDate(remindAt)}')),
      );
    }
  }

  static String _formatDate(DateTime dt) => '${dt.day}/${dt.month}/${dt.year} à ${dt.hour}:${dt.minute}';
}
