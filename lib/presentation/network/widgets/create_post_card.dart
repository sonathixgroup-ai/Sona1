// lib/presentation/network/widgets/create_post_card.dart
import 'package:flutter/material.dart';

class CreatePostCard extends StatelessWidget {
  final Future<void> Function(String text) onCreate;
  const CreatePostCard({Key? key, required this.onCreate}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final controller = TextEditingController();
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            Row(
              children: [
                const CircleAvatar(child: Icon(Icons.person)),
                const SizedBox(width: 12),
                Expanded(child: TextField(controller: controller, decoration: const InputDecoration.collapsed(hintText: "Quoi de neuf ?"))),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                TextButton.icon(onPressed: () {}, icon: const Icon(Icons.photo), label: const Text('Photo')),
                const Spacer(),
                ElevatedButton(
                  onPressed: () async {
                    final text = controller.text.trim();
                    await onCreate(text);
                    controller.clear();
                  },
                  child: const Text('Publier'),
                )
              ],
            )
          ],
        ),
      ),
    );
  }
}
