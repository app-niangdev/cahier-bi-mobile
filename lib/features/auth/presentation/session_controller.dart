import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/providers.dart';
import '../../../core/api/api_client.dart';
import '../../../core/api/api_exception.dart';
import '../../../core/domain/enums.dart';
import '../domain/auth_step.dart';
import '../domain/profil.dart';

enum SessionStatus {
  /// Restauration de la session au démarrage
  unknown,

  /// Restauration impossible (serveur injoignable) : écran de démarrage avec « Réessayer »
  offline,
  unauthenticated,
  authenticated,

  /// Abonnement expiré, compte, entreprise ou boutique désactivés
  blocked,
}

class SessionState {
  const SessionState(this.status, {this.profil, this.error});

  final SessionStatus status;
  final Profil? profil;

  /// Raison du blocage ou de l'échec de restauration.
  final ApiException? error;
}

final sessionProvider = NotifierProvider<SessionController, SessionState>(
  SessionController.new,
);

/// Session de l'utilisateur connecté : propriétaire ou gérant.
class SessionController extends Notifier<SessionState> {
  @override
  SessionState build() {
    final api = ref.watch(apiClientProvider);
    final subscription = api.events.listen((event) {
      switch (event) {
        case SessionExpired():
          if (state.status == SessionStatus.authenticated) _close();
        case AccessBlocked(:final error):
          if (state.status == SessionStatus.authenticated) {
            state = SessionState(
              SessionStatus.blocked,
              profil: state.profil,
              error: error,
            );
          }
      }
    });
    ref.onDispose(subscription.cancel);
    Future.microtask(restore);
    return const SessionState(SessionStatus.unknown);
  }

  /// Rouvre la session mémorisée (`GET /auth/me`).
  Future<void> restore() async {
    final tokens = ref.read(tokenStoreProvider);
    await tokens.load();
    if (tokens.accessToken == null) {
      state = const SessionState(SessionStatus.unauthenticated);
      return;
    }
    state = SessionState(SessionStatus.unknown, profil: state.profil);
    try {
      final profil = await ref.read(authRepositoryProvider).me();
      state = _authenticated(profil);
    } on ApiException catch (e) {
      if (e.isAccessBlocked) {
        state = SessionState(
          SessionStatus.blocked,
          profil: state.profil,
          error: e,
        );
      } else if (e.status == 401) {
        await tokens.clear();
        state = const SessionState(SessionStatus.unauthenticated);
      } else {
        state = SessionState(SessionStatus.offline, error: e);
      }
    }
  }

  /// Étape d'authentification terminée : la session s'ouvre.
  Future<void> open(Authenticated step) async {
    await ref
        .read(tokenStoreProvider)
        .save(step.accessToken, step.refreshToken);
    state = _authenticated(step.profil);
  }

  /// Connexion refusée pour un abonnement expiré ou un compte désactivé : page dédiée.
  void showBlocked(ApiException error) =>
      state = SessionState(SessionStatus.blocked, error: error);

  void updateProfil(Profil profil) {
    if (state.status == SessionStatus.authenticated) {
      state = SessionState(SessionStatus.authenticated, profil: profil);
    }
  }

  Future<void> logout() async {
    final tokens = ref.read(tokenStoreProvider);
    if (tokens.accessToken != null) {
      try {
        await ref.read(authRepositoryProvider).logout();
      } catch (_) {
        // Jetons sans état : la suppression locale suffit
      }
    }
    await _close();
  }

  Future<void> _close() async {
    await ref.read(tokenStoreProvider).clear();
    state = const SessionState(SessionStatus.unauthenticated);
  }

  SessionState _authenticated(Profil profil) {
    // Application réservée au propriétaire et au gérant
    if (profil.role == Role.admin) {
      unawaited(ref.read(tokenStoreProvider).clear());
      return const SessionState(
        SessionStatus.unauthenticated,
        error: ApiException(
          "L'administrateur utilise l'espace web d'administration.",
        ),
      );
    }
    return SessionState(SessionStatus.authenticated, profil: profil);
  }
}

/// Profil de l'utilisateur connecté (null hors session).
final profilProvider = Provider<Profil?>(
  (ref) => ref.watch(sessionProvider).profil,
);
