// lib/core/di/injection_container.dart

import 'package:get_it/get_it.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../repositories/tracking_repository.dart';

final getIt = GetIt.instance;

void setupDependencies() {
  // Supabase Client
  final supabaseClient = Supabase.instance.client;
  
  // Repositories
  getIt.registerSingleton<TrackingRepository>(
    TrackingRepository(supabaseClient),
  );
}
