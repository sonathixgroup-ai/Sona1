import 'package:flutter/material.dart';

class ScheduledMessage {
  final String id;
  final String conversationId;
  final String content;
  final DateTime scheduledTime;
  final MessageRecurrence recurrence;
  final bool isActive;
  final String? timezone;
  final List<String>? recipientIds;

  const ScheduledMessage({
    required this.id,
    required this.conversationId,
    required this.content,
    required this.scheduledTime,
    this.recurrence = MessageRecurrence.none,
    this.isActive = true,
    this.timezone,
    this.recipientIds,
  });

  ScheduledMessage copyWith({
    String? id,
    String? conversationId,
    String? content,
    DateTime? scheduledTime,
    MessageRecurrence? recurrence,
    bool? isActive,
    String? timezone,
    List<String>? recipientIds,
  }) {
    return ScheduledMessage(
      id: id ?? this.id,
      conversationId: conversationId ?? this.conversationId,
      content: content ?? this.content,
      scheduledTime: scheduledTime ?? this.scheduledTime,
      recurrence: recurrence ?? this.recurrence,
      isActive: isActive ?? this.isActive,
      timezone: timezone ?? this.timezone,
      recipientIds: recipientIds ?? this.recipientIds,
    );
  }
}

enum MessageRecurrence {
  none,
  daily,
  weekly,
  biweekly,
  monthly,
  yearly,
  custom
}
