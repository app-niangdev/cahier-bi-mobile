import 'package:flutter/foundation.dart';

/// Version de l'application, comparée à `GET /api/app-version` (garder alignée sur pubspec.yaml).
const appVersion = '1.0.0';

/// URL de l'API Laravel, préfixe /api compris.
///
/// `flutter run --dart-define=API_URL=https://api.exemple.com/api`
/// Sans valeur : `php artisan serve` en local (10.0.2.2 depuis l'émulateur Android).
String get apiUrl {
  const fromEnv = String.fromEnvironment('API_URL');
  if (fromEnv.isNotEmpty) return fromEnv;
  if (!kIsWeb && defaultTargetPlatform == TargetPlatform.android) {
    return 'http://10.0.2.2:8000/api';
  }
  return 'http://127.0.0.1:8000/api';
}
