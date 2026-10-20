/// Enums alignés sur app/Enums du backend Laravel (mêmes valeurs, au caractère près).
library;

enum Role {
  admin('ADMIN', 'Administrateur'),
  proprietaire('PROPRIETAIRE', 'Propriétaire'),
  gerant('GERANT', 'Gérant');

  const Role(this.value, this.label);
  final String value;
  final String label;

  static Role fromJson(Object? value) => Role.values.firstWhere(
    (r) => r.value == value,
    orElse: () => Role.gerant,
  );
}

enum StatutDette {
  enAttente('en_attente', 'En attente'),
  aAujourdhui('a_aujourdhui', "Échéance aujourd'hui"),
  enRetard('en_retard', 'En retard'),
  payee('payee', 'Payée'),
  annulee('annulee', 'Annulée');

  const StatutDette(this.value, this.label);
  final String value;
  final String label;

  /// Dette qui peut encore recevoir des paiements (StatutDette::ouverts()).
  bool get estOuverte =>
      this == enAttente || this == aAujourdhui || this == enRetard;

  static StatutDette fromJson(Object? value) => StatutDette.values.firstWhere(
    (s) => s.value == value,
    orElse: () => StatutDette.enAttente,
  );
}

enum MethodePaiement {
  especes('especes', 'Espèces'),
  wave('wave', 'Wave'),
  orangeMoney('orange_money', 'Orange Money'),
  freeMoney('free_money', 'Free Money'),
  autre('autre', 'Autre');

  const MethodePaiement(this.value, this.label);
  final String value;
  final String label;

  static MethodePaiement fromJson(Object? value) => MethodePaiement.values
      .firstWhere((m) => m.value == value, orElse: () => MethodePaiement.autre);
}

enum StatutBoutique {
  actif('actif', 'Active'),
  inactif('inactif', 'Inactive'),
  suspendu('suspendu', 'Suspendue');

  const StatutBoutique(this.value, this.label);
  final String value;
  final String label;

  static StatutBoutique fromJson(Object? value) => StatutBoutique.values
      .firstWhere((s) => s.value == value, orElse: () => StatutBoutique.actif);
}

/// État calculé par SubscriptionService::statusForTenant().
enum EtatAbonnement {
  active('active', 'Actif'),
  expiring('expiring', 'Expire bientôt'),
  expired('expired', 'Expiré'),
  none('none', 'Aucun abonnement');

  const EtatAbonnement(this.value, this.label);
  final String value;
  final String label;

  bool get estValide => this == active || this == expiring;

  static EtatAbonnement fromJson(Object? value) => EtatAbonnement.values
      .firstWhere((s) => s.value == value, orElse: () => EtatAbonnement.none);
}

/// Ton d'un rappel envoyé au client (TonRappel).
enum TonRappel {
  poli('poli', 'Poli'),
  normal('normal', 'Normal'),
  ferme('ferme', 'Ferme');

  const TonRappel(this.value, this.label);
  final String value;
  final String label;
}

/// Canal d'un rappel (CanalRappel).
enum CanalRappel {
  whatsapp('whatsapp', 'WhatsApp'),
  sms('sms', 'SMS');

  const CanalRappel(this.value, this.label);
  final String value;
  final String label;
}
