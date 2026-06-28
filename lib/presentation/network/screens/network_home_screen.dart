// lib/presentation/network/screens/network_home_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:thix_id/presentation/network/state/network_provider.dart';
import 'package:thix_id/presentation/network/widgets/network_app_bar.dart';
import 'package:thix_id/presentation/network/widgets/stories_section.dart';
import 'package:thix_id/presentation/network/widgets/category_tabs.dart';
import 'package:thix_id/presentation/network/widgets/create_post_card.dart';
import 'package:thix_id/presentation/network/widgets/feed_post_card.dart';
import 'package:thix_id/presentation/network/widgets/opportunities_section.dart';

class NetworkHomeScreen extends StatefulWidget {
  const NetworkHomeScreen({Key? key}) : super(key: key);

  @override
  State<NetworkHomeScreen> createState() => _NetworkHomeScreenState();
}

class _NetworkHomeScreenState extends State<NetworkHomeScreen> {
  @override
  void initState() {
    super.initState();
    final provider = context.read<NetworkProvider>();
    provider.init();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const PreferredSize(preferredSize: Size.fromHeight(64), child: NetworkAppBar()),
      body: Consumer<NetworkProvider>(builder: (context, p, _) {
        return RefreshIndicator(
          onRefresh: p.refreshAll,
          child: ListView(
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
            children: [
              const StoriesSection(),
              const SizedBox(height: 12),
              const CategoryTabs(),
              const SizedBox(height: 12),
              CreatePostCard(onCreate: (text) => p.createPost(text)),
              const SizedBox(height: 12),
              OpportunitiesSection(opportunities: p.state.opportunities),
              const SizedBox(height: 12),
              ...p.state.posts.map((post) => FeedPostCard(post: post, onTapComments: () => p.openComments(context, post))).toList(),
              if (p.state.isLoading) const Padding(padding: EdgeInsets.symmetric(vertical: 24), child: Center(child: CircularProgressIndicator())),
            ],
          ),
        );
      }),
      bottomNavigationBar: const SizedBox(height: 72, child: SizedBox.expand(child: Center(child: Text('Navigation')))),
    );
  }
}
