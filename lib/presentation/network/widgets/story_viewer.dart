import 'package:flutter/material.dart';
import '../../../models/network_story.dart';

class StoryViewer extends StatefulWidget {
  final List<NetworkStory> stories;
  final int initialIndex;
  const StoryViewer({super.key, required this.stories, required this.initialIndex});
  @override State<StoryViewer> createState() => _StoryViewerState();
}
class _StoryViewerState extends State<StoryViewer> {
  late PageController _controller;
  @override void initState(){ super.initState(); _controller = PageController(initialPage: widget.initialIndex); }
  @override Widget build(BuildContext context){
    return Scaffold(backgroundColor: Colors.black, body: PageView.builder(
      controller: _controller, itemCount: widget.stories.length,
      itemBuilder: (c,i){ final s = widget.stories[i]; return Stack(children: [Center(child: Image.network(s.imageUrl)), Positioned(top:50, left:16, child: SafeArea(child: Text(s.userName, style: const TextStyle(color: Colors.white))))]); },
    ));
  }
}
