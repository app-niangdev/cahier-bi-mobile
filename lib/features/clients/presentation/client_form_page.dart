import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/providers.dart';
import '../../../core/api/api_exception.dart';
import '../../../app/theme.dart';
import '../../../core/utils/format.dart';
import '../../../shared/widgets/feedback.dart';
import '../../../shared/widgets/fields.dart';
import '../../../shared/widgets/ui.dart';
import '../../auth/presentation/session_controller.dart';
import '../../boutiques/presentation/boutique_context.dart';
import '../domain/client.dart';

/// Création (`id` null) ou modification d'un client.
class ClientFormPage extends ConsumerStatefulWidget {
  const ClientFormPage({super.key, this.id});
  final int? id;

  @override
  ConsumerState<ClientFormPage> createState() => _ClientFormPageState();
}

class _ClientFormPageState extends ConsumerState<ClientFormPage> {
  final _form = GlobalKey<FormState>();
  final _nom = TextEditingController();
  final _telephone = TextEditingController();
  final _whatsapp = TextEditingController();
  final _adresse = TextEditingController();
  final _note = TextEditingController();
  int? _boutiqueId;
  bool _loading = false;
  bool _pending = false;
  ApiException? _error;

  bool get _edition => widget.id != null;

  @override
  void initState() {
    super.initState();
    _boutiqueId = ref.read(boutiqueFiltreProvider);
    if (_edition) _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final c = await ref.read(clientRepositoryProvider).get(widget.id!);
      _nom.text = c.nom;
      _telephone.text =
          c.telephone == null
              ? ''
              : formatTelephone(c.telephone).replaceFirst('+221 ', '');
      _whatsapp.text =
          c.whatsapp == null
              ? ''
              : formatTelephone(c.whatsapp).replaceFirst('+221 ', '');
      _adresse.text = c.adresse ?? '';
      _note.text = c.note ?? '';
    } catch (e) {
      if (mounted) showError(context, e);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  void dispose() {
    for (final c in [_nom, _telephone, _whatsapp, _adresse, _note]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _submit() async {
    setState(() => _error = null);
    if (!_form.currentState!.validate()) return;
    final profil = ref.read(profilProvider);
    final boutiques = ref.read(boutiquesProvider).value ?? const [];
    final boutiqueId =
        _boutiqueId ?? (boutiques.length == 1 ? boutiques.first.id : null);
    if (!_edition && profil?.isProprietaire == true && boutiqueId == null) {
      showError(context, 'Choisissez la boutique du client.');
      return;
    }
    setState(() => _pending = true);
    final payload = ClientPayload(
      nom: _nom.text,
      telephone: _telephone.text,
      whatsapp: _whatsapp.text,
      adresse: _adresse.text,
      note: _note.text,
      boutiqueId: profil?.isProprietaire == true ? boutiqueId : null,
    );
    try {
      final repo = ref.read(clientRepositoryProvider);
      final client =
          _edition
              ? await repo.update(widget.id!, payload)
              : await repo.create(payload);
      ref.read(dataVersionProvider.notifier).bump();
      if (!mounted) return;
      showSuccess(context, _edition ? 'Client modifié.' : 'Client ajouté.');
      if (_edition) {
        context.pop();
      } else {
        context.pushReplacement('/clients/${client.id}');
      }
    } on ApiException catch (e) {
      if (mounted) setState(() => _error = e);
    } finally {
      if (mounted) setState(() => _pending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final profil = ref.watch(profilProvider);
    final boutiques = ref.watch(boutiquesProvider).value ?? const [];
    final choisirBoutique =
        !_edition && profil?.isProprietaire == true && boutiques.length > 1;
    final error = _error;

    return Scaffold(
      appBar: AppBar(
        title: Text(_edition ? 'Modifier le client' : 'Nouveau client'),
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
                                : 'Ajouter le client',
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
                            title: 'Identité',
                            icon: Icons.person_outline_rounded,
                            children: [
                              if (choisirBoutique) ...[
                                DropdownButtonFormField<int>(
                                  value: _boutiqueId,
                                  borderRadius: Radii.mdAll,
                                  decoration: InputDecoration(
                                    labelText: 'Boutique',
                                    prefixIcon: const Icon(
                                      Icons.storefront_outlined,
                                    ),
                                    errorText: error?.fieldError('boutique_id'),
                                  ),
                                  items: [
                                    for (final b in boutiques)
                                      DropdownMenuItem(
                                        value: b.id,
                                        child: Text(b.nom),
                                      ),
                                  ],
                                  onChanged:
                                      (v) => setState(() => _boutiqueId = v),
                                  validator:
                                      (v) =>
                                          v == null
                                              ? 'Choisissez la boutique du client.'
                                              : null,
                                ),
                                fieldGap,
                              ],
                              TextFormField(
                                controller: _nom,
                                autofocus: !_edition,
                                textCapitalization: TextCapitalization.words,
                                textInputAction: TextInputAction.next,
                                decoration: InputDecoration(
                                  labelText: 'Nom du client',
                                  prefixIcon: const Icon(Icons.badge_outlined),
                                  errorText: error?.fieldError('nom'),
                                ),
                                validator:
                                    (v) =>
                                        (v == null || v.trim().length < 2)
                                            ? 'Au moins 2 caractères.'
                                            : null,
                              ),
                            ],
                          ),
                          FormSection(
                            title: 'Contact',
                            icon: Icons.call_outlined,
                            description:
                                'Le numéro sert à appeler le client et à lui envoyer des rappels.',
                            children: [
                              PhoneField(
                                controller: _telephone,
                                label: 'Téléphone',
                                required: false,
                                errorText: error?.fieldError('telephone'),
                              ),
                              fieldGap,
                              PhoneField(
                                controller: _whatsapp,
                                label: 'WhatsApp (si différent)',
                                required: false,
                                errorText: error?.fieldError('whatsapp'),
                              ),
                            ],
                          ),
                          FormSection(
                            title: 'Compléments',
                            icon: Icons.notes_rounded,
                            children: [
                              TextFormField(
                                controller: _adresse,
                                textCapitalization:
                                    TextCapitalization.sentences,
                                textInputAction: TextInputAction.next,
                                decoration: const InputDecoration(
                                  labelText: 'Adresse (facultatif)',
                                  prefixIcon: Icon(Icons.place_outlined),
                                ),
                              ),
                              fieldGap,
                              TextFormField(
                                controller: _note,
                                maxLines: 3,
                                textCapitalization:
                                    TextCapitalization.sentences,
                                decoration: const InputDecoration(
                                  labelText: 'Note (facultatif)',
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
