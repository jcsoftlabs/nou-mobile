import 'package:dio/dio.dart';
import '../constants/api_constants.dart';
import '../models/register_request.dart';
import '../models/cotisation.dart';
import '../models/cotisation_status.dart';
import '../models/podcast.dart';
import '../models/formation.dart';
import '../models/referral.dart';
import '../models/membre.dart';
import '../models/don.dart';
import '../models/news_article.dart';
import '../models/annonce.dart';
import '../core/services/auth_interceptor.dart';

class ApiService {
  late final Dio _dio;

  ApiService() {
    _dio = Dio(
      BaseOptions(
        baseUrl: ApiConstants.baseUrl,
        connectTimeout: const Duration(milliseconds: ApiConstants.connectionTimeout),
        receiveTimeout: const Duration(milliseconds: ApiConstants.receiveTimeout),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      ),
    );

    // Intercepteur d'authentification
    _dio.interceptors.add(AuthInterceptor());
    
    // Intercepteur pour les logs en debug
    _dio.interceptors.add(
      LogInterceptor(
        requestBody: true,
        responseBody: true,
        error: true,
      ),
    );
  }

  /// Vérifier le NIN pour la récupération de mot de passe
  Future<Map<String, dynamic>> verifyNin(String nin) async {
    try {
      final response = await _dio.post(
        '/auth/verify-nin',
        data: {'nin': nin},
      );

      if (response.statusCode == 200) {
        return {
          'success': true,
          'data': response.data['data'],
        };
      } else {
        return {
          'success': false,
          'message': response.data['message'] ?? 'NIN non trouvé',
        };
      }
    } on DioException catch (e) {
      if (e.response != null) {
        return {
          'success': false,
          'message': e.response?.data['message'] ?? 'NIN non trouvé',
        };
      } else {
        return {
          'success': false,
          'message': 'Impossible de se connecter au serveur',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'Une erreur inattendue est survenue: $e',
      };
    }
  }

  /// Réinitialiser le mot de passe avec le NIN
  Future<Map<String, dynamic>> resetPassword(String nin, String newPassword) async {
    try {
      final response = await _dio.post(
        '/auth/reset-password',
        data: {
          'nin': nin,
          'new_password': newPassword,
        },
      );

      if (response.statusCode == 200) {
        return {
          'success': true,
          'message': response.data['message'] ?? 'Mot de passe réinitialisé avec succès',
        };
      } else {
        return {
          'success': false,
          'message': response.data['message'] ?? 'Erreur lors de la réinitialisation',
        };
      }
    } on DioException catch (e) {
      if (e.response != null) {
        return {
          'success': false,
          'message': e.response?.data['message'] ?? 'Erreur serveur',
        };
      } else {
        return {
          'success': false,
          'message': 'Impossible de se connecter au serveur',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'Une erreur inattendue est survenue: $e',
      };
    }
  }

  /// Connexion d'un membre
  Future<Map<String, dynamic>> login(String identifier, String password) async {
    try {
      final response = await _dio.post(
        ApiConstants.login,
        data: {
          'identifier': identifier,
          'password': password,
        },
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        return {
          'success': true,
          'data': response.data['data'] ?? response.data,
        };
      } else {
        return {
          'success': false,
          'message': response.data['message'] ?? 'Erreur de connexion',
        };
      }
    } on DioException catch (e) {
      if (e.response != null) {
        // Gérer les différents codes d'erreur
        final statusCode = e.response?.statusCode;
        String message;
        
        if (statusCode == 401 || statusCode == 400) {
          // Identifiants incorrects
          message = e.response?.data['message'] ?? 'Identifiant ou mot de passe incorrect';
        } else if (statusCode == 404) {
          message = 'Utilisateur non trouvé';
        } else {
          message = e.response?.data['message'] ?? 'Erreur de connexion';
        }
        
        return {
          'success': false,
          'message': message,
        };
      } else {
        return {
          'success': false,
          'message': 'Impossible de se connecter au serveur',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'Une erreur inattendue est survenue: $e',
      };
    }
  }

  /// Inscription d'un nouveau membre avec photo de profil
  Future<Map<String, dynamic>> register(dynamic request, {String? photoPath}) async {
    try {
      // Si une photo est fournie, utiliser FormData
      dynamic requestData;
      
      if (photoPath != null && photoPath.isNotEmpty) {
        final formData = FormData();
        
        // Ajouter tous les champs du formulaire
        final jsonData = request.toJson();
        jsonData.forEach((key, value) {
          if (value != null) {
            formData.fields.add(MapEntry(key, value.toString()));
          }
        });
        
        // Ajouter la photo
        String fileName = photoPath.split('/').last;
        formData.files.add(MapEntry(
          'photo_profil',
          await MultipartFile.fromFile(
            photoPath,
            filename: fileName,
          ),
        ));
        
        requestData = formData;
      } else {
        // Sans photo, envoyer du JSON classique
        requestData = request.toJson();
      }

      final response = await _dio.post(
        ApiConstants.register,
        data: requestData,
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        return {
          'success': true,
          // On aligne la structure de réponse sur /login : data contient
          // directement { membre, token, refresh_token }.
          'data': response.data['data'] ?? response.data,
        };
      } else {
        return {
          'success': false,
          'message': response.data['message'] ?? 'Une erreur est survenue',
        };
      }
    } on DioException catch (e) {
      if (e.response != null) {
        final statusCode = e.response?.statusCode;
        final responseData = e.response?.data;
        
        // Extraire le message d'erreur principal
        String message = responseData?['message'] ?? 'Erreur de connexion au serveur';
        
        // Extraire les erreurs de champs spécifiques si disponibles
        Map<String, dynamic>? fieldErrors;
        if (responseData != null && responseData['errors'] != null) {
          fieldErrors = Map<String, dynamic>.from(responseData['errors']);
        }
        
        // Différencier les types d'erreur selon le code HTTP
        String errorType = 'server';
        if (statusCode == 400) {
          errorType = 'validation';
          // Erreur de validation des données
          if (message == 'Erreur de connexion au serveur') {
            message = 'Les données fournies sont invalides';
          }
        } else if (statusCode == 409) {
          errorType = 'conflict';
          // Conflit (username ou email déjà pris)
          if (message == 'Erreur de connexion au serveur') {
            message = 'Ces informations sont déjà utilisées';
          }
        } else if (statusCode == 404) {
          errorType = 'not_found';
          // Code d'adhésion non trouvé
          if (message == 'Erreur de connexion au serveur') {
            message = 'Code d\'adhésion invalide';
          }
        } else if (statusCode != null && statusCode >= 500) {
          errorType = 'server';
          if (message == 'Erreur de connexion au serveur') {
            message = 'Erreur du serveur. Veuillez réessayer plus tard.';
          }
        }
        
        return {
          'success': false,
          'message': message,
          'errorType': errorType,
          'statusCode': statusCode,
          'fieldErrors': fieldErrors,
        };
      } else {
        // Erreur de connexion (timeout, pas de réseau, etc.)
        String message = 'Impossible de se connecter au serveur. Vérifiez votre connexion.';
        
        if (e.type == DioExceptionType.connectionTimeout || 
            e.type == DioExceptionType.receiveTimeout ||
            e.type == DioExceptionType.sendTimeout) {
          message = 'La connexion a expiré. Vérifiez votre connexion internet et réessayez.';
        }
        
        return {
          'success': false,
          'message': message,
          'errorType': 'network',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'Une erreur inattendue est survenue: $e',
        'errorType': 'unknown',
      };
    }
  }

  /// Vérifier si un code d'adhésion existe
  Future<Map<String, dynamic>> verifyCodeAdhesion(String code) async {
    try {
      final response = await _dio.get('/auth/verify-code/$code');
      
      if (response.statusCode == 200) {
        final exists = response.data['exists'] == true;
        return {
          'exists': exists,
          'message': exists 
              ? 'Code d\'adhésion valide' 
              : 'Code d\'adhésion invalide',
          'data': response.data['data'],
        };
      } else {
        return {
          'exists': false,
          'message': 'Impossible de vérifier le code',
        };
      }
    } on DioException catch (e) {
      if (e.response?.statusCode == 404) {
        return {
          'exists': false,
          'message': 'Code d\'adhésion invalide',
        };
      }
      return {
        'exists': false,
        'message': 'Erreur lors de la vérification du code',
      };
    } catch (e) {
      return {
        'exists': false,
        'message': 'Erreur lors de la vérification du code',
      };
    }
  }

  /// Vérifier la disponibilité d'un nom d'utilisateur
  Future<Map<String, dynamic>> checkUsernameAvailability(String username) async {
    try {
      final response = await _dio.get('/auth/check-username/$username');
      
      if (response.statusCode == 200) {
        return {
          'available': response.data['available'] ?? false,
          'message': response.data['message'] ?? '',
          'suggestions': response.data['suggestions'] ?? [],
        };
      } else {
        return {
          'available': false,
          'message': 'Erreur lors de la vérification',
        };
      }
    } on DioException catch (e) {
      return {
        'available': false,
        'message': 'Erreur lors de la vérification',
      };
    } catch (e) {
      return {
        'available': false,
        'message': 'Erreur lors de la vérification',
      };
    }
  }

  /// Vérifier la disponibilité d'un email
  Future<Map<String, dynamic>> checkEmailAvailability(String email) async {
    try {
      final response = await _dio.get('/auth/check-email/$email');
      
      if (response.statusCode == 200) {
        return {
          'available': response.data['available'] ?? false,
          'message': response.data['message'] ?? '',
        };
      } else {
        return {
          'available': false,
          'message': 'Erreur lors de la vérification',
        };
      }
    } on DioException catch (e) {
      return {
        'available': false,
        'message': 'Erreur lors de la vérification',
      };
    } catch (e) {
      return {
        'available': false,
        'message': 'Erreur lors de la vérification',
      };
    }
  }

  /// Vérifier la disponibilité d'un numéro de téléphone
  Future<Map<String, dynamic>> checkPhoneAvailability(String phone) async {
    try {
      final response = await _dio.get('/auth/check-phone/$phone');
      
      if (response.statusCode == 200) {
        return {
          'available': response.data['available'] ?? false,
          'message': response.data['message'] ?? '',
        };
      } else {
        return {
          'available': false,
          'message': 'Erreur lors de la vérification',
        };
      }
    } on DioException catch (e) {
      return {
        'available': false,
        'message': 'Erreur lors de la vérification',
      };
    } catch (e) {
      return {
        'available': false,
        'message': 'Erreur lors de la vérification',
      };
    }
  }

  /// Vérifier la disponibilité d'un NIN
  Future<Map<String, dynamic>> checkNinAvailability(String nin) async {
    try {
      final response = await _dio.get('/auth/check-nin/$nin');
      
      if (response.statusCode == 200) {
        return {
          'available': response.data['available'] ?? false,
          'message': response.data['message'] ?? '',
        };
      } else {
        return {
          'available': false,
          'message': 'Erreur lors de la vérification',
        };
      }
    } on DioException catch (e) {
      return {
        'available': false,
        'message': 'Erreur lors de la vérification',
      };
    } catch (e) {
      return {
        'available': false,
        'message': 'Erreur lors de la vérification',
      };
    }
  }

  /// Créer une cotisation avec upload de reçu
  Future<Map<String, dynamic>> createCotisation(CotisationRequest request) async {
    try {
      // Convertir le moyen de paiement vers les valeurs attendues par le backend
      String convertMoyenPaiement(String moyen) {
        if (moyen.toLowerCase().contains('moncash')) return 'moncash';
        if (moyen.toLowerCase().contains('esp') || moyen.toLowerCase().contains('cash')) return 'cash';
        return 'recu_upload'; // Pour virement, reçu uploadé, etc.
      }

      FormData formData = FormData.fromMap({
        'membre_id': request.membreId,
        'montant': request.montant,
        'moyen_paiement': convertMoyenPaiement(request.moyenPaiement),
      });

      // Ajouter le fichier reçu si présent
      if (request.recuPath != null) {
        String fileName = request.recuPath!.split('/').last;
        formData.files.add(MapEntry(
          'recu',
          await MultipartFile.fromFile(
            request.recuPath!,
            filename: fileName,
          ),
        ));
      }

      final response = await _dio.post(
        '/cotisations',
        data: formData,
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        return {
          'success': true,
          'data': response.data,
          'message': 'Cotisation enregistrée avec succès',
        };
      } else {
        return {
          'success': false,
          'message': response.data['message'] ?? 'Erreur lors de l\'enregistrement',
        };
      }
    } on DioException catch (e) {
      if (e.response != null) {
        return {
          'success': false,
          'message': e.response?.data['message'] ?? 'Erreur serveur',
        };
      } else {
        return {
          'success': false,
          'message': 'Impossible de se connecter au serveur',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'Erreur: $e',
      };
    }
  }

  /// Récupérer l'historique des cotisations d'un membre
  Future<Map<String, dynamic>> getCotisations(int membreId) async {
    try {
      final response = await _dio.get(
        '/cotisations',
        queryParameters: {'membre_id': membreId},
      );

      if (response.statusCode == 200) {
        List<Cotisation> cotisations = [];
        // Le backend renvoie data: { cotisations: [...] }
        if (response.data['data'] != null && response.data['data']['cotisations'] != null) {
          cotisations = (response.data['data']['cotisations'] as List)
              .map((json) => Cotisation.fromJson(json))
              .toList();
        }
        return {
          'success': true,
          'data': cotisations,
        };
      } else {
        return {
          'success': false,
          'message': 'Erreur lors de la récupération',
        };
      }
    } on DioException catch (e) {
      print('Erreur lors de la récupération des cotisations: ${e.message}');
      return {
        'success': false,
        'message': e.response?.data['message'] ?? 'Erreur serveur',
        'data': <Cotisation>[],
      };
    } catch (e) {
      print('Erreur inattendue getCotisations: $e');
      return {
        'success': false,
        'message': 'Erreur: $e',
        'data': <Cotisation>[],
      };
    }
  }

  /// Récupérer le statut de la dernière cotisation
  Future<Cotisation?> getLastCotisation(int membreId) async {
    try {
      final response = await _dio.get('/cotisations/last/$membreId');
      
      if (response.statusCode == 200 && response.data['data'] != null) {
        return Cotisation.fromJson(response.data['data']);
      }
      return null;
    } on DioException catch (e) {
      // 404 = aucune cotisation trouvée, ce n'est pas une erreur critique
      if (e.response?.statusCode == 404) {
        return null;
      }
      print('Erreur lors de la récupération de la dernière cotisation: ${e.message}');
      return null;
    } catch (e) {
      print('Erreur inattendue getLastCotisation: $e');
      return null;
    }
  }

  /// Récupérer le statut de cotisation annuelle (montant versé, restant, etc.)
  Future<CotisationStatus?> getCotisationStatus() async {
    try {
      final response = await _dio.get('/cotisations/mon-statut');
      
      if (response.statusCode == 200 && response.data['data'] != null) {
        return CotisationStatus.fromJson(response.data['data']);
      }
      return null;
    } on DioException catch (e) {
      print('Erreur lors de la récupération du statut de cotisation: ${e.message}');
      return null;
    } catch (e) {
      print('Erreur inattendue getCotisationStatus: $e');
      return null;
    }
  }

  /// Récupérer la liste des épisodes de podcast
  Future<Map<String, dynamic>> getPodcasts() async {
    try {
      final response = await _dio.get(ApiConstants.podcasts);

      if (response.statusCode == 200) {
        List<Podcast> podcasts = [];
        // Le backend renvoie data: { podcasts: [...], pagination: {...} }
        if (response.data['data'] != null && response.data['data']['podcasts'] != null) {
          podcasts = (response.data['data']['podcasts'] as List)
              .map((json) => Podcast.fromJson(json))
              .toList();
        }
        return {
          'success': true,
          'data': podcasts,
        };
      } else {
        return {
          'success': false,
          'message': 'Erreur lors de la récupération des podcasts',
        };
      }
    } on DioException catch (e) {
      if (e.response != null) {
        return {
          'success': false,
          'message': e.response?.data['message'] ?? 'Erreur serveur',
        };
      } else {
        return {
          'success': false,
          'message': 'Impossible de se connecter au serveur',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'Erreur: $e',
        'data': <Podcast>[],
      };
    }
  }

  /// Incrémenter le compteur d'écoutes d'un podcast
  Future<bool> incrementPodcastListens(int podcastId) async {
    try {
      final response = await _dio.post('${ApiConstants.podcasts}/$podcastId/listen');
      return response.statusCode == 200;
    } catch (e) {
      print('Erreur lors de l\'incrémentation des écoutes: $e');
      return false;
    }
  }

  /// Récupérer la liste des formations
  Future<Map<String, dynamic>> getFormations() async {
    try {
      final response = await _dio.get(ApiConstants.formations);

      if (response.statusCode == 200) {
        List<Formation> formations = [];
        if (response.data['data'] != null && response.data['data']['formations'] != null) {
          formations = (response.data['data']['formations'] as List)
              .map((json) => Formation.fromJson(json))
              .toList();
        }
        return {
          'success': true,
          'data': formations,
        };
      } else {
        return {
          'success': false,
          'message': 'Erreur lors de la récupération des formations',
        };
      }
    } on DioException catch (e) {
      if (e.response != null) {
        return {
          'success': false,
          'message': e.response?.data['message'] ?? 'Erreur serveur',
        };
      } else {
        return {
          'success': false,
          'message': 'Impossible de se connecter au serveur',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'Erreur: $e',
        'data': <Formation>[],
      };
    }
  }

  /// Récupérer le détail d'une formation avec ses modules et quiz
  Future<Map<String, dynamic>> getFormationById(int id) async {
    try {
      final response = await _dio.get('${ApiConstants.formations}/$id');

      if (response.statusCode == 200) {
        Formation? formation;
        if (response.data['data'] != null && response.data['data']['formation'] != null) {
          formation = Formation.fromJson(response.data['data']['formation']);
        }
        return {
          'success': true,
          'data': formation,
        };
      } else {
        return {
          'success': false,
          'message': 'Erreur lors de la récupération de la formation',
        };
      }
    } on DioException catch (e) {
      if (e.response != null) {
        return {
          'success': false,
          'message': e.response?.data['message'] ?? 'Erreur serveur',
        };
      } else {
        return {
          'success': false,
          'message': 'Impossible de se connecter au serveur',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'Erreur: $e',
      };
    }
  }

  /// Récupérer la liste des filleuls d'un parrain
  Future<Map<String, dynamic>> getReferrals(int parrainId) async {
    try {
      final response = await _dio.get('${ApiConstants.referrals}/$parrainId');

      if (response.statusCode == 200) {
        List<Referral> referrals = [];
        Map<String, dynamic>? statistiques;
        
        // Le backend renvoie data: { filleuls: [...], statistiques: {...} }
        if (response.data['data'] != null) {
          if (response.data['data']['filleuls'] != null) {
            final filleulsData = response.data['data']['filleuls'] as List;
            print('DEBUG: Nombre de filleuls brut du backend: ${filleulsData.length}');
            
            referrals = filleulsData
                .map((json) => Referral.fromJson(json))
                .toList();
            
            print('DEBUG: Nombre de filleuls après parsing: ${referrals.length}');
          }
          
          if (response.data['data']['statistiques'] != null) {
            statistiques = response.data['data']['statistiques'] as Map<String, dynamic>;
            print('DEBUG: Statistiques du backend: $statistiques');
          }
        }
        
        return {
          'success': true,
          'data': {
            'filleuls': referrals,
            'statistiques': statistiques,
          },
        };
      } else {
        return {
          'success': false,
          'message': 'Erreur lors de la récupération des filleuls',
        };
      }
    } on DioException catch (e) {
      if (e.response != null) {
        return {
          'success': false,
          'message': e.response?.data['message'] ?? 'Erreur serveur',
        };
      } else {
        return {
          'success': false,
          'message': 'Impossible de se connecter au serveur',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'Erreur: $e',
        'data': <Referral>[],
      };
    }
  }

  /// Récupérer l'historique des dons d'un membre
  Future<Map<String, dynamic>> getDonsByMembre(int membreId) async {
    try {
      final response = await _dio.get(
        '/api/dons/membre/$membreId',
        options: Options(
          headers: await _getAuthHeaders(),
        ),
      );

      if (response.statusCode == 200 && response.data['success'] == true) {
        return {
          'success': true,
          'data': response.data['data'],
        };
      } else {
        return {
          'success': false,
          'message': response.data['message'] ?? 'Erreur lors de la récupération des dons',
        };
      }
    } on DioException catch (e) {
      if (e.response != null) {
        return {
          'success': false,
          'message': e.response!.data['message'] ?? 'Erreur serveur',
        };
      } else {
        return {
          'success': false,
          'message': 'Erreur de connexion au serveur',
        };
      }
    } catch (e) {
      return {'success': false, 'message': 'Erreur: $e'};
    }
  }

  /// Récupérer les points cumulés d'un membre
  Future<Map<String, dynamic>> getPoints(int membreId) async {
    try {
      final response = await _dio.get('${ApiConstants.points}/$membreId');

      if (response.statusCode == 200) {
        // Le backend renvoie data: { points: { total: 30, parrainage: 30, ... } }
        int points = response.data['data']?['points']?['total'] ?? 0;
        return {
          'success': true,
          'data': points,
        };
      } else {
        return {
          'success': false,
          'message': 'Erreur lors de la récupération des points',
        };
      }
    } on DioException catch (e) {
      if (e.response != null) {
        return {
          'success': false,
          'message': e.response?.data['message'] ?? 'Erreur serveur',
        };
      } else {
        return {
          'success': false,
          'message': 'Impossible de se connecter au serveur',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'Erreur: $e',
        'data': 0,
      };
    }
  }

  /// Récupérer les informations complètes d'un membre
  Future<Map<String, dynamic>> getMembreById(int membreId) async {
    try {
      final response = await _dio.get('${ApiConstants.membres}/$membreId');

      if (response.statusCode == 200) {
        Membre? membre;
        if (response.data['data'] != null) {
          // Le backend renvoie directement data: {...} sans wrapper 'membre'
          membre = Membre.fromJson(response.data['data']);
        }
        return {
          'success': true,
          'data': membre,
        };
      } else {
        return {
          'success': false,
          'message': 'Erreur lors de la récupération du profil',
        };
      }
    } on DioException catch (e) {
      if (e.response != null) {
        return {
          'success': false,
          'message': e.response?.data['message'] ?? 'Erreur serveur',
        };
      } else {
        return {
          'success': false,
          'message': 'Impossible de se connecter au serveur',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'Erreur: $e',
      };
    }
  }

  /// Mettre à jour la photo de profil d'un membre
  Future<Map<String, dynamic>> updatePhotoProfile(int membreId, String photoPath) async {
    try {
      String fileName = photoPath.split('/').last;
      FormData formData = FormData.fromMap({
        'photo': await MultipartFile.fromFile(
          photoPath,
          filename: fileName,
        ),
      });

      // Utiliser /membres/me/photo au lieu de /membres/:id/photo
      final response = await _dio.post(
        '/membres/me/photo',
        data: formData,
      );

      if (response.statusCode == 200) {
        return {
          'success': true,
          'data': response.data['data'],
          'message': 'Photo de profil mise à jour avec succès',
        };
      } else {
        return {
          'success': false,
          'message': response.data['message'] ?? 'Erreur lors de la mise à jour',
        };
      }
    } on DioException catch (e) {
      if (e.response != null) {
        return {
          'success': false,
          'message': e.response?.data['message'] ?? 'Erreur serveur',
        };
      } else {
        return {
          'success': false,
          'message': 'Impossible de se connecter au serveur',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'Erreur: $e',
      };
    }
  }

  /// Créer un don avec upload de reçu optionnel
  Future<Map<String, dynamic>> createDon(DonRequest request, {String? recuPath}) async {
    try {
      final formData = FormData();
      
      // Ajouter les champs du formulaire
      formData.fields.add(MapEntry('montant', request.montant.toString()));
      if (request.description != null && request.description!.isNotEmpty) {
        formData.fields.add(MapEntry('description', request.description!));
      }
      
      // Ajouter le reçu si présent
      if (recuPath != null && recuPath.isNotEmpty) {
        String fileName = recuPath.split('/').last;
        formData.files.add(MapEntry(
          'recu',
          await MultipartFile.fromFile(
            recuPath,
            filename: fileName,
          ),
        ));
      }

      final response = await _dio.post(
        '/dons',
        data: formData,
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        return {
          'success': true,
          'data': response.data['data'],
          'message': response.data['message'] ?? 'Don enregistré avec succès',
        };
      } else {
        return {
          'success': false,
          'message': response.data['message'] ?? 'Erreur lors de l\'enregistrement du don',
        };
      }
    } on DioException catch (e) {
      if (e.response != null) {
        return {
          'success': false,
          'message': e.response?.data['message'] ?? 'Erreur serveur',
        };
      } else {
        return {
          'success': false,
          'message': 'Impossible de se connecter au serveur',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'Erreur: $e',
      };
    }
  }

  /// Récupérer tous les dons du membre connecté
  Future<Map<String, dynamic>> getMesDons() async {
    try {
      final response = await _dio.get('/dons/mes-dons');

      if (response.statusCode == 200) {
        List<Don> dons = [];
        if (response.data['data'] != null) {
          dons = (response.data['data'] as List)
              .map((json) => Don.fromJson(json))
              .toList();
        }
        return {
          'success': true,
          'data': dons,
        };
      } else {
        return {
          'success': false,
          'message': 'Erreur lors de la récupération des dons',
        };
      }
    } on DioException catch (e) {
      if (e.response != null) {
        return {
          'success': false,
          'message': e.response?.data['message'] ?? 'Erreur serveur',
        };
      } else {
        return {
          'success': false,
          'message': 'Impossible de se connecter au serveur',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'Erreur: $e',
        'data': <Don>[],
      };
    }
  }

  /// Récupérer un don spécifique par son ID
  Future<Map<String, dynamic>> getDonById(int donId) async {
    try {
      final response = await _dio.get('/dons/$donId');

      if (response.statusCode == 200) {
        Don? don;
        if (response.data['data'] != null) {
          don = Don.fromJson(response.data['data']);
        }
        return {
          'success': true,
          'data': don,
        };
      } else {
        return {
          'success': false,
          'message': 'Erreur lors de la récupération du don',
        };
      }
    } on DioException catch (e) {
      if (e.response != null) {
        return {
          'success': false,
          'message': e.response?.data['message'] ?? 'Erreur serveur',
        };
      } else {
        return {
          'success': false,
          'message': 'Impossible de se connecter au serveur',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'Erreur: $e',
      };
    }
  }

  /// Récupérer les informations du parrain via son code d'adhésion
  Future<Map<String, dynamic>> getParrainByCode(String codeParrain) async {
    try {
      final response = await _dio.get('/membres/by-code/$codeParrain');

      if (response.statusCode == 200) {
        Membre? parrain;
        if (response.data['data'] != null) {
          parrain = Membre.fromJson(response.data['data']);
        }
        return {
          'success': true,
          'data': parrain,
        };
      } else {
        return {
          'success': false,
          'message': 'Parrain non trouvé',
        };
      }
    } on DioException catch (e) {
      if (e.response != null) {
        return {
          'success': false,
          'message': e.response?.data['message'] ?? 'Erreur serveur',
        };
      } else {
        return {
          'success': false,
          'message': 'Impossible de se connecter au serveur',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'Erreur: $e',
      };
    }
  }

  /// Récupérer la liste des articles de news (publiés)
  Future<Map<String, dynamic>> getNews({
    int page = 1,
    int limit = 10,
    String? categorie,
    String? search,
  }) async {
    try {
      final response = await _dio.get(
        ApiConstants.news,
        queryParameters: {
          'page': page,
          'limit': limit,
          if (categorie != null && categorie.isNotEmpty) 'categorie': categorie,
          if (search != null && search.isNotEmpty) 'search': search,
        },
      );

      if (response.statusCode == 200) {
        List<NewsArticle> articles = [];
        if (response.data['data'] != null) {
          final list = response.data['data'] as List;
          articles = list.map((json) => NewsArticle.fromJson(json)).toList();
        }
        return {
          'success': true,
          'data': articles,
          'pagination': response.data['pagination'],
        };
      } else {
        return {
          'success': false,
          'message': response.data['message'] ?? 'Erreur lors de la récupération des news',
        };
      }
    } on DioException catch (e) {
      if (e.response != null) {
        return {
          'success': false,
          'message': e.response?.data['message'] ?? 'Erreur serveur',
        };
      } else {
        return {
          'success': false,
          'message': 'Impossible de se connecter au serveur',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'Erreur: $e',
        'data': <NewsArticle>[],
      };
    }
  }

  /// Récupérer le détail d'un article par slug ou id
  Future<Map<String, dynamic>> getNewsDetail(String slugOrId) async {
    try {
      final response = await _dio.get('${ApiConstants.news}/$slugOrId');

      if (response.statusCode == 200 && response.data['data'] != null) {
        final article = NewsArticle.fromJson(response.data['data']);
        return {
          'success': true,
          'data': article,
        };
      } else {
        return {
          'success': false,
          'message': response.data['message'] ?? "Article introuvable",
        };
      }
    } on DioException catch (e) {
      if (e.response != null) {
        return {
          'success': false,
          'message': e.response?.data['message'] ?? 'Erreur serveur',
        };
      } else {
        return {
          'success': false,
          'message': 'Impossible de se connecter au serveur',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'Erreur: $e',
      };
    }
  }

  /// Récupérer les annonces actives
  Future<Map<String, dynamic>> getAnnoncesActives() async {
    try {
      final response = await _dio.get(ApiConstants.annonces);

      if (response.statusCode == 200) {
        List<Annonce> annonces = [];
        if (response.data['data'] != null) {
          annonces = (response.data['data'] as List)
              .map((json) => Annonce.fromJson(json))
              .toList();
        }
        return {
          'success': true,
          'data': annonces,
        };
      } else {
        return {
          'success': false,
          'message': response.data['message'] ?? 'Erreur lors de la récupération des annonces',
        };
      }
    } on DioException catch (e) {
      if (e.response != null) {
        return {
          'success': false,
          'message': e.response?.data['message'] ?? 'Erreur serveur',
        };
      } else {
        return {
          'success': false,
          'message': 'Impossible de se connecter au serveur',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'Erreur: $e',
        'data': <Annonce>[],
      };
    }
  }
}
