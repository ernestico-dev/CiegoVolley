import 'dart:js_interop';

import 'package:web/web.dart' as web;

/// Implementación web con la API `Notification` del navegador.
bool get notificationsAvailable => true;

String get notificationPermission => web.Notification.permission;

Future<bool> requestNotificationPermission() async {
  if (web.Notification.permission == 'granted') return true;
  if (web.Notification.permission == 'denied') return false;

  try {
    final result = await web.Notification.requestPermission().toDart;
    return result.toDart == 'granted';
  } catch (_) {
    return false;
  }
}

void showLocalNotification(String title, String body) {
  if (web.Notification.permission != 'granted') return;

  try {
    web.Notification(
      title,
      web.NotificationOptions(
        body: body,
        icon: '/icons/Icon-192.png',
        tag: 'ciegovolley-torneos',
      ),
    );
  } catch (_) {
    // Si el navegador no deja mostrar la notificación, no rompemos la app.
  }
}
