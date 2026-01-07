import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class NotificationService {
  static final FlutterLocalNotificationsPlugin _notifications =
      FlutterLocalNotificationsPlugin();

  static bool _initialized = false;

  /// Initialiser le service de notifications
  static Future<void> initialize() async {
    if (_initialized) return;

    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    const initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _notifications.initialize(initSettings);
    _initialized = true;
  }

  /// Afficher une notification de paiement réussi
  static Future<void> showPaymentSuccess(double montant, String type) async {
    await initialize();

    const androidDetails = AndroidNotificationDetails(
      'payment_success',
      'Paiements réussis',
      channelDescription: 'Notifications pour les paiements réussis',
      importance: Importance.high,
      priority: Priority.high,
      icon: '@mipmap/ic_launcher',
    );

    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    const details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _notifications.show(
      0,
      'Paiement réussi ! ✅',
      'Votre $type de ${montant.toStringAsFixed(2)} HTG a été effectué avec succès.',
      details,
    );
  }

  /// Afficher une notification de paiement en attente
  static Future<void> showPaymentPending(double montant) async {
    await initialize();

    const androidDetails = AndroidNotificationDetails(
      'payment_pending',
      'Paiements en attente',
      channelDescription: 'Notifications pour les paiements en attente',
      importance: Importance.defaultImportance,
      priority: Priority.defaultPriority,
      icon: '@mipmap/ic_launcher',
    );

    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    const details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _notifications.show(
      1,
      'Paiement en cours ⏳',
      'Votre paiement de ${montant.toStringAsFixed(2)} HTG est en cours de traitement. Vous serez notifié dès confirmation.',
      details,
    );
  }

  /// Afficher une notification de paiement confirmé (après vérification)
  static Future<void> showPaymentConfirmed(double montant, String type) async {
    await initialize();

    const androidDetails = AndroidNotificationDetails(
      'payment_confirmed',
      'Paiements confirmés',
      channelDescription: 'Notifications pour les paiements confirmés après vérification',
      importance: Importance.high,
      priority: Priority.high,
      icon: '@mipmap/ic_launcher',
    );

    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    const details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _notifications.show(
      2,
      'Paiement confirmé ! 🎉',
      'Votre $type de ${montant.toStringAsFixed(2)} HTG a été confirmé.',
      details,
    );
  }
}
