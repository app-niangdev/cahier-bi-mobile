import '../../../core/domain/subscription_status.dart';
import '../../../core/utils/format.dart';

/// Compte du propriétaire (`GET /manager/company`).
class Entreprise {
  const Entreprise({
    required this.id,
    required this.name,
    this.shortName,
    this.slogan,
    this.address,
    this.email,
    this.trade,
    this.ninea,
    this.rccm,
    this.phoneCall,
    this.phoneWhatsapp,
    this.logoUrl,
  });

  factory Entreprise.fromJson(Map<String, dynamic> json) => Entreprise(
    id: (json['id'] as num).toInt(),
    name: json['name'] as String? ?? '',
    shortName: json['short_name'] as String?,
    slogan: json['slogan'] as String?,
    address: json['address'] as String?,
    email: json['email'] as String?,
    trade: json['trade'] as String?,
    ninea: json['ninea'] as String?,
    rccm: json['rccm'] as String?,
    phoneCall: json['phone_call'] as String?,
    phoneWhatsapp: json['phone_whatsapp'] as String?,
    logoUrl: json['logo_url'] as String?,
  );

  final int id;
  final String name;
  final String? shortName;
  final String? slogan;
  final String? address;
  final String? email;
  final String? trade;
  final String? ninea;
  final String? rccm;
  final String? phoneCall;
  final String? phoneWhatsapp;
  final String? logoUrl;
}

/// `GET /manager/subscription`
class AbonnementEntreprise {
  const AbonnementEntreprise({
    required this.status,
    required this.warningDays,
    this.maxGerantsParBoutique,
  });

  factory AbonnementEntreprise.fromJson(Map<String, dynamic> json) =>
      AbonnementEntreprise(
        status: SubscriptionStatus.fromJson(
          (json['status'] as Map).cast<String, dynamic>(),
        ),
        warningDays: toIntOrNull(json['warning_days']) ?? 5,
        maxGerantsParBoutique: toIntOrNull(json['max_gerants_par_boutique']),
      );

  final SubscriptionStatus status;
  final int warningDays;

  /// null = illimité
  final int? maxGerantsParBoutique;
}

/// Forfait proposé (`GET /subscription-offers`).
class Forfait {
  const Forfait({
    required this.id,
    required this.name,
    required this.durationMonths,
    required this.price,
    this.maxGerantsParBoutique,
    this.description,
  });

  factory Forfait.fromJson(Map<String, dynamic> json) => Forfait(
    id: (json['id'] as num).toInt(),
    name: json['name'] as String? ?? '',
    durationMonths: toIntOrNull(json['duration_months']) ?? 1,
    price: toDouble(json['price']),
    maxGerantsParBoutique: toIntOrNull(json['max_gerants_par_boutique']),
    description: json['description'] as String?,
  );

  final int id;
  final String name;
  final int durationMonths;
  final double price;
  final int? maxGerantsParBoutique;
  final String? description;

  String get dureeLibelle =>
      durationMonths == 12 ? '1 an' : '$durationMonths mois';
  String get gerantsLibelle =>
      maxGerantsParBoutique == null
          ? 'Gérants illimités'
          : '$maxGerantsParBoutique gérant(s) par boutique';
}

/// Offres et contact pour payer (public : affiché aussi au propriétaire bloqué).
class Offres {
  const Offres({
    required this.forfaits,
    this.contactNom,
    this.contactTelephone,
    this.contactWhatsapp,
    this.moyensPaiement,
  });

  factory Offres.fromJson(Map<String, dynamic> json) {
    final contact = (json['contact'] as Map?) ?? const {};
    return Offres(
      forfaits:
          (json['plans'] as List? ?? const [])
              .map((e) => Forfait.fromJson((e as Map).cast<String, dynamic>()))
              .toList(),
      contactNom: contact['name'] as String?,
      contactTelephone: contact['phone'] as String?,
      contactWhatsapp: contact['whatsapp'] as String?,
      moyensPaiement: contact['payment_methods'] as String?,
    );
  }

  final List<Forfait> forfaits;
  final String? contactNom;
  final String? contactTelephone;
  final String? contactWhatsapp;
  final String? moyensPaiement;
}

/// `GET /app-version`
class VersionInfo {
  const VersionInfo({
    required this.latest,
    required this.min,
    this.androidUrl,
    this.releaseNotes,
  });

  factory VersionInfo.fromJson(Map<String, dynamic> json) => VersionInfo(
    latest: json['latest_version'] as String? ?? '0.0.0',
    min: json['min_version'] as String? ?? '0.0.0',
    androidUrl: json['android_url'] as String?,
    releaseNotes: json['release_notes'] as String?,
  );

  final String latest;
  final String min;
  final String? androidUrl;
  final String? releaseNotes;
}

/// Compare deux versions « 1.2.3 » : négatif si a < b.
int compareVersions(String a, String b) {
  List<int> parts(String v) =>
      v
          .split('.')
          .map((p) => int.tryParse(p.replaceAll(RegExp(r'\D.*'), '')) ?? 0)
          .toList();
  final pa = parts(a), pb = parts(b);
  for (var i = 0; i < 3; i++) {
    final x = i < pa.length ? pa[i] : 0, y = i < pb.length ? pb[i] : 0;
    if (x != y) return x.compareTo(y);
  }
  return 0;
}
