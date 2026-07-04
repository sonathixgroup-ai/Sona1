import 'package:flutter/material.dart';

import '../widgets/selling/publish_announcement_form.dart';

class PublishAnnouncementPage extends StatelessWidget {
  const PublishAnnouncementPage({super.key});

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: const Text('Publier une annonce')),
        body: const SafeArea(child: SingleChildScrollView(child: PublishAnnouncementForm(shopId: null))),
      );
}
