import 'package:supabase_flutter/supabase_flutter.dart';

class SupabaseService {
  static final SupabaseClient _client = Supabase.instance.client;

  // Get all users
  static Future<List<Map<String, dynamic>>> getAllUsers() async {
    try {
      final response = await _client
          .from('users')
          .select()
          .order('created_at', ascending: false);
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      throw Exception('Error fetching users: $e');
    }
  }

  // Get premium users only
  static Future<List<Map<String, dynamic>>> getPremiumUsers() async {
    try {
      final response = await _client
          .from('users')
          .select()
          .eq('is_premium', true)
          .order('created_at', ascending: false);
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      throw Exception('Error fetching premium users: $e');
    }
  }

  // Get users with expiring premium (next 7 days)
  static Future<List<Map<String, dynamic>>> getExpiringPremiumUsers() async {
    try {
      final now = DateTime.now().toIso8601String();
      final cutoff =
          DateTime.now().add(const Duration(days: 7)).toIso8601String();

      final response = await _client
          .from('users')
          .select()
          .eq('is_premium', true)
          .gt('premium_expires_at', now)
          .lt('premium_expires_at', cutoff)
          .order('premium_expires_at', ascending: true);
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      throw Exception('Error fetching expiring users: $e');
    }
  }

  // Increase premium validity
  static Future<Map<String, dynamic>> increasePremiumValidity(
    String userId,
    int daysToAdd,
  ) async {
    try {
      // First, get the current user data
      final userData =
          await _client
              .from('users')
              .select('premium_expires_at')
              .eq('id', userId)
              .single();

      DateTime newExpiry;
      if (userData['premium_expires_at'] != null) {
        final currentExpiry = DateTime.parse(userData['premium_expires_at']);
        newExpiry = currentExpiry.add(Duration(days: daysToAdd));
      } else {
        newExpiry = DateTime.now().add(Duration(days: daysToAdd));
      }

      await _client
          .from('users')
          .update({'premium_expires_at': newExpiry.toIso8601String()})
          .eq('id', userId);

      return {
        'success': true,
        'message': 'Premium validity extended by $daysToAdd days',
      };
    } catch (e) {
      return {'success': false, 'error': e.toString()};
    }
  }

  // Block user
  static Future<Map<String, dynamic>> blockUser(String userId) async {
    try {
      await _client.from('users').update({'is_blocked': true}).eq('id', userId);

      return {'success': true, 'message': 'User blocked successfully'};
    } catch (e) {
      return {'success': false, 'error': e.toString()};
    }
  }

  // Unblock user
  static Future<Map<String, dynamic>> unblockUser(String userId) async {
    try {
      await _client
          .from('users')
          .update({'is_blocked': false})
          .eq('id', userId);

      return {'success': true, 'message': 'User unblocked successfully'};
    } catch (e) {
      return {'success': false, 'error': e.toString()};
    }
  }

  // Get user statistics
  static Future<Map<String, int>> getUserStats() async {
    try {
      final allUsersResponse = await _client
          .from('users')
          .select('id') // select minimal columns when only counting
          .count(CountOption.exact);

      final premiumUsersResponse = await _client
          .from('users')
          .select('id')
          .eq('is_premium', true)
          .count(CountOption.exact);

      return {
        'totalUsers': allUsersResponse.count,
        'premiumUsers': premiumUsersResponse.count,
      };
    } catch (e) {
      throw Exception('Error fetching user stats: $e');
    }
  }

  // Stream all users (real-time)
  static Stream<List<Map<String, dynamic>>> streamAllUsers() {
    return _client
        .from('users')
        .stream(primaryKey: ['id'])
        .order('created_at', ascending: false);
  }

  // Stream premium users (real-time)
  static Stream<List<Map<String, dynamic>>> streamPremiumUsers() {
    return _client
        .from('users')
        .stream(primaryKey: ['id'])
        .eq('is_premium', true)
        .order('created_at', ascending: false);
  }
}
