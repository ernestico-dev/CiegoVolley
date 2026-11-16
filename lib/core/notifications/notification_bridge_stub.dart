/// Implementación para plataformas sin API de notificaciones del navegador.
bool get notificationsAvailable => false;

/// Estado del permiso: `granted`, `denied`, `default` o `unsupported`.
String get notificationPermission => 'unsupported';

Future<bool> requestNotificationPermission() async => false;

void showLocalNotification(String title, String body) {}
