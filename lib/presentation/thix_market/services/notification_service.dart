import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

class NotificationService {
  final SupabaseClient _supabase = Supabase.instance.client;
  final FlutterLocalNotificationsPlugin _localNotifications = FlutterLocalNotificationsPlugin();
  final FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;

  // Initialize notifications
  Future<void> init() async {
    // Initialize local notifications
    const AndroidInitializationSettings androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    const DarwinInitializationSettings iosSettings = DarwinInitializationSettings();
    const InitializationSettings settings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );
    await _localNotifications.initialize(settings);

    // Request permissions
    await _firebaseMessaging.requestPermission();

    // Get FCM token
    final token = await _firebaseMessaging.getToken();
    if (token != null) {
      await _saveFcmToken(token);
    }

    // Listen to messages
    FirebaseMessaging.onMessage.listen(_handleForegroundMessage);
    FirebaseMessaging.onBackgroundMessage(_handleBackgroundMessage);
  }

  // Save FCM token to database
  Future<void> _saveFcmToken(String token) async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) return;

    try {
      await _supabase.from('user_devices').upsert({
        'user_id': userId,
        'fcm_token': token,
        'updated_at': DateTime.now().toIso8601String(),
      });
    } catch (e) {
      // Silently fail
    }
  }

  // Handle foreground message
  void _handleForegroundMessage(RemoteMessage message) {
    _showLocalNotification(message);
  }

  @pragma('vm:entry-point')
  static Future<void> _handleBackgroundMessage(RemoteMessage message) async {
    // Handle background message
  }

  // Show local notification
  Future<void> _showLocalNotification(RemoteMessage message) async {
    const AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
      'thix_market_channel',
      'THIX Market Notifications',
      importance: Importance.high,
      priority: Priority.high,
    );
    const DarwinNotificationDetails iosDetails = DarwinNotificationDetails();
    const NotificationDetails details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _localNotifications.show(
      DateTime.now().millisecondsSinceEpoch.remainder(100000),
      message.notification?.title ?? 'THIX Market',
      message.notification?.body,
      details,
    );
  }

  // Send push notification to user
  Future<void> sendPushNotification({
    required String userId,
    required String title,
    required String body,
    Map<String, dynamic>? data,
  }) async {
    try {
      await _supabase.functions.invoke('send-push-notification', body: {
        'user_id': userId,
        'title': title,
        'body': body,
        'data': data,
      });
    } catch (e) {
      // Silently fail
    }
  }

  // Send notification to multiple users
  Future<void> sendBulkNotification({
    required List<String> userIds,
    required String title,
    required String body,
    Map<String, dynamic>? data,
  }) async {
    try {
      await _supabase.functions.invoke('send-bulk-notification', body: {
        'user_ids': userIds,
        'title': title,
        'body': body,
        'data': data,
      });
    } catch (e) {
      // Silently fail
    }
  }

  // Save notification to database
  Future<void> saveNotification({
    required String userId,
    required String title,
    required String body,
    String? type,
    String? referenceId,
  }) async {
    try {
      await _supabase.from('notifications').insert({
        'user_id': userId,
        'title': title,
        'body': body,
        'type': type,
        'reference_id': referenceId,
        'is_read': false,
        'created_at': DateTime.now().toIso8601String(),
      });
    } catch (e) {
      // Silently fail
    }
  }

  // Mark notification as read
  Future<void> markAsRead(String notificationId) async {
    try {
      await _supabase
          .from('notifications')
          .update({'is_read': true, 'read_at': DateTime.now().toIso8601String()})
          .eq('id', notificationId);
    } catch (e) {
      // Silently fail
    }
  }

  // Mark all notifications as read
  Future<void> markAllAsRead(String userId) async {
    try {
      await _supabase
          .from('notifications')
          .update({'is_read': true, 'read_at': DateTime.now().toIso8601String()})
          .eq('user_id', userId)
          .eq('is_read', false);
    } catch (e) {
      // Silently fail
    }
  }

  // Get unread count
  Future<int> getUnreadCount(String userId) async {
    try {
      final response = await _supabase
          .from('notifications')
          .select('id', count: CountOption.exact)
          .eq('user_id', userId)
          .eq('is_read', false);
      return response.count ?? 0;
    } catch (e) {
      return 0;
    }
  }

  // Get notifications
  Future<List<Map<String, dynamic>>> getNotifications(String userId, {int limit = 50}) async {
    try {
      final response = await _supabase
          .from('notifications')
          .select()
          .eq('user_id', userId)
          .order('created_at', ascending: false)
          .limit(limit);
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      return [];
    }
  }

  // Send order status notification
  Future<void> notifyOrderStatus(String orderId, String status) async {
    try {
      final order = await _supabase
          .from('orders')
          .select('user_id')
          .eq('id', orderId)
          .single();
      final userId = order['user_id'] as String;
      await sendPushNotification(
        userId: userId,
        title: 'Mise à jour commande #$orderId',
        body: 'Votre commande est maintenant $status',
        data: {'order_id': orderId, 'status': status},
      );
      await saveNotification(
        userId: userId,
        title: 'Commande mise à jour',
        body: 'La commande #$orderId est $status',
        type: 'order',
        referenceId: orderId,
      );
    } catch (e) {
      // Silently fail
    }
  }

  // Send new message notification
  Future<void> notifyNewMessage(String conversationId, String message, String senderName) async {
    // Implementation
  }

  // Send promotion notification
  Future<void> notifyPromotion(String title, String body, List<String> userIds) async {
    await sendBulkNotification(userIds: userIds, title: title, body: body);
  }
}
