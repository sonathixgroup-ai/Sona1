// lib/presentation/chat/core/chat_providers.dart
// [PARTIE] Providers pour l'injection de dépendances avec Riverpod

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'chat_repository.dart';
import 'chat_bloc.dart';

final chatRepositoryProvider = Provider<ChatRepository>((ref) {
  return ChatRepository();
});

final chatBlocProvider = Provider<ChatBloc>((ref) {
  final repository = ref.watch(chatRepositoryProvider);
  return ChatBloc(repository);
});

final currentUserIdProvider = Provider<String?>((ref) {
  return Supabase.instance.client.auth.currentUser?.id;
});
