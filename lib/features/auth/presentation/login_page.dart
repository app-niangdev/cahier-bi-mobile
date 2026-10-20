import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/providers.dart';
import '../../../core/api/api_exception.dart';
import '../../../app/theme.dart';
import '../../../shared/widgets/fields.dart';
import '../domain/auth_step.dart';
import 'auth_flow.dart';
import 'auth_widgets.dart';
import 'session_controller.dart';

/// Connexion du propriétaire ou du gérant : numéro WhatsApp et mot de passe.
class LoginPage extends ConsumerStatefulWidget {
  const LoginPage({super.key});

  @override
  ConsumerState<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends ConsumerState<LoginPage> {
  final _form = GlobalKey<FormState>();
  final _phone = TextEditingController();
  final _password = TextEditingController();
  bool _pending = false;
  String? _error;
  AuthStep? _step;

  @override
  void dispose() {
    _phone.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_form.currentState!.validate()) return;
    setState(() {
      _pending = true;
      _error = null;
    });
    try {
      final step = await ref
          .read(authRepositoryProvider)
          .login(_phone.text, _password.text);
      if (!mounted) return;
      if (step is Authenticated) {
        await ref.read(sessionProvider.notifier).open(step);
      } else {
        setState(() => _step = step);
      }
    } on ApiException catch (e) {
      if (!mounted) return;
      if (e.isAccessBlocked) {
        ref.read(sessionProvider.notifier).showBlocked(e);
      } else {
        setState(() => _error = e.message);
      }
    } finally {
      if (mounted) setState(() => _pending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final step = _step;
    if (step != null) {
      return AuthScaffold(
        title:
            step is SetPasswordRequired
                ? 'Choisissez votre mot de passe'
                : 'Confirmez votre numéro',
        onBack: () => setState(() => _step = null),
        child: AuthStepFlow(
          step: step,
          otpIntro: otpIntroFor,
          passwordIntro:
              'Numéro confirmé. Choisissez votre mot de passe personnel (8 caractères minimum).',
        ),
      );
    }

    // Message laissé par la session (ex. compte administrateur)
    final sessionError = ref.watch(sessionProvider.select((s) => s.error));

    return AuthScaffold(
      title: 'Connexion',
      subtitle: 'Suivez les dettes de vos clients, boutique par boutique.',
      child: AutofillGroup(
        child: Form(
          key: _form,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (_error != null || sessionError != null)
                ErrorBanner(_error ?? sessionError!.message),
              PhoneField(controller: _phone),
              const SizedBox(height: 16),
              PasswordField(
                controller: _password,
                onSubmitted: (_) => _submit(),
              ),
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: () => context.push('/mot-de-passe-oublie'),
                  child: const Text('Mot de passe oublié ?'),
                ),
              ),
              const SizedBox(height: Gap.sm),
              FilledButton(
                onPressed: _pending ? null : _submit,
                child:
                    _pending
                        ? const ButtonSpinner()
                        : const Text('Se connecter'),
              ),
              const SizedBox(height: Gap.xxl),
              const _Separateur('Nouveau sur Cahier Bi ?'),
              const SizedBox(height: Gap.lg),
              OutlinedButton.icon(
                onPressed: () => context.push('/inscription'),
                icon: const Icon(Icons.storefront_outlined),
                label: const Text('Créer mon compte gratuitement'),
              ),
              const SizedBox(height: Gap.xl),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    Icons.badge_outlined,
                    size: 18,
                    color: context.scheme.onSurfaceVariant,
                  ),
                  const SizedBox(width: Gap.sm),
                  Expanded(
                    child: Text(
                      'Gérant : connectez-vous avec le numéro et le mot de passe provisoire donnés par votre propriétaire.',
                      style: context.text.bodySmall,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Séparateur horizontal avec un libellé centré.
class _Separateur extends StatelessWidget {
  const _Separateur(this.label);
  final String label;

  @override
  Widget build(BuildContext context) => Row(
    children: [
      const Expanded(child: Divider()),
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: Gap.md),
        child: Text(label, style: context.text.bodySmall),
      ),
      const Expanded(child: Divider()),
    ],
  );
}
