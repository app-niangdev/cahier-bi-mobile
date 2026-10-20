import 'dart:async';

import 'package:dio/dio.dart';

import '../storage/token_store.dart';
import 'api_exception.dart';

/// Page d'une liste paginée (`ApiResponse::paginated`).
class Paged<T> {
  const Paged({
    required this.items,
    required this.currentPage,
    required this.lastPage,
    required this.total,
  });

  final List<T> items;
  final int currentPage;
  final int lastPage;
  final int total;

  bool get hasMore => currentPage < lastPage;
}

/// Événements de session émis par la couche réseau.
sealed class SessionEvent {}

/// Jetons expirés et non renouvelables : retour à la connexion.
class SessionExpired extends SessionEvent {}

/// Accès coupé pendant la session (abonnement expiré, compte ou boutique désactivés).
class AccessBlocked extends SessionEvent {
  AccessBlocked(this.error);
  final ApiException error;
}

/// Routes où un 401 signifie « identifiants incorrects », pas « session expirée ».
final _authRoute = RegExp(
  r'^/?auth/(login|refresh|register|otp|password|forgot-password|reset-password)',
);

/// Client de l'API Laravel : enveloppe `{ status, message, payload }`, jeton Bearer,
/// renouvellement automatique du jeton et erreurs converties en [ApiException].
class ApiClient {
  ApiClient({required String baseUrl, required this.tokens, Dio? dio})
    : _dio = dio ?? Dio(_options(baseUrl)),
      _refreshDio = Dio(_options(baseUrl)) {
    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) {
          final token = tokens.accessToken;
          if (token != null) options.headers['Authorization'] = 'Bearer $token';
          handler.next(options);
        },
      ),
    );
  }

  static BaseOptions _options(String baseUrl) => BaseOptions(
    baseUrl: baseUrl,
    connectTimeout: const Duration(seconds: 15),
    receiveTimeout: const Duration(seconds: 30),
    headers: {'Accept': 'application/json'},
  );

  final TokenStore tokens;
  final Dio _dio;
  final Dio _refreshDio;
  final _events = StreamController<SessionEvent>.broadcast();
  Future<bool>? _refreshing;

  Stream<SessionEvent> get events => _events.stream;

  /// `payload` de la réponse.
  Future<dynamic> get(String path, {Map<String, dynamic>? query}) =>
      _send(() => _dio.get(path, queryParameters: _clean(query)), path);

  Future<dynamic> post(String path, [Object? body]) =>
      _send(() => _dio.post(path, data: body), path);

  Future<dynamic> put(String path, [Object? body]) =>
      _send(() => _dio.put(path, data: body), path);

  Future<dynamic> delete(String path) => _send(() => _dio.delete(path), path);

  /// Liste paginée : `payload` + `meta`.
  Future<Paged<T>> page<T>(
    String path,
    T Function(Map<String, dynamic>) fromJson, {
    Map<String, dynamic>? query,
  }) async {
    final body = await _sendRaw(
      () => _dio.get(path, queryParameters: _clean(query)),
      path,
    );
    final meta = (body['meta'] as Map?)?.cast<String, dynamic>() ?? const {};
    final items =
        (body['payload'] as List? ?? const [])
            .map((e) => fromJson((e as Map).cast<String, dynamic>()))
            .toList();
    return Paged(
      items: items,
      currentPage: (meta['current_page'] as num?)?.toInt() ?? 1,
      lastPage: (meta['last_page'] as num?)?.toInt() ?? 1,
      total: (meta['total'] as num?)?.toInt() ?? items.length,
    );
  }

  Future<dynamic> _send(
    Future<Response<dynamic>> Function() request,
    String path,
  ) async => (await _sendRaw(request, path))['payload'];

  Future<Map<String, dynamic>> _sendRaw(
    Future<Response<dynamic>> Function() request,
    String path,
  ) async {
    try {
      return _body(await request());
    } on DioException catch (e) {
      final status = e.response?.statusCode;
      final canRefresh =
          status == 401 &&
          !_authRoute.hasMatch(path) &&
          tokens.refreshToken != null;
      if (canRefresh && await _refresh()) {
        try {
          return _body(await request());
        } on DioException catch (retry) {
          throw _handle(retry, path);
        }
      }
      throw _handle(e, path);
    }
  }

  ApiException _handle(DioException e, String path) {
    final error = _toApiException(e);
    if (error.status == 401 && !_authRoute.hasMatch(path)) {
      _events.add(SessionExpired());
    } else if (error.isAccessBlocked && !_authRoute.hasMatch(path)) {
      _events.add(AccessBlocked(error));
    }
    return error;
  }

  /// Un seul renouvellement à la fois, partagé entre les requêtes en échec.
  Future<bool> _refresh() =>
      _refreshing ??= () async {
        try {
          final response = await _refreshDio.post(
            '/auth/refresh',
            options: Options(
              headers: {'Authorization': 'Bearer ${tokens.refreshToken}'},
            ),
          );
          final payload =
              (_body(response)['payload'] as Map).cast<String, dynamic>();
          await tokens.save(
            payload['access_token'] as String,
            payload['refresh_token'] as String,
          );
          return true;
        } catch (_) {
          await tokens.clear();
          return false;
        } finally {
          _refreshing = null;
        }
      }();

  static Map<String, dynamic> _body(Response<dynamic> response) {
    final data = response.data;
    if (data is Map) return data.cast<String, dynamic>();
    return {'payload': data};
  }

  static Map<String, dynamic>? _clean(Map<String, dynamic>? query) {
    if (query == null) return null;
    return {
      for (final entry in query.entries)
        if (entry.value != null && entry.value != '')
          entry.key:
              entry.value is bool ? (entry.value as bool ? 1 : 0) : entry.value,
    };
  }

  static ApiException _toApiException(DioException e) {
    final response = e.response;
    if (response == null) return ApiException.network;

    final data = response.data;
    if (data is! Map) {
      return ApiException(
        'Erreur du serveur (${response.statusCode}). Réessayez plus tard.',
        status: response.statusCode,
      );
    }

    final errors = <String, List<String>>{};
    final rawErrors = data['errors'];
    if (rawErrors is Map) {
      rawErrors.forEach((key, value) {
        if (value is List) {
          errors[key.toString()] = value.map((v) => v.toString()).toList();
        }
      });
    }
    final payload = data['payload'];

    return ApiException(
      (data['message'] as String?) ?? 'Une erreur est survenue.',
      code: data['error_code'] as String?,
      status: response.statusCode,
      fieldErrors: errors,
      payload: payload is Map ? payload.cast<String, dynamic>() : null,
    );
  }
}
