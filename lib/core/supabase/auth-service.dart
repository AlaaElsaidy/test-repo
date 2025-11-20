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

  /// Create patient account with default password (123456)
  /// Used when family member invites a patient
  /// If email already exists in auth, throws exception
  Future<AuthResponse> createPatientAccountWithDefaultPassword({
    required String email,
    required String name,
    String? phone,
  }) async {
    const defaultPassword = '123456';
    
    try {
      final response = await _client.auth.signUp(
        email: email,
        password: defaultPassword,
      );

      if (response.user != null) {
        // Use upsert to avoid unique constraint violations
        await _client.from('users').upsert({
          'id': response.user!.id,
          'email': email,
          'name': name,
          'role': 'patient',
          if (phone != null) 'phone': phone,
        }, onConflict: 'id');
      }

      return response;
    } catch (e) {
      // If signup fails due to email already existing, check if user exists in users table
      final existingUser = await _client
          .from('users')
          .select()
          .eq('email', email)
          .maybeSingle();
      
      if (existingUser != null) {
        // User exists in users table, throw exception to be handled by caller
        throw Exception('User already exists in system');
      }
      
      // Re-throw original error
      rethrow;
    }
  }
}
