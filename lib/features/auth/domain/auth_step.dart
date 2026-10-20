import 'profil.dart';

/// Motif d'un code WhatsApp (OtpChallenge::purpose).
enum OtpPurpose {
  signup,
  firstLogin,
  phoneVerification,
  passwordReset;

  static OtpPurpose fromJson(Object? value) => switch (value) {
    'signup' => OtpPurpose.signup,
    'first_login' => OtpPurpose.firstLogin,
    'password_reset' => OtpPurpose.passwordReset,
    _ => OtpPurpose.phoneVerification,
  };
}

/// Code WhatsApp à saisir (`step = otp_required`).
class OtpChallenge {
  const OtpChallenge({
    required this.challengeToken,
    required this.purpose,
    this.phoneMasked,
    this.expiresIn = 300,
    this.resendIn = 60,
    this.resendsLeft = 3,
  });

  factory OtpChallenge.fromJson(Map<String, dynamic> json) => OtpChallenge(
    challengeToken: json['challenge_token'] as String,
    purpose: OtpPurpose.fromJson(json['purpose']),
    phoneMasked: json['phone_masked'] as String?,
    expiresIn: (json['expires_in'] as num?)?.toInt() ?? 300,
    resendIn: (json['resend_in'] as num?)?.toInt() ?? 60,
    resendsLeft: (json['resends_left'] as num?)?.toInt() ?? 3,
  );

  final String challengeToken;
  final OtpPurpose purpose;

  /// « 77 *** ** 67 »
  final String? phoneMasked;
  final int expiresIn;
  final int resendIn;
  final int resendsLeft;
}

/// Réponse d'une étape d'authentification.
sealed class AuthStep {
  const AuthStep();

  static AuthStep fromJson(Map<String, dynamic> json) => switch (json['step']) {
    'authenticated' => Authenticated(
      accessToken: json['access_token'] as String,
      refreshToken: json['refresh_token'] as String,
      profil: Profil.fromJson((json['user'] as Map).cast<String, dynamic>()),
    ),
    'set_password' => SetPasswordRequired(
      resetToken: json['reset_token'] as String,
      purpose: OtpPurpose.fromJson(json['purpose']),
    ),
    _ => OtpRequired(OtpChallenge.fromJson(json)),
  };
}

class Authenticated extends AuthStep {
  const Authenticated({
    required this.accessToken,
    required this.refreshToken,
    required this.profil,
  });
  final String accessToken;
  final String refreshToken;
  final Profil profil;
}

class OtpRequired extends AuthStep {
  const OtpRequired(this.challenge);
  final OtpChallenge challenge;
}

/// Code valide : choisir un mot de passe (première connexion, mot de passe oublié).
class SetPasswordRequired extends AuthStep {
  const SetPasswordRequired({required this.resetToken, required this.purpose});
  final String resetToken;
  final OtpPurpose purpose;
}
