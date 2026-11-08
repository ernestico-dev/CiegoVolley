import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/date_symbol_data_local.dart';

import 'app.dart';
import 'core/supabase/supabase_bootstrap.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Necesario para `DateFormat` con locale 'es'.
  await initializeDateFormatting('es');

  final supabaseReady = await SupabaseBootstrap.initialize();

  runApp(ProviderScope(child: CiegoVolleyApp(supabaseReady: supabaseReady)));
}
