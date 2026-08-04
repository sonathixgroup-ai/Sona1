// lib/presentation/thix_weeding/providers/rsvp_provider.dart
import 'package:flutter/foundation.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../core/failure.dart';
import '../data/repositories/wedding_repository_impl.dart';
import '../domain/entities/wedding_entity.dart';

part 'rsvp_provider.g.dart';

@immutable
class RsvpFormState {
  final String guestName;
  final String status; // yes, no, maybe
  final int count;
  final String message;
  final bool isValid;

  const RsvpFormState({
    this.guestName = '',
    this.status = 'yes',
    this.count = 1,
    this.message = '',
    this.isValid = false,
  });

  RsvpFormState copyWith({String? guestName, String? status, int? count, String? message}) {
    final newName = guestName ?? this.guestName;
    final valid = newName.trim().length >= 2;
    return RsvpFormState(
      guestName: newName,
      status: status ?? this.status,
      count: count ?? this.count,
      message: message ?? this.message,
      isValid: valid,
    );
  }
}

/// Formulaire local - pas d'appel réseau, donc Notifier simple
@riverpod
class RsvpForm extends _$RsvpForm {
  @override
  RsvpFormState build() => const RsvpFormState();

  void updateName(String v) => state = state.copyWith(guestName: v);
  void updateStatus(String v) => state = state.copyWith(status: v);
  void updateCount(int v) => state = state.copyWith(count: v.clamp(1, 10));
  void updateMessage(String v) => state = state.copyWith(message: v);
  void reset() => state = const RsvpFormState();
}

/// Controller de soumission - gère loading/error/success
@riverpod
class RsvpController extends _$RsvpController {
  @override
  FutureOr<void> build() {
    // idle au départ
    return null;
  }

  Future<bool> submit(String weddingId) async {
    final form = ref.read(rsvpFormProvider);
    if (!form.isValid) {
      state = AsyncError(const Failure('Nom invalide (min 2 caractères)'), StackTrace.current);
      return false;
    }

    state = const AsyncLoading();
    final repo = ref.read(weddingRepositoryProvider);

    final result = await AsyncValue.guard(() async {
      final entity = RsvpEntity(
        weddingId: weddingId,
        guestName: form.guestName.trim(),
        status: form.status,
        count: form.count,
        message: form.message.trim(),
      );
      await repo.submitRsvp(entity);
    });

    state = result;
    return !result.hasError;
  }
}
