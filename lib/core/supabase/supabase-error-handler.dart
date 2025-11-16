import 'dart:async';
import 'dart:io';

import 'package:supabase_flutter/supabase_flutter.dart';

class SupabaseErrorHandler {
  static String handleAuthError(dynamic error) {
    if (error is AuthException) {
      switch (error.statusCode) {
        case 400:
          return error.message ?? 'Invalid request data';
        case 401:
          return 'Unauthorized';
        case 429:
          return 'Too many requests. Please try again later.';
        default:
          return error.message ?? 'An authentication error occurred';
      }
    } else if (error is PostgrestException) {
      return handlePostgrestError(error);
    } else if (error is SocketException) {
      return 'Network error. Please check your internet connection';
    } else if (error is TimeoutException) {
      return 'Request timed out. Please try again';
    } else if (error is Exception) {
      return error.toString();
    } else {
      return 'An unknown error occurred';
    }
  }

  static String handlePostgrestError(PostgrestException error) {
    if (error.code == '23505') {
      return 'The user already exists.';
    } else if (error.code == '23514') {
      return 'Invalid data for the table';
    } else if (error.code != null) {
      return 'Database error: ${error.code}';
    } else {
      return error.message ?? 'Database error';
    }
  }

  /// Generic Supabase Error
  static String handleError(dynamic error) {
    return handleAuthError(error);
  }
}
