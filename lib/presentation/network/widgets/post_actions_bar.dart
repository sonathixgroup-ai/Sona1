// lib/presentation/network/widgets/post_actions_bar.dart
import 'package:flutter/material.dart';

class PostActionsBar extends StatelessWidget {
  final int likes;
  final int comments;
  final VoidCallback? onComments;
  final VoidCallback? onLike;

  const PostActionsBar({Key? key, required this.likes, required this.comments, this.onComments, this.onLike}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        IconButton(onPressed: onLike, icon: const Icon(Icons.thumb_up_outlined)),
        Text('$likes'),
        const SizedBox(width: 16),
        IconButton(onPressed: onComments, icon: const Icon(Icons.comment_outlined)),
        Text('$comments'),
        const Spacer(),
        IconButton(onPressed: () {}, icon: const Icon(Icons.share_outlined)),
      ],
    );
  }
}
