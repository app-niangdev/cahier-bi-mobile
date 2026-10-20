import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/providers.dart';
import '../../../core/api/api_exception.dart';
import '../../../core/utils/format.dart';
import '../../../shared/widgets/feedback.dart';
import '../../../app/theme.dart';
import '../../../shared/widgets/fields.dart';
import '../../../shared/widgets/ui.dart';
import '../../auth/presentation/session_controller.dart';

/// Informations de l'entreprise du propriétaire (`/manager/company`).
class EntreprisePage extends ConsumerStatefulWidget {
  const EntreprisePage({super.key});

  @override
  ConsumerState<EntreprisePage> createState() => _EntreprisePageState();
}

class _EntreprisePageState extends ConsumerState<EntreprisePage> {
  final _form = GlobalKey<FormState>();
  final _c = {
    for (final k in [
      'name',
      'short_name',
      'slogan',
      'trade',
      'address',
      'email',
      'phone_call',
      'phone_whatsapp',
      'ninea',
      'rccm',
    ])
      k: TextEditingController(),
  };
  bool _loading = true;
  bool _pending = false;
  Object? _loadError;
  ApiException? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    for (final c in _c.values) {
      c.dispose();
    }
    super.dispose();
  }

  String _phone(String? v) =>
      v == null ? '' : formatTelephone(v).replaceFirst('+221 ', '');

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _loadError = null;
    });
    try {
      final e = await ref.read(entrepriseRepositoryProvider).get();
      _c['name']!.text = e.name;
      _c['short_name']!.text = e.shortName ?? '';
      _c['slogan']!.text = e.slogan ?? '';
      _c['trade']!.text = e.trade ?? '';
      _c['address']!.text = e.address ?? '';
      _c['email']!.text = e.email ?? '';
      _c['phone_call']!.text = _phone(e.phoneCall);
      _c['phone_whatsapp']!.text = _phone(e.phoneWhatsapp);
      _c['ninea']!.text = e.ninea ?? '';
      _c['rccm']!.text = e.rccm ?? '';
    } catch (e) {
      _loadError = e;
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _submit() async {
    setState(() => _error = null);
    if (!_form.currentState!.validate()) return;
    setState(() => _pending = true);
    String? text(String k) =>
        _c[k]!.text.trim().isEmpty ? null : _c[k]!.text.trim();
    String? phone(String k) =>
        text(k) == null ? null : nationalNumber(text(k)) ?? text(k);
    try {
      await ref.read(entrepriseRepositoryProvider).update({
        'name': _c['name']!.text.trim(),
        'short_name': text('short_name'),
        'slogan': text('slogan'),
        'trade': text('trade'),
        'address': text('address'),
        'email': text('email'),
        'phone_call': phone('phone_call'),
        'phone_whatsapp': phone('phone_whatsapp'),
        'ninea': text('ninea'),
        'rccm': text('rccm'),
      });
      // Nom de l'entreprise affiché dans l'application
      final profil = await ref.read(authRepositoryProvider).me();
      ref.read(sessionProvider.notifier).updateProfil(profil);
      if (!mounted) return;
      showSuccess(context, 'Informations mises à jour.');
      context.pop();
    } on ApiException catch (e) {
      if (mounted) setState(() => _error = e);
    } finally {
      if (mounted) setState(() => _pending = false);
    }
  }

  Widget _field(
    String key,
    String label, {
    IconData? icon,
    TextInputType? keyboard,
    TextCapitalization capitalization = TextCapitalization.sentences,
    String? Function(String?)? validator,
    bool last = false,
  }) => Padding(
    padding: EdgeInsets.only(bottom: last ? 0 : Gap.lg),
    child: TextFormField(
      controller: _c[key],
      keyboardType: keyboard,
      textCapitalization: capitalization,
      textInputAction: TextInputAction.next,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: icon == null ? null : Icon(icon),
        errorText: _error?.fieldError(key),
      ),
      validator: validator,
    ),
  );

  @override
  Widget build(BuildContext context) {
    final error = _error;
    final pret = !_loading && _loadError == null;
    return Scaffold(
      appBar: AppBar(title: const Text('Mon entreprise')),
      bottomNavigationBar:
          pret
              ? BottomActionBar(
                child: FilledButton(
                  onPressed: _pending ? null : _submit,
                  child:
                      _pending
                          ? const ButtonSpinner()
                          : const Text('Enregistrer'),
                ),
              )
              : null,
      body:
          _loading
              ? const LoadingState()
              : _loadError != null
              ? ErrorState(error: _loadError!, onRetry: _load)
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
                            icon: Icons.storefront_outlined,
                            children: [
                              _field(
                                'name',
                                'Nom du commerce',
                                icon: Icons.store_outlined,
                                capitalization: TextCapitalization.words,
                                validator:
                                    (v) =>
                                        (v == null || v.trim().isEmpty)
                                            ? 'Le nom est obligatoire.'
                                            : null,
                              ),
                              _field(
                                'short_name',
                                'Nom court',
                                icon: Icons.short_text_rounded,
                              ),
                              _field(
                                'slogan',
                                'Slogan',
                                icon: Icons.format_quote_rounded,
                              ),
                              _field(
                                'trade',
                                'Activité',
                                icon: Icons.category_outlined,
                                last: true,
                              ),
                            ],
                          ),
                          FormSection(
                            title: 'Coordonnées',
                            icon: Icons.contact_phone_outlined,
                            children: [
                              _field(
                                'address',
                                'Adresse',
                                icon: Icons.place_outlined,
                              ),
                              _field(
                                'email',
                                'E-mail',
                                icon: Icons.alternate_email_rounded,
                                keyboard: TextInputType.emailAddress,
                                capitalization: TextCapitalization.none,
                              ),
                              PhoneField(
                                controller: _c['phone_whatsapp']!,
                                label: 'WhatsApp',
                                required: false,
                                errorText: error?.fieldError('phone_whatsapp'),
                              ),
                              fieldGap,
                              PhoneField(
                                controller: _c['phone_call']!,
                                label: 'Téléphone',
                                required: false,
                                errorText: error?.fieldError('phone_call'),
                              ),
                            ],
                          ),
                          FormSection(
                            title: 'Informations légales',
                            icon: Icons.gavel_rounded,
                            children: [
                              _field(
                                'ninea',
                                'NINEA',
                                icon: Icons.numbers_rounded,
                                capitalization: TextCapitalization.characters,
                              ),
                              _field(
                                'rccm',
                                'RCCM',
                                icon: Icons.description_outlined,
                                capitalization: TextCapitalization.characters,
                                last: true,
                              ),
                            ],
                          ),
                          const InfoNote(
                            'Vos boutiques sont créées par l\'administrateur de Cahier Bi : contactez-le pour en ouvrir une autre.',
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
