import 'package:alzcare/core/supabase/supabase-config.dart';
import 'package:supabase/supabase.dart';

class AuthService {
  final _client = SupabaseConfig.client;

  Future<AuthResponse> signUp({
    required String email,
    required String password,
    required String name,
    required String role,
  }) async {
    final response = await _client.auth.signUp(
      email: email,
      password: password,
    );

    if (response.user != null) {
      await _client.from('users').upsert({
        'id': response.user!.id,
        'email': email,
        'name': name,
        'role': role,
      });
    }

    return response;
  }

  Future<AuthResponse> signIn({
    required String email,
    required String password,
  }) async {
    final response = await _client.auth.signInWithPassword(
      email: email,
      password: password,
    );
    return response;
  }

  Future<void> signOut() async {
    await _client.auth.signOut();
  }

  Future<void> resetPassword(String email) async {
    await _client.auth.resetPasswordForEmail(email);
  }

  User? getCurrentUser() {
    return _client.auth.currentUser;
  }

  bool isLoggedIn() {
    return _client.auth.currentUser != null;
  }

  Stream<AuthState> authStateStream() {
    return _client.auth.onAuthStateChange;
  }
}
