// lib/presentation/network/controllers/network_controller.dart
import 'package:flutter/material.dart';
import 'package:thix_id/presentation/network/services/network_service.dart';
import 'package:thix_id/presentation/network/models/post_model.dart';
import 'package:thix_id/presentation/network/models/story_model.dart';
import 'package:thix_id/presentation/network/models/opportunity_model.dart';

class NetworkController {
  final NetworkService service;
  NetworkController({required this.service});

  Future<List<PostModel>> fetchPosts({int limit = 20, int offset = 0}) async => service.fetchPosts(limit: limit, offset: offset);
  Future<List<StoryModel>> fetchStories() async => service.fetchStories();
  Future<List<OpportunityModel>> fetchOpportunities() async => service.fetchOpportunities();
  Future<void> createPost(String profileId, String content) async => service.createPost(profileId: profileId, content: content);
}
