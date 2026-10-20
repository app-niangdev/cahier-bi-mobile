import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../features/auth/presentation/session_controller.dart';
import '../shared/widgets/ui.dart';
import 'theme.dart';

class _Destination {
  const _Destination(this.branch, this.label, this.icon, this.selectedIcon);
  final int branch;
  final String label;
  final IconData icon;
  final IconData selectedIcon;
}

const _accueil = _Destination(
  0,
  'Accueil',
  Icons.space_dashboard_outlined,
  Icons.space_dashboard_rounded,
);
const _clients = _Destination(
  1,
  'Clients',
  Icons.people_outline_rounded,
  Icons.people_rounded,
);
const _dettes = _Destination(
  2,
  'Dettes',
  Icons.receipt_long_outlined,
  Icons.receipt_long_rounded,
);
const _gerants = _Destination(
  3,
  'Gérants',
  Icons.badge_outlined,
  Icons.badge_rounded,
);
const _compte = _Destination(
  4,
  'Compte',
  Icons.account_circle_outlined,
  Icons.account_circle_rounded,
);

/// Coque de l'espace connecté. Moins de 600 px : barre de navigation en bas ;
/// au-delà : rail latéral (déplié au-delà de 1024 px). Un gérant ne voit pas « Gérants ».
class AppShell extends ConsumerWidget {
  const AppShell({super.key, required this.shell});

  final StatefulNavigationShell shell;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isGerant = ref.watch(
      profilProvider.select((p) => p?.isGerant ?? false),
    );
    final destinations = [
      _accueil,
      _clients,
      _dettes,
      if (!isGerant) _gerants,
      _compte,
    ];
    final selected = destinations
        .indexWhere((d) => d.branch == shell.currentIndex)
        .clamp(0, destinations.length - 1);

    void go(int index) {
      final branch = destinations[index].branch;
      // Toucher l'onglet courant revient à sa première page
      shell.goBranch(branch, initialLocation: branch == shell.currentIndex);
    }

    final width = MediaQuery.sizeOf(context).width;
    if (width < 600) {
      return Scaffold(
        body: shell,
        bottomNavigationBar: DecoratedBox(
          decoration: BoxDecoration(
            border: Border(
              top: BorderSide(
                color: Theme.of(context).colorScheme.outlineVariant,
              ),
            ),
          ),
          child: NavigationBar(
            selectedIndex: selected,
            onDestinationSelected: go,
            destinations: [
              for (final d in destinations)
                NavigationDestination(
                  icon: Icon(d.icon),
                  selectedIcon: Icon(d.selectedIcon),
                  label: d.label,
                ),
            ],
          ),
        ),
      );
    }

    final extended = width >= 1024;
    return Scaffold(
      body: Row(
        children: [
          NavigationRail(
            extended: extended,
            labelType:
                extended
                    ? NavigationRailLabelType.none
                    : NavigationRailLabelType.all,
            selectedIndex: selected,
            onDestinationSelected: go,
            minExtendedWidth: 232,
            groupAlignment: -0.85,
            leading: Padding(
              padding: const EdgeInsets.fromLTRB(
                Gap.xs,
                Gap.lg,
                Gap.xs,
                Gap.xl,
              ),
              child: BrandMark(size: 40, showName: extended),
            ),
            destinations: [
              for (final d in destinations)
                NavigationRailDestination(
                  icon: Icon(d.icon),
                  selectedIcon: Icon(d.selectedIcon),
                  label: Text(d.label),
                ),
            ],
          ),
          VerticalDivider(
            width: 1,
            color: Theme.of(context).colorScheme.outlineVariant,
          ),
          // Contenu limité en largeur : l'interface mobile n'est pas étirée sur grand écran
          Expanded(
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: Widths.content),
                child: shell,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
