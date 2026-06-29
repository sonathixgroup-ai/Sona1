// Re-export for legacy paths.
//
// Some parts of the codebase import `package:thix_id/providers/feed_provider.dart`,
// while the actual implementation lives in `lib/provides/feed_provider.dart`.
// Keeping this file avoids breaking imports without refactoring the module.

export 'package:thix_id/provides/feed_provider.dart';
