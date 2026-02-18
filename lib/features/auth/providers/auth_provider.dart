import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

final supabaseProvider = Provider<SupabaseClient>((ref) {
  return Supabase.instance.client;
});

final authChangeProvider = StreamProvider<AuthState>((ref) {
  return ref.watch(supabaseProvider).auth.onAuthStateChange;
});

final currentUserProvider = Provider<User?>((ref) {
  return ref.watch(supabaseProvider).auth.currentUser;
});

enum AppAuthStatus { idle, loading, signUpSuccess }

class AppAuthState {
  final AppAuthStatus status;
  final String? error;

  const AppAuthState({this.status = AppAuthStatus.idle, this.error});
}

class AuthNotifier extends StateNotifier<AppAuthState> {
  final SupabaseClient _client;

  AuthNotifier(this._client) : super(const AppAuthState());

  Future<void> signInWithEmail(String email, String password) async {
    debugPrint('[Auth] signIn: $email');
    state = const AppAuthState(status: AppAuthStatus.loading);
    try {
      final response = await _client.auth.signInWithPassword(email: email, password: password);
      debugPrint('[Auth] signIn success, user: ${response.user?.id}');
      state = const AppAuthState();
    } catch (e) {
      debugPrint('[Auth] signIn error: $e');
      state = AppAuthState(error: e.toString());
    }
  }

  Future<void> signUpWithEmail(
    String email,
    String password,
    String name,
  ) async {
    debugPrint('[Auth] signUp: $email, name: $name');
    state = const AppAuthState(status: AppAuthStatus.loading);
    try {
      final response = await _client.auth.signUp(
        email: email,
        password: password,
        data: {'name': name},
      );
      debugPrint('[Auth] signUp success, user: ${response.user?.id}, session: ${response.session != null}');
      state = const AppAuthState(status: AppAuthStatus.signUpSuccess);
    } catch (e) {
      debugPrint('[Auth] signUp error: $e');
      state = AppAuthState(error: e.toString());
    }
  }

  void clearError() {
    state = const AppAuthState();
  }

  Future<void> signOut() async {
    debugPrint('[Auth] signOut');
    await _client.auth.signOut();
    state = const AppAuthState();
  }
}

final authNotifierProvider =
    StateNotifierProvider<AuthNotifier, AppAuthState>((ref) {
  return AuthNotifier(ref.watch(supabaseProvider));
});
