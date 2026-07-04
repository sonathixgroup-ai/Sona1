import 'package:agora_rtc_engine/agora_rtc_engine.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:permission_handler/permission_handler.dart';

class LiveStreamService {
  final SupabaseClient _supabase = Supabase.instance.client;
  late RtcEngine _engine;
  bool _isHost = false;
  bool _isJoined = false;
  int _remoteUid = 0;
  String? _currentChannel;

  // Initialize Agora engine
  Future<void> initEngine({required bool isHost}) async {
    await [Permission.microphone, Permission.camera].request();

    _engine = createRtcEngine();
    await _engine.initialize(const RtcEngineContext(
      appId: 'YOUR_AGORA_APP_ID',
      channelProfile: ChannelProfileType.liveBroadcasting,
    ));

    _engine.registerEventHandler(RtcEngineEventHandler(
      onJoinChannelSuccess: (RtcConnection connection, int elapsed) {
        _isJoined = true;
      },
      onUserJoined: (RtcConnection connection, int remoteUid, int elapsed) {
        _remoteUid = remoteUid;
      },
      onUserOffline: (RtcConnection connection, int remoteUid, UserOfflineReasonType reason) {
        _remoteUid = 0;
      },
      onError: (RtcError err) {
        // Handle error
      },
    ));

    _isHost = isHost;
    if (isHost) {
      await _engine.setClientRole(role: ClientRoleType.clientRoleBroadcaster);
    } else {
      await _engine.setClientRole(role: ClientRoleType.clientRoleAudience);
    }
  }

  // Join a live channel
  Future<void> joinChannel({
    required String channelName,
    required String token,
  }) async {
    _currentChannel = channelName;
    await _engine.joinChannel(
      token: token,
      channelId: channelName,
      uid: 0,
      options: const ChannelMediaOptions(),
    );
  }

  // Leave current channel
  Future<void> leaveChannel() async {
    await _engine.leaveChannel();
    _isJoined = false;
    _remoteUid = 0;
    _currentChannel = null;
  }

  // Start live streaming (host only)
  Future<void> startLive() async {
    if (!_isHost) return;
    // Additional live start logic
  }

  // Stop live streaming (host only)
  Future<void> stopLive() async {
    if (!_isHost) return;
    await leaveChannel();
  }

  // Mute/unmute microphone
  Future<void> toggleMute() async {
    final isMuted = await _engine.isLocalAudioStreamMuted();
    await _engine.muteLocalAudioStream(!isMuted);
  }

  // Switch camera
  Future<void> switchCamera() async {
    await _engine.switchCamera();
  }

  // Enable/disable video
  Future<void> toggleVideo() async {
    final isEnabled = await _engine.isVideoEnabled();
    if (isEnabled) {
      await _engine.disableVideo();
    } else {
      await _engine.enableVideo();
    }
  }

  // Get Agora token from Supabase Edge Function
  Future<String?> getAgoraToken(String channelName) async {
    try {
      final response = await _supabase.functions.invoke('generate-rtc-token', body: {
        'channelName': channelName,
        'role': _isHost ? 'publisher' : 'subscriber',
      });
      return response.data['token'] as String?;
    } catch (e) {
      return null;
    }
  }

  // Create a live session in database
  Future<Map<String, dynamic>> createLiveSession({
    required String shopId,
    required String title,
    String? description,
    required List<String> productIds,
    bool hasAuction = false,
    double? startingPrice,
    DateTime? auctionEndTime,
    DateTime? scheduledStart,
  }) async {
    final channelName = 'live_${DateTime.now().millisecondsSinceEpoch}';
    final token = await getAgoraToken(channelName);

    final liveData = {
      'shop_id': shopId,
      'title': title,
      'description': description,
      'channel_name': channelName,
      'token': token,
      'products': productIds,
      'has_auction': hasAuction,
      'starting_price': startingPrice,
      'auction_end_time': auctionEndTime?.toIso8601String(),
      'scheduled_start': (scheduledStart ?? DateTime.now().add(const Duration(minutes: 5))).toIso8601String(),
      'status': 'scheduled',
      'created_at': DateTime.now().toIso8601String(),
    };

    final response = await _supabase.from('lives').insert(liveData).select().single();
    return response;
  }

  // Start scheduled live (mark as live)
  Future<void> startScheduledLive(String liveId) async {
    await _supabase
        .from('lives')
        .update({
          'status': 'live',
          'started_at': DateTime.now().toIso8601String(),
        })
        .eq('id', liveId);
  }

  // End live session
  Future<void> endLiveSession(String liveId, int durationSeconds) async {
    await _supabase
        .from('lives')
        .update({
          'status': 'ended',
          'ended_at': DateTime.now().toIso8601String(),
          'duration_seconds': durationSeconds,
        })
        .eq('id', liveId);
    await leaveChannel();
  }

  // Increment viewer count
  Future<void> incrementViewers(String liveId) async {
    await _supabase.rpc('increment_live_viewers', params: {'live_id': liveId});
  }

  // Send live comment
  Future<void> sendComment(String liveId, String comment) async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) return;

    await _supabase.from('live_comments').insert({
      'live_id': liveId,
      'user_id': userId,
      'comment': comment,
      'created_at': DateTime.now().toIso8601String(),
    });
  }

  // Get live comments
  Stream<List<Map<String, dynamic>>> getLiveComments(String liveId) {
    return _supabase
        .from('live_comments')
        .stream(primaryKey: ['id'])
        .eq('live_id', liveId)
        .order('created_at', ascending: true)
        .map((data) => List<Map<String, dynamic>>.from(data));
  }

  // Place bid on auction
  Future<void> placeBid(String auctionId, double amount) async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) throw Exception('Login required');

    await _supabase.rpc('place_bid', params: {
      'auction_id': auctionId,
      'bid_amount': amount,
    });
  }

  // Get auction bids stream
  Stream<List<Map<String, dynamic>>> getAuctionBids(String auctionId) {
    return _supabase
        .from('auction_bids')
        .stream(primaryKey: ['id'])
        .eq('auction_id', auctionId)
        .order('amount', ascending: false)
        .map((data) => List<Map<String, dynamic>>.from(data));
  }

  // Get current bid for auction
  Future<double> getCurrentBid(String auctionId) async {
    try {
      final response = await _supabase
          .from('auctions')
          .select('current_bid')
          .eq('id', auctionId)
          .single();
      return (response['current_bid'] as num?)?.toDouble() ?? 0;
    } catch (e) {
      return 0;
    }
  }

  // Clean up
  Future<void> dispose() async {
    await _engine.leaveChannel();
    await _engine.destroy();
  }
}
