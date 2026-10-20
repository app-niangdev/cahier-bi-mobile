import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/providers.dart';
import '../../../core/api/api_exception.dart';
import '../../../app/theme.dart';
import '../../../shared/widgets/fields.dart';
import '../../../shared/widgets/ui.dart';
import '../data/auth_repository.dart';
import '../domain/auth_step.dart';
import 'auth_flow.dart';
import 'auth_widgets.dart';

/// Inscription d'un propriétaire : son commerce devient son entreprise et sa première boutique,
/// avec le forfait gratuit. Le code WhatsApp confirme le numéro et ouvre la session.
class RegisterPage extends ConsumerStatefulWidget {
  const RegisterPage({super.key});

  @override
  ConsumerState<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends ConsumerState<RegisterPage> {
  final _form = GlobalKey<FormState>();
  final _firstName = TextEditingController();
  final _lastName = TextEditingController();
  final _company = TextEditingController();
  final _quartier = TextEditingController();
  final _phone = TextEditingController();
  final _password = TextEditingController();
  final _confirmation = TextEditingController();
  bool _pending = false;
  ApiException? _error;
  OtpChallenge? _challenge;

  @override
  void dispose() {
    for (final c in [
      _firstName,
      _lastName,
      _company,
      _quartier,
      _phone,
      _password,
      _confirmation,
    ]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _submit() async {
    setState(() => _error = null);
    if (!_form.currentState!.validate()) return;
    setState(() => _pending = true);
    try {
      final challenge = await ref
          .read(authRepositoryProvider)
          .register(
            RegisterPayload(
              firstName: _firstName.text,
              lastName: _lastName.text,
              companyName: _company.text,
              quartier: _quartier.text,
              phone: _phone.text,
              password: _password.text,
            ),
          );
      if (mounted) setState(() => _challenge = challenge);
    } on ApiException catch (e) {
      if (mounted) setState(() => _error = e);
    } finally {
      if (mounted) setState(() => _pending = false);
    }
  }

  String? _required(String? v, String message) =>
      (v == null || v.trim().length < 2) ? message : null;

  @override
  Widget build(BuildContext context) {
    final challenge = _challenge;
    if (challenge != null) {
      return AuthScaffold(
        title: 'Confirmez votre numéro',
        onBack: () => setState(() => _challenge = null),
        child: AuthStepFlow(
          step: OtpRequired(challenge),
          otpIntro: otpIntroFor,
        ),
      );
    }

    final error = _error;
    return AuthScaffold(
      title: 'Créer mon compte',
      subtitle:
          'Votre boutique est créée tout de suite, avec le forfait gratuit.',
      onBack: () => context.pop(),
      child: AutofillGroup(
        child: Form(
          key: _form,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (error != null && error.fieldErrors.isEmpty)
                ErrorBanner(error.message),
              const _Section(
                'Vous',
                Icons.person_outline_rounded,
                premier: true,
              ),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _firstName,
                      textCapitalization: TextCapitalization.words,
                      autofillHints: const [AutofillHints.givenName],
                      decoration: InputDecoration(
                        labelText: 'Prénom',
                        errorText: error?.fieldError('first_name'),
                      ),
                      validator: (v) => _required(v, 'Au moins 2 caractères.'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextFormField(
                      controller: _lastName,
                      textCapitalization: TextCapitalization.words,
                      autofillHints: const [AutofillHints.familyName],
                      decoration: InputDecoration(
                        labelText: 'Nom',
                        errorText: error?.fieldError('last_name'),
                      ),
                      validator: (v) => _required(v, 'Au moins 2 caractères.'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              PhoneField(
                controller: _phone,
                errorText: error?.fieldError('phone'),
                helper: 'Vous recevrez un code de confirmation sur WhatsApp.',
              ),
              const _Section('Votre boutique', Icons.storefront_outlined),
              TextFormField(
                controller: _company,
                textCapitalization: TextCapitalization.words,
                decoration: InputDecoration(
                  labelText: 'Nom du commerce',
                  prefixIcon: const Icon(Icons.store_outlined),
                  hintText: 'Ex. Alimentation Fall',
                  errorText: error?.fieldError('company_name'),
                ),
                validator:
                    (v) => _required(v, 'Le nom du commerce est obligatoire.'),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _quartier,
                textCapitalization: TextCapitalization.words,
                decoration: InputDecoration(
                  labelText: 'Quartier (facultatif)',
                  prefixIcon: const Icon(Icons.place_outlined),
                  hintText: 'Ex. Médina',
                  errorText: error?.fieldError('quartier'),
                ),
              ),
              const _Section('Votre mot de passe', Icons.lock_outline_rounded),
              PasswordField(
                controller: _password,
                newPassword: true,
                validator: validateNewPassword,
                errorText: error?.fieldError('password'),
              ),
              const SizedBox(height: 16),
              PasswordField(
                controller: _confirmation,
                label: 'Confirmer le mot de passe',
                newPassword: true,
                onSubmitted: (_) => _submit(),
                validator:
                    (v) =>
                        v != _password.text
                            ? 'Les deux mots de passe ne correspondent pas.'
                            : null,
              ),
              const SizedBox(height: 24),
              FilledButton(
                onPressed: _pending ? null : _submit,
                child:
                    _pending
                        ? const ButtonSpinner()
                        : const Text('Recevoir mon code WhatsApp'),
              ),
              const SizedBox(height: 8),
              TextButton(
                onPressed: () => context.pop(),
                child: const Text('Déjà inscrit ? Se connecter'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Section extends StatelessWidget {
  const _Section(this.title, this.icon, {this.premier = false});
  final String title;
  final IconData icon;
  final bool premier;

  @override
  Widget build(BuildContext context) => Padding(
    padding: EdgeInsets.only(top: premier ? 0 : Gap.xxl, bottom: Gap.md),
    child: Row(
      children: [
        IconBadge(icon, size: 28),
        const SizedBox(width: Gap.sm),
        Text(
          title,
          style: context.text.titleSmall?.copyWith(fontWeight: FontWeight.w700),
        ),
        const SizedBox(width: Gap.md),
        const Expanded(child: Divider()),
      ],
    ),
  );
}
