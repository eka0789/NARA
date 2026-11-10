import '../ai/gemini_service.dart';
import '../../features/auth/auth_repository.dart';

/// Everything the app needs before the first frame, decided once in `main`.
///
/// Firebase initialization lives in `main.dart` (placeholder detection →
/// local-mode fallback); this class only carries the decided state.
class AppBootstrap {
  const AppBootstrap({
    required this.firebaseEnabled,
    required this.auth,
    required this.ai,
  });

  /// True when Firebase initialized (production mode); false runs in
  /// device-local demo mode.
  final bool firebaseEnabled;
  final AuthRepository auth;
  final GeminiService ai;
}
