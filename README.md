# Cahier Bi — application mobile (propriétaire et gérant)

Application Flutter (Android, iOS et Web/PWA) branchée sur l'API Laravel de `../backend`
(`/api/auth/*`, `/api/manager/*`). L'espace administrateur reste l'application Angular de `../frontend`.

## Parcours

- **Propriétaire** : il s'inscrit depuis l'application (prénom, nom, commerce, quartier, ville, numéro WhatsApp,
  mot de passe). Le code reçu sur WhatsApp confirme son numéro. Son entreprise est alors activée avec
  **le forfait « Gratuit »** et **une première boutique** au nom du commerce, et la session s'ouvre.
  Les boutiques suivantes sont créées par l'administrateur.
- **Gérant** : il ne s'inscrit pas. Le propriétaire crée son compte (onglet Gérants) et lui communique un mot de
  passe provisoire. À la première connexion, le gérant confirme son numéro par un code WhatsApp et choisit son
  mot de passe ; ensuite il se connecte directement et arrive dans **la boutique à laquelle il est affecté**.
- **Abonnement expiré, entreprise, compte ou boutique désactivés** : page bloquante avec les forfaits et le contact
  pour payer.

| Fonction | Propriétaire | Gérant |
|---|---|---|
| Accueil (total à récupérer, encaissements, dettes par statut, à relancer) | toutes ses boutiques ou une seule | sa boutique |
| Clients : liste, recherche, fiche, création, modification, suppression | ✓ | ✓ |
| Dettes : création, modification, paiement ; versement global avec aperçu de la répartition | ✓ | ✓ (sans modifier le montant) |
| Annuler une dette ou un versement | ✓ | — |
| Relance WhatsApp / SMS (ton poli, normal, ferme) et appel | ✓ | ✓ |
| Gérants : quota par boutique, ajout, modification, transfert, activation, accès, suppression | ✓ | — |
| Mon entreprise, abonnement et forfaits | ✓ | — |

## Lancer

Prérequis : Flutter 3.29 (Dart 3.7), l'API Laravel démarrée.

```bash
flutter pub get

# API locale (php artisan serve) : 10.0.2.2 depuis l'émulateur Android, 127.0.0.1 ailleurs
flutter run

# Autre API (téléphone réel sur le même réseau, préproduction, production)
flutter run --dart-define=API_URL=https://api.exemple.com/api
flutter run -d chrome --dart-define=API_URL=http://127.0.0.1:8000/api
```

L'URL de l'API se règle uniquement par `API_URL` (voir `lib/core/config.dart`).
En debug, Android et iOS autorisent l'HTTP local ; **la version publiée doit utiliser HTTPS**.

Sur un téléphone réel, lancer l'API avec `php artisan serve --host=0.0.0.0` et passer l'IP du poste dans `API_URL`.

## Tests

```bash
flutter analyze
flutter test                       # tests unitaires et de widgets (sans réseau)
```

Test de bout en bout contre une API locale (ignoré sans `API_URL`) : inscription d'un propriétaire, boutique et
forfait Gratuit, client, dettes, paiements, versement global, annulation, gérant et sa première connexion.
Avec WAHA **non configuré** (`WAHA_BASE_URL` vide), les codes OTP sont écrits dans `storage/logs/laravel.log`
au lieu d'être envoyés :

```bash
flutter test test/e2e --dart-define=API_URL=http://127.0.0.1:8000/api \
  --dart-define=LARAVEL_LOG=../backend/storage/logs/laravel.log
```

> Ne lancez pas ce test contre un backend dont WAHA est configuré : il enverrait de vrais messages WhatsApp
> à des numéros générés au hasard.

## Build

```bash
flutter build apk --release --dart-define=API_URL=https://api.exemple.com/api
flutter build web --release --dart-define=API_URL=https://api.exemple.com/api
```

Avant une publication Android : remplacer l'identifiant `com.example.mobile_cahier_bi`
(`android/app/build.gradle.kts`) et configurer la signature.

La version de l'application (`appVersion` dans `lib/core/config.dart`, à garder égale à `pubspec.yaml`) est comparée
à `GET /api/app-version` : sous `MOBILE_MIN_VERSION`, la mise à jour est imposée ; sous `MOBILE_LATEST_VERSION`, elle
est proposée avec le lien `MOBILE_ANDROID_URL`.

## Web (PWA)

- URLs sans `#` (`usePathUrlStrategy`). Le serveur doit renvoyer toutes les routes inconnues vers `index.html` :

  ```nginx
  location / {
      try_files $uri $uri/ /index.html;
  }
  ```

- Servir en **HTTPS** (obligatoire pour l'installation de la PWA et le stockage sécurisé des jetons).
- L'API doit autoriser l'origine du site (`CORS_ALLOWED_ORIGINS` côté Laravel).
- iOS : pas d'invite d'installation, passer par Safari › Partager › « Sur l'écran d'accueil ».
- Relances : `wa.me` ouvre WhatsApp (ou WhatsApp Web sur ordinateur) ; le lien `sms:` dépend du navigateur
  et ne fonctionne généralement que sur mobile.

## Architecture

```text
lib/
├── main.dart, app/          application, thème, routeur (redirections session/rôle), coque responsive, providers
├── core/                    client HTTP (enveloppe, jeton, renouvellement, erreurs), formats, enums, config
├── shared/widgets/          champs (téléphone, montant, mot de passe, date), états, liste paginée, montant/statut
└── features/
    ├── auth/                connexion, inscription, code WhatsApp, mot de passe, session
    ├── boutiques/           boutiques et boutique de travail (sélecteur)
    ├── dashboard/  clients/  dettes/  paiements/  rappels/  gerants/  entreprise/  compte/
```

- Riverpod pour l'état et l'injection : tous les repositories sont déclarés dans `lib/app/providers.dart`.
- Après chaque modification, `dataVersionProvider` est incrémenté : les écrans concernés se rechargent.
- Le domaine (modèles, `repartirVersement`) est en Dart pur ; la répartition d'un versement global reproduit
  exactement `PaiementService::repartir` (dettes ouvertes de la plus ancienne à la plus récente).
- Navigation : barre du bas sous 600 px, rail latéral au-delà (déplié au-delà de 1024 px), contenu limité à 960 px.

## Limites connues

- **Android 6.0 minimum** (minSdk 23), imposé par le stockage sécurisé des jetons.

- **Hors ligne** : l'application a besoin du réseau. Une saisie faite sans connexion échoue avec un message
  « Réessayer » ; il n'y a ni cache local ni file d'attente de synchronisation.
- **Rappels** : l'API n'a pas encore de routes pour les rappels. L'application prépare le message et ouvre
  WhatsApp ou les SMS, mais n'enregistre pas d'historique des rappels.
- **Logo** de l'entreprise : non modifiable depuis l'application (l'API l'accepte en multipart).
- Le changement de numéro principal et du nom se fait par le propriétaire (pour ses gérants) ou par l'administrateur.
