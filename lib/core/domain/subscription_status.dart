import '../utils/format.dart';
import 'enums.dart';

/// État de l'abonnement de l'entreprise (SubscriptionService::statusForTenant).
class SubscriptionStatus {
  const SubscriptionStatus({
    required this.state,
    this.plan,
    this.startsAt,
    this.endsAt,
    this.daysLeft,
  });

  factory SubscriptionStatus.fromJson(Map<String, dynamic> json) =>
      SubscriptionStatus(
        state: EtatAbonnement.fromJson(json['state']),
        plan: json['plan'] as String?,
        startsAt: parseDate(json['starts_at']),
        endsAt: parseDate(json['ends_at']),
        daysLeft: toIntOrNull(json['days_left']),
      );

  final EtatAbonnement state;
  final String? plan;
  final DateTime? startsAt;
  final DateTime? endsAt;

  /// Négatif une fois expiré.
  final int? daysLeft;

  /// Forfait gratuit offert à l'inscription, ou période d'essai.
  bool get estOffert => plan == 'Gratuit' || plan == 'Essai';
}
