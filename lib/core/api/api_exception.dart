/// Erreur renvoyée par l'API Laravel : `{ status, message, error_code?, errors?, payload? }`.
class ApiException implements Exception {
  const ApiException(
    this.message, {
    this.code,
    this.status,
    this.fieldErrors = const {},
    this.payload,
  });

  final String message;

  /// `error_code` stable du backend (SUBSCRIPTION_EXPIRED, OTP_INVALID…)
  final String? code;
  final int? status;

  /// Erreurs de validation 422, par champ.
  final Map<String, List<String>> fieldErrors;
  final Map<String, dynamic>? payload;

  /// Accès coupé : abonnement expiré, compte, entreprise ou boutique désactivés.
  bool get isAccessBlocked => accessBlockedCodes.contains(code);

  String? fieldError(String field) => fieldErrors[field]?.first;

  static const accessBlockedCodes = {
    'SUBSCRIPTION_EXPIRED',
    'ACCOUNT_DISABLED',
    'TENANT_DISABLED',
    'BOUTIQUE_DISABLED',
  };

  static const network = ApiException(
    'Impossible de joindre le serveur. Vérifiez votre connexion internet.',
    code: 'NETWORK',
  );

  @override
  String toString() => message;
}

/// Message lisible pour n'importe quelle erreur.
String errorMessage(Object error) =>
    error is ApiException
        ? error.message
        : 'Une erreur est survenue. Veuillez réessayer.';
