import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/providers.dart';
import '../../../core/api/api_exception.dart';
import '../../../shared/widgets/feedback.dart';
import '../../../app/theme.dart';
import '../../../shared/widgets/fields.dart';
import '../../../shared/widgets/ui.dart';

class PasswordPage extends ConsumerStatefulWidget {
  const PasswordPage({super.key});

  @override
  ConsumerState<PasswordPage> createState() => _PasswordPageState();
}

class _PasswordPageState extends ConsumerState<PasswordPage> {
  final _form = GlobalKey<FormState>();
  final _current = TextEditingController();
  final _password = TextEditingController();
  final _confirmation = TextEditingController();
  bool _pending = false;
  ApiException? _error;

  @override
  void dispose() {
    _current.dispose();
    _password.dispose();
    _confirmation.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    setState(() => _error = null);
    if (!_form.currentState!.validate()) return;
    setState(() => _pending = true);
    try {
      await ref
          .read(authRepositoryProvider)
          .changePassword(_current.text, _password.text);
      if (!mounted) return;
      showSuccess(context, 'Mot de passe modifié.');
      context.pop();
    } on ApiException catch (e) {
      if (mounted) setState(() => _error = e);
    } finally {
      if (mounted) setState(() => _pending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final error = _error;
    final currentError =
        error?.code == 'CURRENT_PASSWORD_INVALID'
            ? error!.message
            : error?.fieldError('current_password');
    return Scaffold(
      appBar: AppBar(title: const Text('Mot de passe')),
      bottomNavigationBar: BottomActionBar(
        child: FilledButton(
          onPressed: _pending ? null : _submit,
          child:
              _pending
                  ? const ButtonSpinner()
                  : const Text('Changer mon mot de passe'),
        ),
      ),
      body: Form(
        key: _form,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(
            Gap.page,
            Gap.sm,
            Gap.page,
            Gap.xxl,
          ),
          children: [
            ContentWidth(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (error != null &&
                      error.fieldErrors.isEmpty &&
                      error.code != 'CURRENT_PASSWORD_INVALID')
                    ErrorBanner(error.message),
                  FormSection(
                    title: 'Mot de passe actuel',
                    icon: Icons.lock_outline_rounded,
                    children: [
                      PasswordField(
                        controller: _current,
                        label: 'Mot de passe actuel',
                        errorText: currentError,
                      ),
                    ],
                  ),
                  FormSection(
                    title: 'Nouveau mot de passe',
                    icon: Icons.key_rounded,
                    description: 'Au moins 8 caractères.',
                    children: [
                      PasswordField(
                        controller: _password,
                        label: 'Nouveau mot de passe',
                        newPassword: true,
                        validator: validateNewPassword,
                        errorText: error?.fieldError('password'),
                      ),
                      fieldGap,
                      PasswordField(
                        controller: _confirmation,
                        label: 'Confirmer le nouveau mot de passe',
                        newPassword: true,
                        onSubmitted: (_) => _submit(),
                        validator:
                            (v) =>
                                v != _password.text
                                    ? 'Les deux mots de passe ne correspondent pas.'
                                    : null,
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
