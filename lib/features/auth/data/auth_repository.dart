import '../../../core/api/api_client.dart';
import '../../../core/utils/format.dart';
import '../domain/auth_step.dart';
import '../domain/profil.dart';

/// Inscription d'un propriétaire : son commerce devient son entreprise et sa première boutique.
class RegisterPayload {
  const RegisterPayload({
    required this.firstName,
    required this.lastName,
    required this.companyName,
    required this.phone,
    required this.password,
    this.trade,
    this.quartier,
    this.ville,
  });

  final String firstName;
  final String lastName;
  final String companyName;
  final String phone;
  final String password;
  final String? trade;
  final String? quartier;
  final String? ville;
}

/// `/api/auth/*`
class AuthRepository {
  AuthRepository(this._api);
  final ApiClient _api;

  Future<AuthStep> login(String phone, String password) async =>
      AuthStep.fromJson(
        await _api.post('/auth/login', {
          'phone': nationalNumber(phone) ?? phone,
          'password': password,
        }),
      );

  Future<OtpChallenge> register(RegisterPayload p) async =>
      OtpChallenge.fromJson(
        await _api.post('/auth/register', {
          'first_name': p.firstName.trim(),
          'last_name': p.lastName.trim(),
          'company_name': p.companyName.trim(),
          'trade': p.trade?.trim(),
          'quartier': p.quartier?.trim(),
          'ville': p.ville?.trim(),
          'phone': nationalNumber(p.phone) ?? p.phone,
          'password': p.password,
          'password_confirmation': p.password,
        }),
      );

  Future<AuthStep> verifyOtp(String challengeToken, String code) async =>
      AuthStep.fromJson(
        await _api.post('/auth/otp/verify', {
          'challenge_token': challengeToken,
          'code': code,
        }),
      );

  Future<OtpChallenge> resendOtp(String challengeToken) async =>
      OtpChallenge.fromJson(
        await _api.post('/auth/otp/resend', {
          'challenge_token': challengeToken,
        }),
      );

  Future<AuthStep> setPassword(String resetToken, String password) async =>
      AuthStep.fromJson(
        await _api.post('/auth/password/set', {
          'reset_token': resetToken,
          'password': password,
          'password_confirmation': password,
        }),
      );

  Future<OtpChallenge> forgotPassword(String phone) async =>
      OtpChallenge.fromJson(
        await _api.post('/auth/forgot-password', {
          'phone': nationalNumber(phone) ?? phone,
        }),
      );

  Future<Profil> me() async => Profil.fromJson(
    (await _api.get('/auth/me') as Map).cast<String, dynamic>(),
  );

  /// Téléphone secondaire et adresse (nom et numéro principal : gérés par le propriétaire / l'admin).
  Future<Profil> updateMe({String? phoneTwo, String? address}) async =>
      Profil.fromJson(
        (await _api.put('/auth/me', {
                  'phone_two':
                      phoneTwo == null || phoneTwo.isEmpty
                          ? null
                          : nationalNumber(phoneTwo) ?? phoneTwo,
                  'address':
                      address == null || address.trim().isEmpty
                          ? null
                          : address.trim(),
                })
                as Map)
            .cast<String, dynamic>(),
      );

  Future<void> changePassword(String current, String password) =>
      _api.put('/auth/me', {
        'current_password': current,
        'password': password,
        'password_confirmation': password,
      });

  Future<void> logout() => _api.post('/auth/logout');
}
