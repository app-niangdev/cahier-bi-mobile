import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../domain/auth_step.dart';
import 'auth_widgets.dart';
import 'session_controller.dart';

/// Suite d'une étape d'authentification : code WhatsApp, puis mot de passe, jusqu'à l'ouverture
/// de la session (le routeur redirige alors vers l'accueil).
class AuthStepFlow extends ConsumerStatefulWidget {
  const AuthStepFlow({
    super.key,
    required this.step,
    this.otpIntro,
    this.passwordIntro,
    this.passwordLabel = 'Enregistrer et me connecter',
  });

  final AuthStep step;
  final String? Function(OtpPurpose purpose)? otpIntro;
  final String? passwordIntro;
  final String passwordLabel;

  @override
  ConsumerState<AuthStepFlow> createState() => _AuthStepFlowState();
}

class _AuthStepFlowState extends ConsumerState<AuthStepFlow> {
  late AuthStep _step = widget.step;

  @override
  void initState() {
    super.initState();
    _open(_step);
  }

  void _next(AuthStep step) {
    _open(step);
    setState(() => _step = step);
  }

  void _open(AuthStep step) {
    if (step is Authenticated) {
      WidgetsBinding.instance.addPostFrameCallback(
        (_) => ref.read(sessionProvider.notifier).open(step),
      );
    }
  }

  @override
  Widget build(BuildContext context) => switch (_step) {
    OtpRequired(:final challenge) => OtpStepView(
      key: ValueKey(challenge.challengeToken),
      challenge: challenge,
      intro: widget.otpIntro?.call(challenge.purpose),
      onStep: _next,
    ),
    SetPasswordRequired(:final resetToken) => SetPasswordView(
      resetToken: resetToken,
      intro: widget.passwordIntro,
      submitLabel: widget.passwordLabel,
      onStep: _next,
    ),
    Authenticated() => const Center(
      child: Padding(
        padding: EdgeInsets.all(24),
        child: CircularProgressIndicator(),
      ),
    ),
  };
}

/// Texte d'introduction du code selon son motif.
String? otpIntroFor(OtpPurpose purpose) => switch (purpose) {
  OtpPurpose.firstLogin =>
    'Première connexion : confirmez votre numéro, puis choisissez votre mot de passe.',
  OtpPurpose.phoneVerification =>
    'Votre numéro a changé : confirmez-le pour continuer.',
  OtpPurpose.signup =>
    'Dernière étape : confirmez votre numéro WhatsApp pour activer votre compte.',
  OtpPurpose.passwordReset => null,
};
