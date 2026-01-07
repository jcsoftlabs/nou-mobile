import 'package:dio/dio.dart';
import '../constants/api_constants.dart';

class PaymentService {
  final Dio _dio;

  PaymentService() : _dio = Dio(BaseOptions(
    baseUrl: ApiConstants.baseUrl,
    connectTimeout: const Duration(seconds: 30),
    receiveTimeout: const Duration(seconds: 30),
  ));

  /// Initier un paiement (cotisation ou don)
  Future<Map<String, dynamic>> initiatePayment({
    required String token,
    required String type, // 'cotisation' ou 'don'
    required double montant,
    String paymentMethod = 'all',
    Map<String, dynamic>? metadata,
  }) async {
    try {
      final response = await _dio.post(
        '/api/payment/initiate',
        data: {
          'type': type,
          'montant': montant,
          'payment_method': paymentMethod,
          'metadata': metadata ?? {},
        },
        options: Options(
          headers: {
            'Content-Type': 'application/json',
            'Authorization': 'Bearer $token',
          },
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
          'message': response.data['message'] ?? 'Erreur lors de l\'initiation du paiement',
        };
      }
    } on DioException catch (e) {
      print('DioException in initiatePayment: ${e.type}');
      print('Error message: ${e.message}');
      print('Response: ${e.response}');
      
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
      print('Unexpected error in initiatePayment: $e');
      print('Error type: ${e.runtimeType}');
      
      return {
        'success': false,
        'message': 'Erreur inattendue: ${e.toString()}',
      };
    }
  }

  /// Vérifier le statut d'un paiement
  Future<Map<String, dynamic>> checkPaymentStatus({
    required String token,
    required String referenceId,
  }) async {
    try {
      final response = await _dio.get(
        '/api/payment/status/$referenceId',
        options: Options(
          headers: {
            'Content-Type': 'application/json',
            'Authorization': 'Bearer $token',
          },
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
          'message': response.data['message'] ?? 'Erreur lors de la vérification',
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
      return {
        'success': false,
        'message': 'Erreur inattendue: ${e.toString()}',
      };
    }
  }
}
