import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../features/auth/presentation/forgot_password_page.dart';
import '../features/auth/presentation/login_page.dart';
import '../features/auth/presentation/register_page.dart';
import '../features/auth/presentation/session_controller.dart';
import '../features/auth/presentation/splash_page.dart';
import '../features/clients/presentation/client_detail_page.dart';
import '../features/clients/presentation/client_form_page.dart';
import '../features/clients/presentation/clients_page.dart';
import '../features/compte/presentation/compte_page.dart';
import '../features/compte/presentation/password_page.dart';
import '../features/compte/presentation/profil_page.dart';
import '../features/dashboard/presentation/dashboard_page.dart';
import '../features/dettes/presentation/dette_detail_page.dart';
import '../features/dettes/presentation/dette_form_page.dart';
import '../features/dettes/presentation/dettes_page.dart';
import '../features/entreprise/presentation/abonnement_page.dart';
import '../features/entreprise/presentation/blocked_page.dart';
import '../features/entreprise/presentation/entreprise_page.dart';
import '../features/gerants/presentation/gerants_page.dart';
import 'shell.dart';

const _publicRoutes = {'/connexion', '/inscription', '/mot-de-passe-oublie'};

/// Pages réservées au propriétaire.
bool _proprietaireSeulement(String path) =>
    path.startsWith('/gerants') ||
    path.startsWith('/compte/entreprise') ||
    path.startsWith('/compte/abonnement');

/// Redirection selon l'état de la session et le rôle (testable sans routeur).
String? redirectFor(SessionState session, String path) {
  switch (session.status) {
    case SessionStatus.unknown:
    case SessionStatus.offline:
      return path == '/demarrage' ? null : '/demarrage';
    case SessionStatus.unauthenticated:
      return _publicRoutes.contains(path) ? null : '/connexion';
    case SessionStatus.blocked:
      return path == '/bloque' ? null : '/bloque';
    case SessionStatus.authenticated:
      if (_publicRoutes.contains(path) ||
          path == '/demarrage' ||
          path == '/bloque' ||
          path == '/') {
        return '/accueil';
      }
      if (session.profil?.isGerant == true && _proprietaireSeulement(path)) {
        return '/accueil';
      }
      return null;
  }
}

final routerProvider = Provider<GoRouter>((ref) {
  final refresh = _RouterRefresh();
  ref.listen(sessionProvider, (previous, next) {
    if (previous?.status != next.status ||
        previous?.profil?.role != next.profil?.role) {
      refresh.notify();
    }
  });
  ref.onDispose(refresh.dispose);

  return GoRouter(
    initialLocation: '/demarrage',
    refreshListenable: refresh,
    redirect:
        (context, state) =>
            redirectFor(ref.read(sessionProvider), state.uri.path),
    errorBuilder: (context, state) => const NotFoundPage(),
    routes: [
      GoRoute(path: '/', redirect: (_, __) => '/accueil'),
      GoRoute(path: '/demarrage', builder: (_, __) => const SplashPage()),
      GoRoute(path: '/connexion', builder: (_, __) => const LoginPage()),
      GoRoute(path: '/inscription', builder: (_, __) => const RegisterPage()),
      GoRoute(
        path: '/mot-de-passe-oublie',
        builder: (_, __) => const ForgotPasswordPage(),
      ),
      GoRoute(path: '/bloque', builder: (_, __) => const BlockedPage()),
      StatefulShellRoute.indexedStack(
        builder: (context, state, shell) => AppShell(shell: shell),
        branches: [
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/accueil',
                builder: (_, __) => const DashboardPage(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/clients',
                builder: (_, __) => const ClientsPage(),
                routes: [
                  GoRoute(
                    path: 'nouveau',
                    builder: (_, __) => const ClientFormPage(),
                  ),
                  GoRoute(
                    path: ':id',
                    builder:
                        (_, state) => ClientDetailPage(
                          id: int.parse(state.pathParameters['id']!),
                        ),
                    routes: [
                      GoRoute(
                        path: 'modifier',
                        builder:
                            (_, state) => ClientFormPage(
                              id: int.parse(state.pathParameters['id']!),
                            ),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/dettes',
                builder:
                    (_, state) =>
                        DettesPage(statut: state.uri.queryParameters['statut']),
                routes: [
                  GoRoute(
                    path: 'nouvelle',
                    builder:
                        (_, state) => DetteFormPage(
                          clientId: int.tryParse(
                            state.uri.queryParameters['client'] ?? '',
                          ),
                        ),
                  ),
                  GoRoute(
                    path: ':id',
                    builder:
                        (_, state) => DetteDetailPage(
                          id: int.parse(state.pathParameters['id']!),
                        ),
                    routes: [
                      GoRoute(
                        path: 'modifier',
                        builder:
                            (_, state) => DetteFormPage(
                              id: int.parse(state.pathParameters['id']!),
                            ),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/gerants',
                builder: (_, __) => const GerantsPage(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/compte',
                builder: (_, __) => const ComptePage(),
                routes: [
                  GoRoute(
                    path: 'profil',
                    builder: (_, __) => const ProfilPage(),
                  ),
                  GoRoute(
                    path: 'mot-de-passe',
                    builder: (_, __) => const PasswordPage(),
                  ),
                  GoRoute(
                    path: 'entreprise',
                    builder: (_, __) => const EntreprisePage(),
                  ),
                  GoRoute(
                    path: 'abonnement',
                    builder: (_, __) => const AbonnementPage(),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    ],
  );
});

class _RouterRefresh extends ChangeNotifier {
  void notify() => notifyListeners();
}

class NotFoundPage extends StatelessWidget {
  const NotFoundPage({super.key});

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(),
    body: Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.search_off, size: 64),
          const SizedBox(height: 12),
          Text(
            'Page introuvable',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 16),
          FilledButton(
            onPressed: () => context.go('/accueil'),
            child: const Text("Retour à l'accueil"),
          ),
        ],
      ),
    ),
  );
}
