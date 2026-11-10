import '../../l10n/generated/app_localizations.dart';

/// Maps an [AuthException]-style l10n key to localized text.
String authErrorMessage(AppLocalizations l10n, String key) => switch (key) {
      'authErrorWrongPassword' => l10n.authErrorWrongPassword,
      'authErrorNetwork' => l10n.authErrorNetwork,
      'authErrorTooManyRequests' => l10n.authErrorTooManyRequests,
      'authErrorNameEmpty' => l10n.authErrorNameEmpty,
      'authGoogleCancelled' => l10n.authGoogleCancelled,
      _ => l10n.commonErrorGeneric,
    };
