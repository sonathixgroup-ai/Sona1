import 'package:flutter/material.dart';

import '../widgets/live/create_live_form.dart';

class CreateLivePage extends StatelessWidget {
  const CreateLivePage({super.key});

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: const Text('Créer un live')),
        body: const SafeArea(child: SingleChildScrollView(child: CreateLiveForm(shopId: ''))),
      );
}
