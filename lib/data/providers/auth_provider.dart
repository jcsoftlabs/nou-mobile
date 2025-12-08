import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../../services/api_service.dart';
import '../../models/membre.dart';
import '../../models/register_request.dart';

class AuthProvider with ChangeNotifier {
  final ApiService _apiService = ApiService();
  final FlutterSecureStorage _storage = const FlutterSecureStorage();

  Membre? _currentMembre;
  String? _token;
  String? _refreshToken;
  bool _isAuthenticated = false;
  bool _isLoading = true; // true au départ pour le chargement initial

  Membre? get currentMembre => _currentMembre;
  bool get isAuthenticated => _isAuthenticated;
  bool get isLoading => _isLoading;
  String? get token => _token;

  // Clés de stockage
  static const String _keyToken = 'access_token';
  static const String _keyRefreshToken = 'refresh_token';
  static const String _keyMembreId = 'membre_id';
  static const String _keyCodeAdhesion = 'code_adhesion';

  AuthProvider() {
    _loadAuthState();
  }

  /// Charger l'état d'authentification au démarrage
  Future<void> _loadAuthState() async {
    _isLoading = true;
    notifyListeners();

    try {
      _token = await _storage.read(key: _keyToken);
      _refreshToken = await _storage.read(key: _keyRefreshToken);
      final membreIdStr = await _storage.read(key: _keyMembreId);

      if (_token != null && membreIdStr != null) {
        final membreId = int.tryParse(membreIdStr);
        if (membreId != null) {
          // Charger les données du membre
          final result = await _apiService.getMembreById(membreId);
          if (result['success']) {
            _currentMembre = result['data'];
            _isAuthenticated = true;
          } else {
            // Token invalide, nettoyer
            await _clearAuth();
          }
        }
      }
    } catch (e) {
      debugPrint('Erreur chargement auth: $e');
      await _clearAuth();
    }

    _isLoading = false;
    notifyListeners();
  }

  /// Connexion
  Future<Map<String, dynamic>> login(String email, String password) async {
    // Ne pas toucher à _isLoading ici pour éviter les redirections
    // lors d'un échec de connexion

    try {
      final response = await _apiService.login(email, password);

      if (response['success']) {
        // Extraire les données de la réponse
        final data = response['data'];
        _token = data['token'];
        _refreshToken = data['refresh_token'];
        
        // Le backend renvoie { membre, token, refresh_token }
        if (data['membre'] != null) {
          _currentMembre = Membre.fromJson(data['membre']);
          _isAuthenticated = true;

          // Sauvegarder dans SecureStorage
          await _storage.write(key: _keyToken, value: _token);
          await _storage.write(key: _keyRefreshToken, value: _refreshToken);
          await _storage.write(key: _keyMembreId, value: _currentMembre!.id.toString());
          await _storage.write(key: _keyCodeAdhesion, value: _currentMembre!.codeAdhesion);

          notifyListeners();
          
          return {'success': true, 'message': 'Connexion réussie'};
        }
      }

      // NE PAS appeler notifyListeners() en cas d'échec pour éviter
      // que le router force une redirection
      return {'success': false, 'message': response['message'] ?? 'Erreur de connexion'};
    } catch (e) {
      // NE PAS appeler notifyListeners() en cas d'erreur
      return {'success': false, 'message': 'Erreur: $e'};
    }
  }

  /// Inscription (ancienne méthode, sans auto-login)
  Future<Map<String, dynamic>> register(Map<String, dynamic> data) async {
    _isLoading = true;
    notifyListeners();

    try {
      final response = await _apiService.register(data);
      _isLoading = false;
      notifyListeners();
      return response;
    } catch (e) {
      _isLoading = false;
      notifyListeners();
      return {'success': false, 'message': 'Erreur: $e'};
    }
  }

  /// Inscription + connexion automatique (avec RegisterRequest)
  Future<Map<String, dynamic>> registerAndLogin(
    RegisterRequest request, {
    String? photoPath,
  }) async {
    _isLoading = true;
    notifyListeners();

    try {
      final response = await _apiService.register(
        request,
        photoPath: photoPath,
      );

      if (response['success'] == true) {
        final data = response['data'];

        _token = data['token'];
        _refreshToken = data['refresh_token'];

        // Le backend renvoie { membre, token, refresh_token }
        if (data['membre'] != null) {
          _currentMembre = Membre.fromJson(data['membre']);
          _isAuthenticated = true;

          // Sauvegarder dans SecureStorage
          await _storage.write(key: _keyToken, value: _token);
          await _storage.write(key: _keyRefreshToken, value: _refreshToken);
          await _storage.write(
              key: _keyMembreId, value: _currentMembre!.id.toString());
          await _storage.write(
              key: _keyCodeAdhesion, value: _currentMembre!.codeAdhesion);

          _isLoading = false;
          notifyListeners();

          return {'success': true, 'message': 'Inscription réussie'};
        }
      }

      _isLoading = false;
      notifyListeners();
      return {
        'success': false,
        'message': response['message'] ?? 'Erreur lors de l\'inscription',
      };
    } catch (e) {
      _isLoading = false;
      notifyListeners();
      return {'success': false, 'message': 'Erreur: $e'};
    }
  }

  /// Déconnexion
  Future<void> logout() async {
    await _clearAuth();
    notifyListeners();
  }

  /// Rafraîchir le token
  Future<bool> refreshAccessToken() async {
    if (_refreshToken == null) return false;

    try {
      // Appeler l'endpoint de refresh (à implémenter dans ApiService si nécessaire)
      // Pour l'instant, on retourne false si le refresh échoue
      return false;
    } catch (e) {
      debugPrint('Erreur refresh token: $e');
      return false;
    }
  }

  /// Nettoyer l'authentification
  Future<void> _clearAuth() async {
    _token = null;
    _refreshToken = null;
    _currentMembre = null;
    _isAuthenticated = false;

    await _storage.deleteAll();
  }

  /// Mettre à jour les infos du membre
  Future<void> updateMembre() async {
    if (_currentMembre == null) return;

    try {
      final result = await _apiService.getMembreById(_currentMembre!.id);
      if (result['success']) {
        _currentMembre = result['data'];
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Erreur mise à jour membre: $e');
    }
  }
}
