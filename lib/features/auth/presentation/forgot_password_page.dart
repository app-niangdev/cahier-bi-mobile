import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/providers.dart';
import '../../../core/api/api_exception.dart';
import '../../../shared/widgets/fields.dart';
import '../domain/auth_step.dart';
import 'auth_flow.dart';
import 'auth_widgets.dart';

/// Mot de passe oublié : code WhatsApp, puis nouveau mot de passe (la session s'ouvre ensuite).
class ForgotPasswordPage extends ConsumerStatefulWidget {
  const ForgotPasswordPage({super.key});

  @override
  ConsumerState<ForgotPasswordPage> createState() => _ForgotPasswordPageState();
}

class _ForgotPasswordPageState extends ConsumerState<ForgotPasswordPage> {
  final _form = GlobalKey<FormState>();
  final _phone = TextEditingController();
  bool _pending = false;
  String? _error;

  /// Aucun compte avec ce numéro : proposer l'inscription.
  bool _inconnu = false;
  OtpChallenge? _challenge;

  @override
  void dispose() {
    _phone.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_form.currentState!.validate()) return;
    setState(() {
      _pending = true;
      _error = null;
      _inconnu = false;
    });
    try {
      // Le serveur vérifie que le numéro correspond à un compte avant d'envoyer le code
      final challenge = await ref
          .read(authRepositoryProvider)
          .forgotPassword(_phone.text);
      if (mounted) setState(() => _challenge = challenge);
    } on ApiException catch (e) {
      if (mounted) {
        setState(() {
          _error = e.message;
          _inconnu = e.code == 'PHONE_NOT_FOUND';
        });
      }
    } catch (e) {
      if (mounted) setState(() => _error = errorMessage(e));
    } finally {
      if (mounted) setState(() => _pending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final challenge = _challenge;
    return AuthScaffold(
      title: 'Mot de passe oublié',
      subtitle:
          challenge == null
              ? 'Recevez un code sur WhatsApp pour choisir un nouveau mot de passe.'
              : null,
      onBack:
          () =>
              challenge == null
                  ? context.pop()
                  : setState(() => _challenge = null),
      child:
          challenge != null
              ? AuthStepFlow(
                step: OtpRequired(challenge),
                otpIntro:
                    (_) =>
                        'Compte trouvé : un code vient d\'être envoyé sur WhatsApp.',
                passwordIntro:
                    'Code vérifié. Choisissez votre nouveau mot de passe.',
                passwordLabel: 'Réinitialiser et me connecter',
              )
              : Form(
                key: _form,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    if (_error != null) ErrorBanner(_error!),
                    PhoneField(
                      controller: _phone,
                      label: 'Numéro WhatsApp du compte',
                      textInputAction: TextInputAction.done,
                      helper:
                          'Le numéro avec lequel vous vous connectez à Cahier Bi.',
                    ),
                    const SizedBox(height: 24),
                    FilledButton(
                      onPressed: _pending ? null : _submit,
                      child:
                          _pending
                              ? const ButtonSpinner()
                              : const Text('Recevoir le code'),
                    ),
                    if (_inconnu) ...[
                      const SizedBox(height: 12),
                      OutlinedButton.icon(
                        onPressed:
                            () => context.pushReplacement('/inscription'),
                        icon: const Icon(Icons.storefront_outlined),
                        label: const Text('Créer mon compte'),
                      ),
                    ],
                  ],
                ),
              ),
    );
  }
}
