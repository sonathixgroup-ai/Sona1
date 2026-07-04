import 'package:flutter/material.dart';

class DisputeDetailPage extends StatelessWidget {
  final String disputeId;

  const DisputeDetailPage({super.key, required this.disputeId});

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: const Text('Litige')),
        body: Center(child: Text('Litige $disputeId')),
      );
}
