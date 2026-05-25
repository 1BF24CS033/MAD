import 'package:supabase_flutter/supabase_flutter.dart';

/// Central access point for the Supabase client.
/// Call [SupabaseService.client] anywhere in the app.
class SupabaseService {
  SupabaseService._();

  static SupabaseClient get client => Supabase.instance.client;

  /// Convenience getter for the currently signed-in user's UUID.
  /// Returns null when no user is authenticated.
  static String? get currentUserId => client.auth.currentUser?.id;
}
