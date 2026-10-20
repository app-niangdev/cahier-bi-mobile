import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/providers.dart';
import '../../../core/api/api_exception.dart';
import '../../../app/theme.dart';
import '../../../core/utils/format.dart';
import '../../../shared/widgets/feedback.dart';
import '../../../shared/widgets/fields.dart';
import '../../../shared/widgets/ui.dart';
import '../../boutiques/domain/boutique.dart';
import '../../boutiques/presentation/boutique_context.dart';
import '../domain/gerant.dart';

final gerantsProvider = FutureProvider.autoDispose<List<Gerant>>((ref) {
  ref.watch(dataVersionProvider);
  return ref.read(gerantRepositoryProvider).list();
});

/// Gérants des boutiques du propriétaire, avec le quota de chaque boutique.
class GerantsPage extends ConsumerWidget {
  const GerantsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final gerants = ref.watch(gerantsProvider);
    final boutiques = ref.watch(boutiquesProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Gérants')),
      body: switch ((boutiques, gerants)) {
        (AsyncError(:final error), _) ||
        (_, AsyncError(:final error)) => ErrorState(
          error: error,
          onRetry: () {
            ref.invalidate(boutiquesProvider);
            ref.invalidate(gerantsProvider);
          },
        ),
        (AsyncData(value: final bs), AsyncData(value: final gs)) => RefreshIndicator(
          onRefresh: () async {
            ref.invalidate(boutiquesProvider);
            return ref.refresh(gerantsProvider.future);
          },
          child:
              bs.isEmpty
                  ? ListView(
                    padding: const EdgeInsets.only(top: 48),
                    children: const [
                      EmptyState(
                        icon: Icons.storefront_rounded,
                        titre: 'Aucune boutique',
                        message:
                            "Contactez l'administrateur pour créer votre boutique.",
                      ),
                    ],
                  )
                  : ListView(
                    padding: const EdgeInsets.fromLTRB(
                      Gap.page,
                      Gap.xs,
                      Gap.page,
                      Gap.xxxl,
                    ),
                    children: [
                      const InfoNote(
                        'Un gérant gère une seule boutique. Il se connecte avec son numéro et le mot de passe provisoire '
                        'que vous lui communiquez, puis confirme son numéro par un code WhatsApp.',
                        icon: Icons.lightbulb_outline_rounded,
                      ),
                      const SizedBox(height: Gap.xl),
                      for (final b in bs) ...[
                        _BoutiqueGerants(
                          boutique: b,
                          gerants:
                              gs.where((g) => g.boutiqueId == b.id).toList(),
                          boutiques: bs,
                        ),
                        const SizedBox(height: Gap.lg),
                      ],
                    ],
                  ),
        ),
        _ => const LoadingState(),
      },
    );
  }
}

class _BoutiqueGerants extends ConsumerWidget {
  const _BoutiqueGerants({
    required this.boutique,
    required this.gerants,
    required this.boutiques,
  });

  final Boutique boutique;
  final List<Gerant> gerants;
  final List<Boutique> boutiques;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final places = boutique.gerantsPlaces;
    final complet = places?.complet ?? false;

    final colors = context.colors;
    return AppCard(
      padding: EdgeInsets.zero,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(Gap.lg, Gap.lg, Gap.lg, Gap.md),
            child: Row(
              children: [
                const IconBadge(Icons.storefront_rounded),
                const SizedBox(width: Gap.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        boutique.nom,
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      if (boutique.lieu.isNotEmpty)
                        Text(boutique.lieu, style: theme.textTheme.bodySmall),
                    ],
                  ),
                ),
                if (places != null)
                  Tooltip(
                    message: 'Gérants utilisés / autorisés',
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: Gap.sm,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color:
                            complet
                                ? colors.dangerContainer
                                : theme.colorScheme.surfaceContainerHigh,
                        borderRadius: BorderRadius.circular(Radii.pill),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.badge_outlined,
                            size: 14,
                            color:
                                complet
                                    ? colors.danger
                                    : theme.colorScheme.onSurfaceVariant,
                          ),
                          const SizedBox(width: Gap.xs),
                          Text(
                            places.libelle,
                            style: theme.textTheme.labelMedium?.copyWith(
                              color:
                                  complet
                                      ? colors.danger
                                      : theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          ),
          const Divider(),
          for (final (i, g) in gerants.indexed) ...[
            if (i > 0) const Divider(indent: 72),
            _GerantTile(gerant: g, boutiques: boutiques),
          ],
          if (gerants.isEmpty)
            Padding(
              padding: const EdgeInsets.all(Gap.lg),
              child: Text(
                'Aucun gérant pour cette boutique.',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ),
          Padding(
            padding: const EdgeInsets.fromLTRB(Gap.lg, Gap.xs, Gap.lg, Gap.lg),
            child:
                complet
                    ? Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        InfoNote(
                          'Nombre maximal de gérants atteint pour votre forfait (${places!.max}).',
                          icon: Icons.block_rounded,
                          color: theme.colorScheme.onErrorContainer,
                          background: theme.colorScheme.errorContainer,
                        ),
                        const SizedBox(height: Gap.sm),
                        TextButton.icon(
                          onPressed: () => context.push('/compte/abonnement'),
                          icon: const Icon(Icons.workspace_premium_outlined),
                          label: const Text('Voir les forfaits'),
                        ),
                      ],
                    )
                    : OutlinedButton.icon(
                      onPressed:
                          () => _ouvrirFormulaire(
                            context,
                            ref,
                            boutique: boutique,
                          ),
                      icon: const Icon(Icons.person_add_alt_1_rounded),
                      label: const Text('Ajouter un gérant'),
                    ),
          ),
        ],
      ),
    );
  }
}

enum _Action { modifier, transferer, basculer, reinitialiser, supprimer }

class _GerantTile extends ConsumerWidget {
  const _GerantTile({required this.gerant, required this.boutiques});

  final Gerant gerant;
  final List<Boutique> boutiques;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final g = gerant;
    final colors = context.colors;
    PopupMenuItem<_Action> item(
      _Action value,
      IconData icon,
      String label, {
      bool danger = false,
    }) => PopupMenuItem(
      value: value,
      child: Row(
        children: [
          Icon(icon, size: 20, color: danger ? theme.colorScheme.error : null),
          const SizedBox(width: Gap.md),
          Text(
            label,
            style: danger ? TextStyle(color: theme.colorScheme.error) : null,
          ),
        ],
      ),
    );

    return Padding(
      padding: const EdgeInsets.fromLTRB(Gap.lg, Gap.md, Gap.xs, Gap.md),
      child: Row(
        children: [
          Opacity(
            opacity: g.status ? 1 : 0.5,
            child: InitialsAvatar(g.fullName),
          ),
          const SizedBox(width: Gap.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  g.fullName,
                  style: theme.textTheme.bodyLarge?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: g.status ? null : theme.colorScheme.outline,
                  ),
                ),
                Text(
                  formatTelephone(g.phoneOne),
                  style: theme.textTheme.bodySmall,
                ),
                if (!g.status || g.mustChangePassword) ...[
                  const SizedBox(height: Gap.xs),
                  Pill(
                    !g.status ? 'Désactivé' : 'Première connexion à faire',
                    color: !g.status ? colors.neutral : colors.warning,
                    background:
                        !g.status
                            ? colors.neutralContainer
                            : colors.warningContainer,
                  ),
                ],
              ],
            ),
          ),
          PopupMenuButton<_Action>(
            tooltip: 'Actions',
            icon: const Icon(Icons.more_vert_rounded),
            onSelected: (a) => _agir(context, ref, a),
            itemBuilder:
                (_) => [
                  item(_Action.modifier, Icons.edit_outlined, 'Modifier'),
                  if (boutiques.length > 1)
                    item(
                      _Action.transferer,
                      Icons.swap_horiz_rounded,
                      'Transférer',
                    ),
                  item(
                    _Action.basculer,
                    g.status
                        ? Icons.pause_circle_outline_rounded
                        : Icons.play_circle_outline_rounded,
                    g.status ? 'Désactiver' : 'Activer',
                  ),
                  item(
                    _Action.reinitialiser,
                    Icons.lock_reset_rounded,
                    "Réinitialiser l'accès",
                  ),
                  item(
                    _Action.supprimer,
                    Icons.delete_outline_rounded,
                    'Supprimer',
                    danger: true,
                  ),
                ],
          ),
        ],
      ),
    );
  }

  Future<void> _agir(
    BuildContext context,
    WidgetRef ref,
    _Action action,
  ) async {
    final repo = ref.read(gerantRepositoryProvider);
    final g = gerant;
    Future<void> run(Future<void> Function() call, String succes) async {
      try {
        await call();
        ref.read(dataVersionProvider.notifier).bump();
        if (context.mounted) showSuccess(context, succes);
      } catch (e) {
        if (context.mounted) showError(context, e);
      }
    }

    switch (action) {
      case _Action.modifier:
        await _ouvrirFormulaire(context, ref, gerant: g);
      case _Action.transferer:
        final cible = await showModalBottomSheet<Boutique>(
          context: context,
          showDragHandle: true,
          builder:
              (context) => SafeArea(
                child: ListView(
                  shrinkWrap: true,
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: Gap.xxl),
                      child: SheetHeader(
                        title: 'Transférer ${g.fullName}',
                        subtitle: 'Choisissez sa nouvelle boutique.',
                      ),
                    ),
                    for (final b in boutiques.where(
                      (b) => b.id != g.boutiqueId,
                    ))
                      ListTile(
                        leading: const IconBadge(
                          Icons.storefront_rounded,
                          size: 36,
                        ),
                        title: Text(b.nom),
                        subtitle:
                            b.gerantsPlaces == null
                                ? null
                                : Text('Gérants : ${b.gerantsPlaces!.libelle}'),
                        enabled: !(b.gerantsPlaces?.complet ?? false),
                        onTap: () => Navigator.pop(context, b),
                      ),
                  ],
                ),
              ),
        );
        if (cible != null) {
          await run(
            () => repo.transfer(g.id, cible.id),
            '${g.fullName} transféré vers ${cible.nom}.',
          );
        }
      case _Action.basculer:
        if (g.status &&
            !await confirmer(
              context,
              titre: 'Désactiver ${g.fullName} ?',
              message: 'Il ne pourra plus se connecter.',
              confirmer: 'Désactiver',
            )) {
          return;
        }
        await run(
          () => repo.toggleStatus(g.id),
          g.status ? 'Gérant désactivé.' : 'Gérant activé.',
        );
      case _Action.reinitialiser:
        if (!await confirmer(
          context,
          titre: "Réinitialiser l'accès de ${g.fullName} ?",
          message:
              'Un nouveau mot de passe provisoire remplace le sien. Il confirmera son numéro par WhatsApp à sa prochaine connexion.',
          confirmer: 'Réinitialiser',
          danger: false,
        )) {
          return;
        }
        try {
          final password = await repo.resetAccess(g.id);
          ref.read(dataVersionProvider.notifier).bump();
          if (context.mounted) {
            await _afficherMotDePasse(
              context,
              g.fullName,
              g.phoneOne,
              password,
            );
          }
        } catch (e) {
          if (context.mounted) showError(context, e);
        }
      case _Action.supprimer:
        if (!await confirmer(
          context,
          titre: 'Supprimer ${g.fullName} ?',
          message: 'Son compte est supprimé et sa place libérée.',
          confirmer: 'Supprimer',
        )) {
          return;
        }
        await run(() => repo.delete(g.id), 'Gérant supprimé.');
    }
  }
}

/// Ajout (avec [boutique]) ou modification (avec [gerant]).
Future<void> _ouvrirFormulaire(
  BuildContext context,
  WidgetRef ref, {
  Boutique? boutique,
  Gerant? gerant,
}) => showModalBottomSheet<void>(
  context: context,
  isScrollControlled: true,
  showDragHandle: true,
  builder: (_) => _GerantForm(boutique: boutique, gerant: gerant),
);

class _GerantForm extends ConsumerStatefulWidget {
  const _GerantForm({this.boutique, this.gerant});
  final Boutique? boutique;
  final Gerant? gerant;

  @override
  ConsumerState<_GerantForm> createState() => _GerantFormState();
}

class _GerantFormState extends ConsumerState<_GerantForm> {
  final _form = GlobalKey<FormState>();
  late final _firstName = TextEditingController(text: widget.gerant?.firstName);
  late final _lastName = TextEditingController(text: widget.gerant?.lastName);
  late final _phone = TextEditingController(
    text:
        widget.gerant == null
            ? ''
            : formatTelephone(
              widget.gerant!.phoneOne,
            ).replaceFirst('+221 ', ''),
  );
  bool _pending = false;
  ApiException? _error;

  @override
  void dispose() {
    _firstName.dispose();
    _lastName.dispose();
    _phone.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    setState(() => _error = null);
    if (!_form.currentState!.validate()) return;
    setState(() => _pending = true);
    final payload = GerantPayload(
      firstName: _firstName.text,
      lastName: _lastName.text,
      phoneOne: _phone.text,
      phoneTwo: widget.gerant?.phoneTwo,
      address: widget.gerant?.address,
    );
    final repo = ref.read(gerantRepositoryProvider);
    try {
      if (widget.gerant != null) {
        await repo.update(widget.gerant!.id, payload);
        ref.read(dataVersionProvider.notifier).bump();
        if (!mounted) return;
        Navigator.pop(context);
        showSuccess(context, 'Gérant modifié.');
      } else {
        final (gerant, password) = await repo.create(
          widget.boutique!.id,
          payload,
        );
        ref.read(dataVersionProvider.notifier).bump();
        if (!mounted) return;
        final navigator = Navigator.of(context);
        final parent = navigator.context;
        navigator.pop();
        await _afficherMotDePasse(
          parent,
          gerant.fullName,
          gerant.phoneOne,
          password,
        );
      }
    } on ApiException catch (e) {
      if (mounted) setState(() => _error = e);
    } finally {
      if (mounted) setState(() => _pending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final error = _error;
    final edition = widget.gerant != null;
    return SafeArea(
      child: Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.viewInsetsOf(context).bottom,
        ),
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(Gap.xxl, 0, Gap.xxl, Gap.xxl),
          child: Form(
            key: _form,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                SheetHeader(
                  leading: IconBadge(
                    edition
                        ? Icons.manage_accounts_outlined
                        : Icons.person_add_alt_1_rounded,
                    size: 48,
                  ),
                  title: edition ? 'Modifier le gérant' : 'Nouveau gérant',
                  subtitle: edition ? null : widget.boutique!.nom,
                ),
                if (error != null && error.fieldErrors.isEmpty)
                  ErrorBanner(error.message),
                TextFormField(
                  controller: _firstName,
                  autofocus: true,
                  textCapitalization: TextCapitalization.words,
                  textInputAction: TextInputAction.next,
                  decoration: InputDecoration(
                    labelText: 'Prénom',
                    prefixIcon: const Icon(Icons.person_outline_rounded),
                    errorText: error?.fieldError('first_name'),
                  ),
                  validator:
                      (v) =>
                          (v == null || v.trim().length < 2)
                              ? 'Au moins 2 caractères.'
                              : null,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _lastName,
                  textCapitalization: TextCapitalization.words,
                  textInputAction: TextInputAction.next,
                  decoration: InputDecoration(
                    labelText: 'Nom',
                    prefixIcon: const Icon(Icons.badge_outlined),
                    errorText: error?.fieldError('last_name'),
                  ),
                  validator:
                      (v) =>
                          (v == null || v.trim().length < 2)
                              ? 'Au moins 2 caractères.'
                              : null,
                ),
                const SizedBox(height: 16),
                PhoneField(
                  controller: _phone,
                  errorText: error?.fieldError('phone_one'),
                  helper:
                      edition
                          ? 'Un numéro modifié devra être confirmé par WhatsApp.'
                          : 'Il recevra ses codes de connexion sur WhatsApp.',
                  textInputAction: TextInputAction.done,
                ),
                const SizedBox(height: 24),
                FilledButton(
                  onPressed: _pending ? null : _submit,
                  child:
                      _pending
                          ? const ButtonSpinner()
                          : Text(edition ? 'Enregistrer' : 'Créer le compte'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Mot de passe provisoire à communiquer au gérant (affiché une seule fois).
Future<void> _afficherMotDePasse(
  BuildContext context,
  String nom,
  String telephone,
  String password,
) => showDialog<void>(
  context: context,
  barrierDismissible: false,
  builder:
      (context) => AlertDialog(
        icon: const IconBadge(Icons.key_rounded, size: 48),
        title: const Text(
          'Mot de passe provisoire',
          textAlign: TextAlign.center,
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Communiquez à $nom (${formatTelephone(telephone)}) ce mot de passe. Il le remplacera à sa première connexion.',
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: Gap.xl),
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: Gap.lg,
                vertical: Gap.lg,
              ),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surfaceContainer,
                borderRadius: Radii.mdAll,
                border: Border.all(
                  color: Theme.of(context).colorScheme.outlineVariant,
                ),
              ),
              child: SelectableText(
                password,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontFamily: 'monospace',
                  fontWeight: FontWeight.w700,
                  letterSpacing: 2,
                ),
              ),
            ),
            const SizedBox(height: Gap.sm),
            Text(
              'Il ne sera plus affiché ensuite.',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ),
        actionsPadding: const EdgeInsets.fromLTRB(Gap.xxl, 0, Gap.xxl, Gap.xxl),
        actions: [
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () async {
                    await Clipboard.setData(ClipboardData(text: password));
                    if (context.mounted) {
                      showSuccess(context, 'Mot de passe copié.');
                    }
                  },
                  icon: const Icon(Icons.copy_rounded),
                  label: const Text('Copier'),
                ),
              ),
              const SizedBox(width: Gap.md),
              Expanded(
                child: FilledButton(
                  onPressed: () => Navigator.pop(context),
                  style: FilledButton.styleFrom(minimumSize: const Size(0, 50)),
                  child: const Text("J'ai noté"),
                ),
              ),
            ],
          ),
        ],
      ),
);
