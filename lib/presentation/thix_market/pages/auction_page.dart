import 'package:flutter/material.dart';

import '../widgets/live/live_auction_widget.dart';

class AuctionPage extends StatelessWidget {
  final String auctionId;

  const AuctionPage({super.key, required this.auctionId});

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: const Text('Enchère')),
        body: LiveAuctionWidget(auctionId: auctionId),
      );
}
