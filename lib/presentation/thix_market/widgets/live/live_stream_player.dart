import 'package:flutter/material.dart';
import 'package:agora_rtc_engine/agora_rtc_engine.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:intl/intl.dart';

class LiveStreamPlayer extends StatefulWidget {
  final String channelName;
  final String liveId;
  final String? token;

  const LiveStreamPlayer({
    super.key,
    required this.channelName,
    required this.liveId,
    this.token,
  });

  @override
  State<LiveStreamPlayer> createState() => _LiveStreamPlayerState();
}

class _LiveStreamPlayerState extends State<LiveStreamPlayer> {
  late RtcEngine _engine;
  bool _isJoined = false;
  int _remoteUid = 0;
  bool _isMuted = false;
  bool _isChatOpen = false;
  final TextEditingController _messageController = TextEditingController();
  List<Map<String, dynamic>> _messages = [];
  Map<String, dynamic> _liveInfo = {};
  List<Map<String, dynamic>> _products = [];
  int _viewerCount = 0;
  String? _currentAuctionId;
  double _currentBid = 0;

  @override
  void initState() {
    super.initState();
    _initAgora();
    _loadLiveInfo();
    _setupRealtimeMessages();
    _updateViewerCount();
  }

  @override
  void dispose() {
    _engine.leaveChannel();
    _engine.destroy();
    _messageController.dispose();
    super.dispose();
  }

  Future<void> _initAgora() async {
    await [Permission.microphone, Permission.camera].request();
    
    _engine = createRtcEngine();
    await _engine.initialize(const RtcEngineContext(
      appId: 'YOUR_AGORA_APP_ID',
      channelProfile: ChannelProfileType.liveBroadcasting,
    ));
    
    _engine.registerEventHandler(RtcEngineEventHandler(
      onJoinChannelSuccess: (RtcConnection connection, int elapsed) {
        setState(() {
          _isJoined = true;
        });
      },
      onUserJoined: (RtcConnection connection, int remoteUid, int elapsed) {
        setState(() {
          _remoteUid = remoteUid;
        });
      },
      onUserOffline: (RtcConnection connection, int remoteUid, UserOfflineReasonType reason) {
        setState(() {
          _remoteUid = 0;
        });
      },
    ));
    
    await _engine.setClientRole(role: ClientRoleType.clientRoleAudience);
    await _engine.joinChannel(
      token: widget.token ?? '',
      channelId: widget.channelName,
      uid: 0,
      options: const ChannelMediaOptions(),
    );
  }

  Future<void> _loadLiveInfo() async {
    try {
      final response = await Supabase.instance.client
          .from('lives')
          .select('*, shop:shops(name, logo_url)')
          .eq('id', widget.liveId)
          .single();
      
      setState(() {
        _liveInfo = response;
        _products = List<Map<String, dynamic>>.from(response['products'] ?? []);
        _currentAuctionId = response['auction_id'];
        _currentBid = response['current_bid']?.toDouble() ?? 0;
      });
    } catch (e) {
      debugPrint('Error loading live info: $e');
    }
  }

  void _setupRealtimeMessages() {
    Supabase.instance.client
        .from('live_messages')
        .stream(primaryKey: ['id'])
        .eq('live_id', widget.liveId)
        .listen((data) {
      if (mounted) {
        setState(() {
          _messages = List<Map<String, dynamic>>.from(data);
        });
      }
    });
  }

  Future<void> _updateViewerCount() async {
    await Supabase.instance.client.rpc('increment_live_viewers', params: {
      'live_id': widget.liveId,
    });
    
    final response = await Supabase.instance.client
        .from('lives')
        .select('viewer_count')
        .eq('id', widget.liveId)
        .single();
    
    setState(() {
      _viewerCount = response['viewer_count'] ?? 0;
    });
  }

  Future<void> _sendMessage() async {
    final userId = Supabase.instance.client.auth.currentUser?.id;
    if (userId == null || _messageController.text.isEmpty) return;
    
    await Supabase.instance.client
        .from('live_messages')
        .insert({
          'live_id': widget.liveId,
          'user_id': userId,
          'message': _messageController.text,
          'created_at': DateTime.now().toIso8601String(),
        });
    
    _messageController.clear();
  }

  Future<void> _placeBid() async {
    final bidAmount = await showDialog<double>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Placer une enchère'),
        content: TextField(
          keyboardType: TextInputType.number,
          decoration: InputDecoration(
            hintText: 'Montant (FCFA)',
            suffixText: 'FCFA',
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Annuler')),
          ElevatedButton(
            onPressed: () {
              final amount = double.tryParse((context.findChildRenderObject() as TextEditingController?)?.text ?? '0');
              Navigator.pop(context, amount);
            },
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFE5592F)),
            child: const Text('Enchérir'),
          ),
        ],
      ),
    );
    
    if (bidAmount != null && bidAmount > _currentBid) {
      await Supabase.instance.client.rpc('place_bid', params: {
        'auction_id': _currentAuctionId,
        'bid_amount': bidAmount,
      });
      
      setState(() {
        _currentBid = bidAmount;
      });
    }
  }

  String _formatNumber(int num) {
    if (num >= 1000000) return '${(num / 1000000).toStringAsFixed(1)}M';
    if (num >= 1000) return '${(num / 1000).toStringAsFixed(1)}k';
    return num.toString();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Video stream
          if (_isJoined)
            AgoraVideoView(
              controller: VideoViewController.remote(
                rtcEngine: _engine,
                canvas: VideoCanvas(uid: _remoteUid),
                connection: RtcConnection(channelId: widget.channelName),
              ),
            )
          else
            Container(color: Colors.black),
          
          // Overlay controls
          Positioned(
            top: 40,
            left: 16,
            right: 16,
            child: Row(
              children: [
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.arrow_back, color: Colors.white),
                  style: IconButton.styleFrom(backgroundColor: Colors.black54),
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.black54,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.visibility, size: 16, color: Colors.white),
                      const SizedBox(width: 4),
                      Text(
                        _formatNumber(_viewerCount),
                        style: const TextStyle(color: Colors.white),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.red,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Row(
                    children: [
                      Icon(Icons.fiber_manual_record, size: 12, color: Colors.white),
                      SizedBox(width: 4),
                      Text('LIVE', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                    ],
                  ),
                ),
              ],
            ),
          ),
          
          // Shop info
          Positioned(
            bottom: 100,
            left: 16,
            child: GestureDetector(
              onTap: () => Navigator.pushNamed(context, '/shop/${_liveInfo['shop_id']}'),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.black54,
                  borderRadius: BorderRadius.circular(24),
                ),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 16,
                      backgroundImage: CachedNetworkImageProvider(_liveInfo['shop']?['logo_url'] ?? ''),
                    ),
                    const SizedBox(width: 8),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _liveInfo['shop']?['name'] ?? 'Boutique',
                          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w500),
                        ),
                        Text(
                          _liveInfo['title'] ?? '',
                          style: const TextStyle(color: Colors.white70, fontSize: 11),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
          
          // Products list
          if (_products.isNotEmpty)
            Positioned(
              right: 16,
              bottom: 100,
              child: Column(
                children: _products.map((product) => Container(
                  width: 60,
                  height: 60,
                  margin: const EdgeInsets.only(bottom: 8),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: const Color(0xFFE5592F), width: 2),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: CachedNetworkImage(
                      imageUrl: product['image_url'],
                      fit: BoxFit.cover,
                    ),
                  ),
                )).toList(),
              ),
            ),
          
          // Auction panel
          if (_currentAuctionId != null)
            Positioned(
              bottom: 100,
              left: 0,
              right: 0,
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 16),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.black87,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.gavel, color: Color(0xFFE5592F)),
                    const SizedBox(width: 8),
                    Text(
                      'Enchère: ${_currentBid.toInt()} FCFA',
                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                    ),
                    const Spacer(),
                    ElevatedButton(
                      onPressed: _placeBid,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFE5592F),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                      ),
                      child: const Text('Enchérir'),
                    ),
                  ],
                ),
              ),
            ),
          
          // Chat panel toggle
          Positioned(
            bottom: 20,
            right: 16,
            child: FloatingActionButton(
              onPressed: () => setState(() => _isChatOpen = !_isChatOpen),
              mini: true,
              backgroundColor: const Color(0xFFE5592F),
              child: Icon(_isChatOpen ? Icons.close : Icons.chat),
            ),
          ),
          
          // Chat panel
          if (_isChatOpen)
            Positioned(
              bottom: 80,
              right: 16,
              width: 300,
              height: 400,
              child: Card(
                elevation: 8,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                child: Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: const BoxDecoration(
                        color: Color(0xFFE5592F),
                        borderRadius: BorderRadius.vertical(top: Radius.circular(12)),
                      ),
                      child: const Row(
                        children: [
                          Icon(Icons.chat, color: Colors.white),
                          SizedBox(width: 8),
                          Text('Chat en direct', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                        ],
                      ),
                    ),
                    Expanded(
                      child: ListView.builder(
                        reverse: true,
                        padding: const EdgeInsets.all(8),
                        itemCount: _messages.length,
                        itemBuilder: (context, index) {
                          final msg = _messages.reversed.toList()[index];
                          return Padding(
                            padding: const EdgeInsets.symmetric(vertical: 4),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  msg['user_name'] ?? 'Anonyme',
                                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                                ),
                                Text(msg['message'], style: const TextStyle(fontSize: 12)),
                              ],
                            ),
                          );
                        },
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(8),
                      child: Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: _messageController,
                              decoration: InputDecoration(
                                hintText: 'Votre message...',
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(24),
                                  borderSide: BorderSide.none,
                                ),
                                filled: true,
                                fillColor: Colors.grey[100],
                                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                              ),
                            ),
                          ),
                          IconButton(
                            onPressed: _sendMessage,
                            icon: const Icon(Icons.send),
                            color: const Color(0xFFE5592F),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          
          // Audio toggle
          Positioned(
            bottom: 20,
            left: 16,
            child: IconButton(
              onPressed: () {
                setState(() => _isMuted = !_isMuted);
                _engine.muteLocalAudioStream(_isMuted);
              },
              icon: Icon(_isMuted ? Icons.volume_off : Icons.volume_up, color: Colors.white),
              style: IconButton.styleFrom(backgroundColor: Colors.black54),
            ),
          ),
        ],
      ),
    );
  }
}
