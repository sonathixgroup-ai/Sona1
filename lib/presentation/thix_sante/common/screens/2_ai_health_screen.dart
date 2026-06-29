// 📁 lib/presentation/thix_sante/common/screens/2_ai_health_screen.dart

import 'package:flutter/material.dart';
import '_components/ai_chat_content.dart';
import '_components/predictive_analysis_content.dart';

class AiHealthScreen extends StatefulWidget {
  const AiHealthScreen({Key? key}) : super(key: key);

  @override
  State<AiHealthScreen> createState() => _AiHealthScreenState();
}

class _AiHealthScreenState extends State<AiHealthScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Assistant santé IA'),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.purple,
          labelColor: Colors.purple,
          labelStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
          unselectedLabelStyle: const TextStyle(fontSize: 12),
          tabs: const [
            Tab(icon: Icon(Icons.chat), text: 'Chat IA'),
            Tab(icon: Icon(Icons.analytics), text: 'Prédictions'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: const [
          AiChatContent(),
          PredictiveAnalysisContent(),
        ],
      ),
    );
  }
}
