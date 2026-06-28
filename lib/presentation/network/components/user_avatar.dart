// lib/presentation/network/components/user_avatar.dart
import 'package:flutter/material.dart';

class UserAvatar extends StatelessWidget {
  final double size;
  final String? url;
  const UserAvatar({Key? key, this.size = 40, this.url}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return CircleAvatar(radius: size / 2, backgroundImage: url != null ? NetworkImage(url!) : null, child: url == null ? const Icon(Icons.person) : null);
  }
}
