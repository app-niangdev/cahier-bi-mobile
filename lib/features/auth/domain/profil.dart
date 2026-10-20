import '../../../core/domain/enums.dart';
import '../../../core/domain/subscription_status.dart';

/// Boutique du gérant (profil).
class BoutiqueRef {
  const BoutiqueRef({
    required this.id,
    required this.nom,
    this.ville,
    this.quartier,
  });

  factory BoutiqueRef.fromJson(Map<String, dynamic> json) => BoutiqueRef(
    id: (json['id'] as num).toInt(),
    nom: json['nom'] as String? ?? '',
    ville: json['ville'] as String?,
    quartier: json['quartier'] as String?,
  );

  final int id;
  final String nom;
  final String? ville;
  final String? quartier;
}

/// Utilisateur connecté (TokenService::profile, `GET /auth/me`).
class Profil {
  const Profil({
    required this.id,
    required this.firstName,
    required this.lastName,
    required this.fullName,
    required this.role,
    this.email,
    this.phone,
    this.phoneTwo,
    this.address,
    this.tenantId,
    this.tenantName,
    this.boutique,
    this.subscription,
  });

  factory Profil.fromJson(Map<String, dynamic> json) {
    final tenant = json['tenant'];
    final boutique = json['boutique'];
    final subscription = json['subscription'];
    return Profil(
      id: (json['id'] as num).toInt(),
      firstName: json['first_name'] as String? ?? '',
      lastName: json['last_name'] as String? ?? '',
      fullName: json['full_name'] as String? ?? '',
      role: Role.fromJson(json['role']),
      email: json['email'] as String?,
      phone: json['phone'] as String?,
      phoneTwo: json['phone_two'] as String?,
      address: json['address'] as String?,
      tenantId: (json['tenant_id'] as num?)?.toInt(),
      tenantName: tenant is Map ? tenant['name'] as String? : null,
      boutique:
          boutique is Map
              ? BoutiqueRef.fromJson(boutique.cast<String, dynamic>())
              : null,
      subscription:
          subscription is Map
              ? SubscriptionStatus.fromJson(
                subscription.cast<String, dynamic>(),
              )
              : null,
    );
  }

  final int id;
  final String firstName;
  final String lastName;
  final String fullName;
  final Role role;
  final String? email;
  final String? phone;
  final String? phoneTwo;
  final String? address;
  final int? tenantId;
  final String? tenantName;

  /// Boutique du gérant (null pour le propriétaire).
  final BoutiqueRef? boutique;
  final SubscriptionStatus? subscription;

  bool get isProprietaire => role == Role.proprietaire;
  bool get isGerant => role == Role.gerant;

  String get nomAffiche => [
    firstName,
    lastName,
  ].where((s) => s.isNotEmpty).join(' ').ifEmpty(fullName);
}

extension on String {
  String ifEmpty(String other) => isEmpty ? other : this;
}
