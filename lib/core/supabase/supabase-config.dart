import 'package:supabase_flutter/supabase_flutter.dart';

import '../../config/env/supabase_keys.dart';

class SupabaseConfig {
  static const String supabaseUrl = SupabaseKeys.url;
  static const String supabaseKey = SupabaseKeys.anonKey; // Anon Key

  static final Supabase _instance = Supabase.instance;

  static Future<void> initialize() async {
    await Supabase.initialize(
      url: supabaseUrl,
      anonKey: supabaseKey,
    );
  }

  static SupabaseClient get client => Supabase.instance.client;

  static User? get currentUser => client.auth.currentUser;

  static bool get isLoggedIn => currentUser != null;
}
