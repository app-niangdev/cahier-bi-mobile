import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/providers.dart';
import '../../../app/theme.dart';
import '../../../core/api/api_exception.dart';
import '../../../shared/widgets/feedback.dart';
import '../../../shared/widgets/fields.dart';
import '../../../shared/widgets/ui.dart';
import '../domain/auth_step.dart';

export '../../../shared/widgets/ui.dart' show ButtonSpinner, ErrorBanner;

/// Cadre des écrans d'authentification : logo, titre, contenu centré et limité en largeur.
/// Sur grand écran (tablette, PWA), le contenu est présenté dans une carte.
class AuthScaffold extends StatelessWidget {
  const AuthScaffold({
    super.key,
    required this.title,
    this.subtitle,
    required this.child,
    this.onBack,
  });

  final String title;
  final String? subtitle;
  final Widget child;
  final VoidCallback? onBack;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final wide = MediaQuery.sizeOf(context).width >= 600;

    final content = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Center(child: BrandMark(size: 48)),
        const SizedBox(height: Gap.xxxl),
        Text(
          title,
          style: theme.textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.w800,
          ),
          textAlign: TextAlign.center,
        ),
        if (subtitle != null) ...[
          const SizedBox(height: Gap.sm),
          Text(
            subtitle!,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: scheme.onSurfaceVariant,
            ),
            textAlign: TextAlign.center,
          ),
        ],
        const SizedBox(height: Gap.xxl),
        AnimatedSwitcher(
          duration: Motion.medium,
          switchInCurve: Motion.curve,
          transitionBuilder:
              (child, animation) => FadeTransition(
                opacity: animation,
                child: SlideTransition(
                  position: Tween(
                    begin: const Offset(0, 0.04),
                    end: Offset.zero,
                  ).animate(animation),
                  child: child,
                ),
              ),
          child: KeyedSubtree(key: ValueKey(title), child: child),
        ),
      ],
    );

    return Scaffold(
      backgroundColor: wide ? scheme.surfaceContainer : scheme.surface,
      appBar:
          onBack == null
              ? null
              : AppBar(
                backgroundColor: Colors.transparent,
                leading: BackButton(onPressed: onBack),
              ),
      body: SafeArea(
        top: onBack == null,
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(Gap.xxl),
            keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
            child: ConstrainedBox(
              constraints: BoxConstraints(
                maxWidth: wide ? Widths.auth + 64 : Widths.auth,
              ),
              child:
                  wide
                      ? AppCard(
                        padding: const EdgeInsets.all(Gap.xxxl),
                        child: content,
                      )
                      : content,
            ),
          ),
        ),
      ),
    );
  }
}

/// Saisie du code à 6 chiffres reçu sur WhatsApp, avec renvoi et compte à rebours.
class OtpStepView extends ConsumerStatefulWidget {
  const OtpStepView({
    super.key,
    required this.challenge,
    required this.onStep,
    this.intro,
  });

  final OtpChallenge challenge;

  /// Étape suivante : session ouverte ou mot de passe à choisir.
  final ValueChanged<AuthStep> onStep;
  final String? intro;

  @override
  ConsumerState<OtpStepView> createState() => _OtpStepViewState();
}

class _OtpStepViewState extends ConsumerState<OtpStepView> {
  final _code = TextEditingController();
  late OtpChallenge _challenge = widget.challenge;
  late int _wait = _challenge.resendIn;
  Timer? _timer;
  bool _pending = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _startTimer();
  }

  void _startTimer() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (_wait <= 0) return t.cancel();
      setState(() => _wait--);
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _code.dispose();
    super.dispose();
  }

  Future<void> _verify() async {
    if (!RegExp(r'^\d{6}$').hasMatch(_code.text)) {
      setState(() => _error = 'Le code contient 6 chiffres.');
      return;
    }
    setState(() {
      _pending = true;
      _error = null;
    });
    try {
      final step = await ref
          .read(authRepositoryProvider)
          .verifyOtp(_challenge.challengeToken, _code.text);
      if (mounted) widget.onStep(step);
    } on ApiException catch (e) {
      if (mounted) setState(() => _error = e.message);
    } finally {
      if (mounted) setState(() => _pending = false);
    }
  }

  Future<void> _resend() async {
    setState(() {
      _pending = true;
      _error = null;
    });
    try {
      final challenge = await ref
          .read(authRepositoryProvider)
          .resendOtp(_challenge.challengeToken);
      if (!mounted) return;
      setState(() {
        _challenge = challenge;
        _wait = challenge.resendIn;
        _code.clear();
      });
      _startTimer();
      showSuccess(context, 'Un nouveau code vous a été envoyé sur WhatsApp.');
    } on ApiException catch (e) {
      if (mounted) setState(() => _error = e.message);
    } finally {
      if (mounted) setState(() => _pending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (_error != null) ErrorBanner(_error!),
        if (widget.intro != null) ...[
          InfoNote(widget.intro!, icon: Icons.verified_user_outlined),
          const SizedBox(height: Gap.lg),
        ],
        Text.rich(
          textAlign: TextAlign.center,
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
          TextSpan(
            children: [
              const TextSpan(
                text: 'Saisissez le code à 6 chiffres envoyé sur WhatsApp',
              ),
              if (_challenge.phoneMasked != null) ...[
                const TextSpan(text: ' au '),
                TextSpan(
                  text: '+221 ${_challenge.phoneMasked}',
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
              ],
              const TextSpan(text: '.'),
            ],
          ),
        ),
        const SizedBox(height: Gap.xl),
        TextField(
          controller: _code,
          autofocus: true,
          keyboardType: TextInputType.number,
          textAlign: TextAlign.center,
          maxLength: 6,
          autofillHints: const [AutofillHints.oneTimeCode],
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          style: theme.textTheme.headlineMedium?.copyWith(
            letterSpacing: 14,
            fontWeight: FontWeight.w800,
            fontFeatures: const [FontFeature.tabularFigures()],
          ),
          decoration: const InputDecoration(
            labelText: 'Code de vérification',
            hintText: '••••••',
            counterText: '',
            contentPadding: EdgeInsets.symmetric(vertical: 20),
          ),
          onChanged: (v) {
            if (v.length == 6 && !_pending) _verify();
          },
          onSubmitted: (_) => _verify(),
        ),
        const SizedBox(height: 16),
        FilledButton(
          onPressed: _pending ? null : _verify,
          child:
              _pending ? const ButtonSpinner() : const Text('Vérifier le code'),
        ),
        const SizedBox(height: 8),
        if (_challenge.resendsLeft > 0)
          TextButton(
            onPressed: _pending || _wait > 0 ? null : _resend,
            child: Text(
              _wait > 0 ? 'Renvoyer le code ($_wait s)' : 'Renvoyer le code',
            ),
          )
        else
          Text(
            'Nombre maximal de renvois atteint.',
            textAlign: TextAlign.center,
            style: theme.textTheme.bodySmall,
          ),
      ],
    );
  }
}

/// Choix d'un nouveau mot de passe après un code valide ; ouvre ensuite la session.
class SetPasswordView extends ConsumerStatefulWidget {
  const SetPasswordView({
    super.key,
    required this.resetToken,
    required this.onStep,
    this.intro,
    this.submitLabel = 'Enregistrer',
  });

  final String resetToken;
  final ValueChanged<AuthStep> onStep;
  final String? intro;
  final String submitLabel;

  @override
  ConsumerState<SetPasswordView> createState() => _SetPasswordViewState();
}

class _SetPasswordViewState extends ConsumerState<SetPasswordView> {
  final _form = GlobalKey<FormState>();
  final _password = TextEditingController();
  final _confirmation = TextEditingController();
  bool _pending = false;
  String? _error;

  @override
  void dispose() {
    _password.dispose();
    _confirmation.dispose();
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
          .setPassword(widget.resetToken, _password.text);
      if (mounted) widget.onStep(step);
    } on ApiException catch (e) {
      if (mounted) setState(() => _error = e.message);
    } finally {
      if (mounted) setState(() => _pending = false);
    }
  }

  @override
  Widget build(BuildContext context) => Form(
    key: _form,
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (_error != null) ErrorBanner(_error!),
        if (widget.intro != null) ...[
          InfoNote(widget.intro!, icon: Icons.check_circle_outline_rounded),
          const SizedBox(height: Gap.xl),
        ],
        PasswordField(
          controller: _password,
          label: 'Nouveau mot de passe',
          newPassword: true,
          validator: validateNewPassword,
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
          child: _pending ? const ButtonSpinner() : Text(widget.submitLabel),
        ),
      ],
    ),
  );
}
