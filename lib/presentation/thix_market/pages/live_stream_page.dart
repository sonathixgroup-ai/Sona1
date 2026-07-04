import 'package:flutter/material.dart';

import '../widgets/live/live_stream_player.dart';

class LiveStreamPage extends StatelessWidget {
  final String liveId;

  const LiveStreamPage({super.key, required this.liveId});

  @override
  Widget build(BuildContext context) => LiveStreamPlayer(channelName: liveId, liveId: liveId);
}
