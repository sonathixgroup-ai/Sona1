import 'package:flutter/material.dart';

import '../widgets/shops/create_shop_form.dart';

class CreateShopPage extends StatelessWidget {
  const CreateShopPage({super.key});

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: const Text('Créer une boutique')),
        body: const SafeArea(child: SingleChildScrollView(child: CreateShopForm())),
      );
}
