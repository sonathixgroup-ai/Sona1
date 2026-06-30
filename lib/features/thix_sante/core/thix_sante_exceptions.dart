import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Enterprise-friendly exception for the THIX Santé feature.
///
/// This keeps error handling consistent across repositories and UI.
class ThixSanteException implements Exception {
  final String message;
  final String? code;
  final Object? cause;
  ThixSanteException(this.message, {this.code, this.cause});

  @override
  String toString() => 'ThixSanteException(code=$code, message=$message, cause=$cause)';
}

ThixSanteException mapSupabaseError(Object error, {required String context}) {
  debugPrint('THIX Santé error ($context): $error');

  if (error is PostgrestException) {
    return ThixSanteException(
      'Erreur serveur (${error.code ?? 'postgrest'}): ${error.message}',
      code: error.code,
      cause: error,
    );
  }
  if (error is AuthException) {
    return ThixSanteException('Erreur d\'authentification: ${error.message}', code: 'auth', cause: error);
  }
  return ThixSanteException('Une erreur est survenue. Réessaie.', code: 'unknown', cause: error);
}
