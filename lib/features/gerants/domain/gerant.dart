import '../../../core/utils/format.dart';

/// Gérant d'une boutique du propriétaire (`GET /manager/gerants`).
class Gerant {
  const Gerant({
    required this.id,
    required this.firstName,
    required this.lastName,
    required this.fullName,
    required this.phoneOne,
    required this.status,
    required this.phoneVerified,
    required this.mustChangePassword,
    this.phoneTwo,
    this.address,
    this.boutiqueId,
    this.boutiqueNom,
  });

  factory Gerant.fromJson(Map<String, dynamic> json) {
    final boutique = json['boutique'];
    return Gerant(
      id: (json['id'] as num).toInt(),
      firstName: json['first_name'] as String? ?? '',
      lastName: json['last_name'] as String? ?? '',
      fullName: json['full_name'] as String? ?? '',
      phoneOne: json['phone_one'] as String? ?? '',
      phoneTwo: json['phone_two'] as String?,
      address: json['address'] as String?,
      status: json['status'] == true || json['status'] == 1,
      phoneVerified: json['phone_verified'] == true,
      mustChangePassword: json['must_change_password'] == true,
      boutiqueId: boutique is Map ? toIntOrNull(boutique['id']) : null,
      boutiqueNom: boutique is Map ? boutique['nom'] as String? : null,
    );
  }

  final int id;
  final String firstName;
  final String lastName;
  final String fullName;
  final String phoneOne;
  final String? phoneTwo;
  final String? address;

  /// Compte actif
  final bool status;
  final bool phoneVerified;

  /// Mot de passe provisoire pas encore remplacé (première connexion à faire).
  final bool mustChangePassword;
  final int? boutiqueId;
  final String? boutiqueNom;
}

class GerantPayload {
  const GerantPayload({
    required this.firstName,
    required this.lastName,
    required this.phoneOne,
    this.phoneTwo,
    this.address,
  });

  final String firstName;
  final String lastName;
  final String phoneOne;
  final String? phoneTwo;
  final String? address;

  Map<String, dynamic> toJson() => {
    'first_name': firstName.trim(),
    'last_name': lastName.trim(),
    'phone_one': nationalNumber(phoneOne) ?? phoneOne,
    'phone_two':
        phoneTwo == null || phoneTwo!.trim().isEmpty
            ? null
            : nationalNumber(phoneTwo) ?? phoneTwo,
    'address':
        address == null || address!.trim().isEmpty ? null : address!.trim(),
  };
}
