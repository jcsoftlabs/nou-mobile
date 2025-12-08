import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class AuthInterceptor extends Interceptor {
  final FlutterSecureStorage _storage = const FlutterSecureStorage();
  final Function()? onUnauthorized;

  AuthInterceptor({this.onUnauthorized});

  @override
  Future<void> onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    // Ajouter automatiquement le token à toutes les requêtes
    final token = await _storage.read(key: 'access_token');
    
    if (token != null) {
      options.headers['Authorization'] = 'Bearer $token';
    }

    return handler.next(options);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) async {
    // Gérer les erreurs 401 (non autorisé)
    if (err.response?.statusCode == 401) {
      // Token expiré ou invalide
      await _storage.deleteAll();
      
      // Déclencher le callback de déconnexion
      if (onUnauthorized != null) {
        onUnauthorized!();
      }
    }

    return handler.next(err);
  }
}
