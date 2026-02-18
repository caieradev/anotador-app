import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'app.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final url = const String.fromEnvironment('SUPABASE_URL');
  final key = const String.fromEnvironment('SUPABASE_ANON_KEY');
  debugPrint('[App] Starting with Supabase URL: $url');

  await Supabase.initialize(url: url, anonKey: key);
  debugPrint('[App] Supabase initialized');

  final session = Supabase.instance.client.auth.currentSession;
  debugPrint('[App] Current session: ${session != null ? "logged in (${session.user.id})" : "none"}');

  FlutterError.onError = (details) {
    debugPrint('[App] FlutterError: ${details.exceptionAsString()}');
    debugPrint('[App] Stack: ${details.stack}');
  };

  runApp(const ProviderScope(child: AnotadorApp()));
}
