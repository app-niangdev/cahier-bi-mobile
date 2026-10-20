import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/providers.dart';
import '../../../app/theme.dart';
import '../../../core/utils/format.dart';
import '../../../shared/widgets/feedback.dart';
import '../../../shared/widgets/montant.dart';
import '../../../shared/widgets/paged_list.dart';
import '../../../shared/widgets/ui.dart';
import '../../boutiques/presentation/boutique_context.dart';
import '../../boutiques/presentation/boutique_switcher.dart';
import '../domain/client.dart';

class ClientsPage extends ConsumerStatefulWidget {
  const ClientsPage({super.key});

  @override
  ConsumerState<ClientsPage> createState() => _ClientsPageState();
}

class _ClientsPageState extends ConsumerState<ClientsPage> {
  final _search = TextEditingController();
  Timer? _debounce;
  String _query = '';
  bool _debiteurs = false;

  @override
  void dispose() {
    _debounce?.cancel();
    _search.dispose();
    super.dispose();
  }

  void _onSearch(String value) {
    _debounce?.cancel();
    _debounce = Timer(
      const Duration(milliseconds: 350),
      () => setState(() => _query = value.trim()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final boutiqueId = ref.watch(boutiqueFiltreProvider);
    final version = ref.watch(dataVersionProvider);
    final repo = ref.watch(clientRepositoryProvider);

    return Scaffold(
      appBar: AppBar(title: const BoutiqueSwitcher(titre: 'Clients')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push('/clients/nouveau'),
        icon: const Icon(Icons.person_add_alt_1_rounded),
        label: const Text('Nouveau client'),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(Gap.page, Gap.xs, Gap.page, 0),
            child: TextField(
              controller: _search,
              onChanged: _onSearch,
              textInputAction: TextInputAction.search,
              decoration: InputDecoration(
                hintText: 'Rechercher par nom ou téléphone',
                prefixIcon: const Icon(Icons.search_rounded),
                contentPadding: const EdgeInsets.symmetric(vertical: 14),
                border: const OutlineInputBorder(
                  borderRadius: BorderRadius.all(Radius.circular(Radii.pill)),
                  borderSide: BorderSide.none,
                ),
                enabledBorder: const OutlineInputBorder(
                  borderRadius: BorderRadius.all(Radius.circular(Radii.pill)),
                  borderSide: BorderSide.none,
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: const BorderRadius.all(
                    Radius.circular(Radii.pill),
                  ),
                  borderSide: BorderSide(color: context.scheme.primary),
                ),
                fillColor: context.scheme.surfaceContainerHigh,
                suffixIcon:
                    _search.text.isEmpty
                        ? null
                        : IconButton(
                          tooltip: 'Effacer la recherche',
                          icon: const Icon(Icons.close_rounded),
                          onPressed: () {
                            _search.clear();
                            _onSearch('');
                          },
                        ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(
              Gap.page,
              Gap.md,
              Gap.page,
              Gap.xs,
            ),
            child: Row(
              children: [
                ChoiceChip(
                  label: const Text('Tous'),
                  selected: !_debiteurs,
                  onSelected: (_) => setState(() => _debiteurs = false),
                ),
                const SizedBox(width: Gap.sm),
                ChoiceChip(
                  avatar: Icon(
                    Icons.account_balance_wallet_outlined,
                    size: 18,
                    color:
                        _debiteurs
                            ? context.scheme.onPrimaryContainer
                            : context.scheme.onSurfaceVariant,
                  ),
                  label: const Text('Doivent encore'),
                  selected: _debiteurs,
                  onSelected: (_) => setState(() => _debiteurs = true),
                ),
              ],
            ),
          ),
          Expanded(
            child: PagedList<Client>(
              resetKey: (boutiqueId, _query, _debiteurs, version),
              fetch:
                  (page) => repo.list(
                    page: page,
                    boutiqueId: boutiqueId,
                    search: _query,
                    debiteurs: _debiteurs,
                  ),
              empty: EmptyState(
                icon:
                    _query.isEmpty
                        ? Icons.people_outline_rounded
                        : Icons.person_search_rounded,
                titre: _query.isEmpty ? 'Aucun client' : 'Aucun client trouvé',
                message:
                    _query.isEmpty
                        ? 'Ajoutez votre premier client pour noter ses achats à crédit.'
                        : 'Essayez un autre nom ou numéro.',
              ),
              padding: const EdgeInsets.only(bottom: Gap.fab),
              divider: const Divider(indent: 72, endIndent: Gap.page),
              itemBuilder: (context, client) => _ClientTile(client),
            ),
          ),
        ],
      ),
    );
  }
}

class _ClientTile extends StatelessWidget {
  const _ClientTile(this.client);
  final Client client;

  @override
  Widget build(BuildContext context) {
    final scheme = context.scheme;
    final colors = context.colors;
    return InkWell(
      onTap: () => context.push('/clients/${client.id}'),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: Gap.page,
          vertical: Gap.md,
        ),
        child: Row(
          children: [
            InitialsAvatar(client.nom),
            const SizedBox(width: Gap.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    client.nom,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: context.text.bodyLarge?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: Gap.xxs),
                  Text(
                    client.telephone == null
                        ? 'Sans téléphone'
                        : formatTelephone(client.telephone),
                    style: context.text.bodySmall,
                  ),
                ],
              ),
            ),
            const SizedBox(width: Gap.sm),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                if (client.totalDu > 0)
                  MontantText(client.totalDu, color: scheme.onSurface)
                else
                  Pill(
                    'À jour',
                    color: colors.success,
                    background: colors.successContainer,
                  ),
                if (client.dettesEnRetard > 0) ...[
                  const SizedBox(height: Gap.xs),
                  Pill(
                    '${client.dettesEnRetard} en retard',
                    color: colors.danger,
                    background: colors.dangerContainer,
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }
}
