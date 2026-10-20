import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/providers.dart';
import '../../../core/api/api_exception.dart';
import '../../../app/theme.dart';
import '../../../core/utils/format.dart';
import '../../../shared/widgets/feedback.dart';
import '../../../shared/widgets/fields.dart';
import '../../../shared/widgets/montant.dart';
import '../../../shared/widgets/ui.dart';
import '../../auth/presentation/session_controller.dart';
import '../../boutiques/presentation/boutique_context.dart';
import '../../clients/domain/client.dart';

/// Nouvelle dette (achat à crédit) ou modification. Le montant d'une dette existante
/// n'est modifiable que par le propriétaire.
class DetteFormPage extends ConsumerStatefulWidget {
  const DetteFormPage({super.key, this.id, this.clientId});

  final int? id;

  /// Client présélectionné (depuis sa fiche)
  final int? clientId;

  @override
  ConsumerState<DetteFormPage> createState() => _DetteFormPageState();
}

class _DetteFormPageState extends ConsumerState<DetteFormPage> {
  final _form = GlobalKey<FormState>();
  final _montant = TextEditingController();
  final _note = TextEditingController();
  DateTime _dateCreation = DateTime.now();
  DateTime? _echeance;
  Client? _client;
  String? _clientNom;
  double _montantPaye = 0;
  bool _loading = false;
  bool _pending = false;
  ApiException? _error;

  bool get _edition => widget.id != null;

  @override
  void initState() {
    super.initState();
    if (_edition) {
      _loadDette();
    } else if (widget.clientId != null) {
      _loadClient(widget.clientId!);
    }
  }

  @override
  void dispose() {
    _montant.dispose();
    _note.dispose();
    super.dispose();
  }

  Future<void> _loadDette() async {
    setState(() => _loading = true);
    try {
      final d = await ref.read(detteRepositoryProvider).get(widget.id!);
      _montant.text = fcfa(d.montant, suffix: false);
      _note.text = d.note ?? '';
      _echeance = d.dateEcheance;
      _clientNom = d.client?.nom;
      _montantPaye = d.montantPaye;
    } catch (e) {
      if (mounted) showError(context, e);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _loadClient(int id) async {
    setState(() => _loading = true);
    try {
      final c = await ref.read(clientRepositoryProvider).get(id);
      if (mounted) setState(() => _client = c);
    } catch (e) {
      if (mounted) showError(context, e);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _choisirClient() async {
    final client = await showModalBottomSheet<Client>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (_) => const _ClientPicker(),
    );
    if (client != null) setState(() => _client = client);
  }

  Future<void> _submit() async {
    setState(() => _error = null);
    if (!_edition && _client == null) {
      showError(context, 'Choisissez le client.');
      return;
    }
    if (!_form.currentState!.validate()) return;
    setState(() => _pending = true);
    final repo = ref.read(detteRepositoryProvider);
    final isProprietaire = ref.read(profilProvider)?.isProprietaire ?? false;
    try {
      if (_edition) {
        await repo.update(
          widget.id!,
          montant: isProprietaire ? parseMontant(_montant.text) : null,
          dateEcheance: _echeance,
          note: _note.text,
        );
      } else {
        await repo.create(
          clientId: _client!.id,
          montant: parseMontant(_montant.text)!,
          dateCreation: _dateCreation,
          dateEcheance: _echeance,
          note: _note.text,
        );
      }
      ref.read(dataVersionProvider.notifier).bump();
      if (!mounted) return;
      showSuccess(context, _edition ? 'Dette modifiée.' : 'Dette enregistrée.');
      context.pop();
    } on ApiException catch (e) {
      if (mounted) setState(() => _error = e);
    } finally {
      if (mounted) setState(() => _pending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isProprietaire = ref.watch(profilProvider)?.isProprietaire ?? false;
    final montantModifiable = !_edition || isProprietaire;
    final error = _error;

    final aujourdhui = DateUtils.dateOnly(DateTime.now());

    return Scaffold(
      appBar: AppBar(
        title: Text(_edition ? 'Modifier la dette' : 'Nouvelle dette'),
      ),
      bottomNavigationBar:
          _loading
              ? null
              : BottomActionBar(
                child: FilledButton(
                  onPressed: _pending ? null : _submit,
                  child:
                      _pending
                          ? const ButtonSpinner()
                          : Text(
                            _edition
                                ? 'Enregistrer les modifications'
                                : 'Enregistrer la dette',
                          ),
                ),
              ),
      body:
          _loading
              ? const LoadingState()
              : Form(
                key: _form,
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(
                    Gap.page,
                    Gap.sm,
                    Gap.page,
                    Gap.xxl,
                  ),
                  keyboardDismissBehavior:
                      ScrollViewKeyboardDismissBehavior.onDrag,
                  children: [
                    ContentWidth(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          if (error != null && error.fieldErrors.isEmpty)
                            ErrorBanner(error.message),
                          FormSection(
                            title: 'Client',
                            icon: Icons.person_outline_rounded,
                            children: [
                              if (_edition)
                                AppCard(
                                  child: Row(
                                    children: [
                                      InitialsAvatar(_clientNom ?? ''),
                                      const SizedBox(width: Gap.md),
                                      Expanded(
                                        child: Text(
                                          _clientNom ?? '',
                                          style: context.text.bodyLarge
                                              ?.copyWith(
                                                fontWeight: FontWeight.w600,
                                              ),
                                        ),
                                      ),
                                    ],
                                  ),
                                )
                              else
                                _ClientChoisi(
                                  client: _client,
                                  onTap: _choisirClient,
                                ),
                            ],
                          ),
                          FormSection(
                            title: 'Montant',
                            icon: Icons.account_balance_wallet_outlined,
                            children: [
                              if (montantModifiable)
                                MontantField(
                                  controller: _montant,
                                  autofocus: !_edition && _client != null,
                                  errorText: error?.fieldError('montant'),
                                )
                              else
                                AppCard(
                                  child: Row(
                                    children: [
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            const Text('Montant'),
                                            Text(
                                              'Seul le propriétaire peut modifier le montant.',
                                              style: context.text.bodySmall,
                                            ),
                                          ],
                                        ),
                                      ),
                                      const SizedBox(width: Gap.md),
                                      MontantText(
                                        parseMontant(_montant.text) ?? 0,
                                        style: context.text.titleMedium,
                                      ),
                                    ],
                                  ),
                                ),
                              if (_edition &&
                                  isProprietaire &&
                                  _montantPaye > 0)
                                Padding(
                                  padding: const EdgeInsets.only(
                                    top: Gap.sm,
                                    left: Gap.xs,
                                  ),
                                  child: Text(
                                    'Minimum : ${fcfa(_montantPaye)} (déjà payé).',
                                    style: context.text.bodySmall,
                                  ),
                                ),
                            ],
                          ),
                          FormSection(
                            title: 'Dates',
                            icon: Icons.event_outlined,
                            children: [
                              if (!_edition) ...[
                                DateField(
                                  label: "Date de l'achat",
                                  value: _dateCreation,
                                  lastDate: DateTime.now(),
                                  onChanged:
                                      (d) => setState(
                                        () =>
                                            _dateCreation = d ?? DateTime.now(),
                                      ),
                                ),
                                fieldGap,
                              ],
                              DateField(
                                label: 'Échéance (facultatif)',
                                value: _echeance,
                                clearable: true,
                                firstDate: DateTime.now().subtract(
                                  const Duration(days: 365),
                                ),
                                onChanged: (d) => setState(() => _echeance = d),
                              ),
                              if (error?.fieldError('date_echeance') != null)
                                Padding(
                                  padding: const EdgeInsets.only(
                                    top: Gap.xs,
                                    left: Gap.lg,
                                  ),
                                  child: Text(
                                    error!.fieldError('date_echeance')!,
                                    style: context.text.bodySmall?.copyWith(
                                      color: context.scheme.error,
                                    ),
                                  ),
                                ),
                              const SizedBox(height: Gap.md),
                              Wrap(
                                spacing: Gap.sm,
                                runSpacing: Gap.sm,
                                children: [
                                  for (final jours in [7, 15, 30])
                                    ChoiceChip(
                                      label: Text('Dans $jours jours'),
                                      selected:
                                          _echeance != null &&
                                          DateUtils.isSameDay(
                                            _echeance,
                                            aujourdhui.add(
                                              Duration(days: jours),
                                            ),
                                          ),
                                      onSelected:
                                          (_) => setState(
                                            () =>
                                                _echeance = DateTime.now().add(
                                                  Duration(days: jours),
                                                ),
                                          ),
                                    ),
                                ],
                              ),
                            ],
                          ),
                          FormSection(
                            title: 'Détails',
                            icon: Icons.shopping_basket_outlined,
                            children: [
                              TextFormField(
                                controller: _note,
                                maxLines: 3,
                                textCapitalization:
                                    TextCapitalization.sentences,
                                decoration: const InputDecoration(
                                  labelText: 'Articles / note (facultatif)',
                                  hintText:
                                      'Ex. 2 sacs de riz, 1 bidon d\'huile',
                                  alignLabelWithHint: true,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
    );
  }
}

/// Carte du client de la dette : toucher pour le choisir ou le changer.
class _ClientChoisi extends StatelessWidget {
  const _ClientChoisi({required this.client, required this.onTap});

  final Client? client;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = client;
    final colors = context.colors;
    return AppCard(
      onTap: onTap,
      borderColor: c == null ? context.scheme.primary : null,
      child: Row(
        children: [
          if (c == null)
            const IconBadge(Icons.person_search_rounded, size: 44)
          else
            InitialsAvatar(c.nom),
          const SizedBox(width: Gap.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  c?.nom ?? 'Choisir le client',
                  style: context.text.bodyLarge?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: c == null ? context.scheme.primary : null,
                  ),
                ),
                if (c != null)
                  Text(
                    c.totalDu > 0 ? 'Doit déjà ${fcfa(c.totalDu)}' : 'À jour',
                    style: context.text.bodySmall?.copyWith(
                      color: c.totalDu > 0 ? colors.danger : colors.success,
                    ),
                  )
                else
                  Text(
                    'Rechercher ou ajouter un client',
                    style: context.text.bodySmall,
                  ),
              ],
            ),
          ),
          Icon(
            c == null ? Icons.chevron_right_rounded : Icons.swap_horiz_rounded,
            color: context.scheme.onSurfaceVariant,
          ),
        ],
      ),
    );
  }
}

/// Recherche et choix d'un client de la boutique courante.
class _ClientPicker extends ConsumerStatefulWidget {
  const _ClientPicker();

  @override
  ConsumerState<_ClientPicker> createState() => _ClientPickerState();
}

class _ClientPickerState extends ConsumerState<_ClientPicker> {
  Timer? _debounce;
  String _query = '';
  Future<List<Client>>? _results;

  @override
  void initState() {
    super.initState();
    _search();
  }

  @override
  void dispose() {
    _debounce?.cancel();
    super.dispose();
  }

  void _search() {
    _results = ref
        .read(clientRepositoryProvider)
        .list(boutiqueId: ref.read(boutiqueFiltreProvider), search: _query)
        .then((page) => page.items);
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: SizedBox(
        height: MediaQuery.sizeOf(context).height * 0.8,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(Gap.page, 0, Gap.page, Gap.sm),
              child: TextField(
                autofocus: true,
                decoration: const InputDecoration(
                  hintText: 'Rechercher un client',
                  prefixIcon: Icon(Icons.search_rounded),
                ),
                onChanged: (v) {
                  _debounce?.cancel();
                  _debounce = Timer(
                    const Duration(milliseconds: 300),
                    () => setState(() {
                      _query = v.trim();
                      _search();
                    }),
                  );
                },
              ),
            ),
            ListTile(
              leading: const IconBadge(Icons.person_add_alt_1_rounded),
              title: Text(
                'Nouveau client',
                style: TextStyle(color: context.scheme.primary),
              ),
              onTap: () {
                Navigator.pop(context);
                context.push('/clients/nouveau');
              },
            ),
            const Divider(height: 1),
            Expanded(
              child: FutureBuilder<List<Client>>(
                future: _results,
                builder: (context, snapshot) {
                  if (snapshot.hasError) {
                    return ErrorState(
                      error: snapshot.error!,
                      onRetry: () => setState(_search),
                    );
                  }
                  if (!snapshot.hasData) return const LoadingState();
                  final clients = snapshot.data!;
                  if (clients.isEmpty) {
                    return const EmptyState(
                      icon: Icons.person_search_rounded,
                      titre: 'Aucun client trouvé',
                    );
                  }
                  return ListView(
                    children: [
                      for (final c in clients)
                        ListTile(
                          leading: InitialsAvatar(c.nom, size: 40),
                          title: Text(c.nom),
                          subtitle: Text(
                            c.telephone == null
                                ? ''
                                : formatTelephone(c.telephone),
                          ),
                          trailing:
                              c.totalDu > 0
                                  ? MontantText(
                                    c.totalDu,
                                    color: context.colors.danger,
                                  )
                                  : null,
                          onTap: () => Navigator.pop(context, c),
                        ),
                    ],
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
