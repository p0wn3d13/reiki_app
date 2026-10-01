import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

/// Encapsula FCM + notificaciones locales.
///
/// Se usa Firebase únicamente para el transporte de push (FCM), no para
/// auth ni base de datos — esa es la decisión de la Fase 1/2. El resto
/// del proyecto (Fase 9, sistema de disponibilidad/reservas) no depende
/// de este servicio.
class NotificationService {
  final _localNotifications = FlutterLocalNotificationsPlugin();
  final _messaging = FirebaseMessaging.instance;

  Future<void> init() async {
    await _messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    const androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosInit = DarwinInitializationSettings();
    await _localNotifications.initialize(
      const InitializationSettings(android: androidInit, iOS: iosInit),
    );

    // Notificación recibida con la app en primer plano.
    FirebaseMessaging.onMessage.listen(_showLocalNotification);
  }

  /// Token FCM del dispositivo actual, para guardar en `device_tokens`
  /// (tabla definida en la Fase 1) tras el login.
  Future<String?> getToken() => _messaging.getToken();

  Future<void> _showLocalNotification(RemoteMessage message) async {
    final notification = message.notification;
    if (notification == null) return;

    const androidDetails = AndroidNotificationDetails(
      'reiki_appointments',
      'Citas',
      channelDescription: 'Notificaciones de citas y recordatorios',
      importance: Importance.high,
      priority: Priority.high,
    );
    const details = NotificationDetails(android: androidDetails);

    await _localNotifications.show(
      notification.hashCode,
      notification.title,
      notification.body,
      details,
    );
  }
}
