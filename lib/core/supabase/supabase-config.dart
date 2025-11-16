import 'package:supabase_flutter/supabase_flutter.dart';

class SupabaseConfig {
  static const String supabaseUrl = "https://xyhexdrrfxqsnhlqluta.supabase.co";
  static const String supabaseKey =
      "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Inh5aGV4ZHJyZnhxc25obHFsdXRhIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NjI2MTQ3MjcsImV4cCI6MjA3ODE5MDcyN30.0uiIn3hs8XW1g79de3m3rWJK2WyQE3m-FST3X78dF4c"; // Anon Key

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
