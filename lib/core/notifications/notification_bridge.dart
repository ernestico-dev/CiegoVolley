/// Puente de notificaciones del navegador.
///
/// En web usa la API `Notification`; en el resto de plataformas no hace nada.
library;

export 'notification_bridge_stub.dart'
    if (dart.library.js_interop) 'notification_bridge_web.dart';
