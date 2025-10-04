import 'dart:typed_data';
import 'package:supabase/supabase.dart';

class SupabaseGameService {
  final SupabaseClient _supabase;

  SupabaseGameService(this._supabase);

  // Upload file to Supabase Storage and return public URL
  Future<String> uploadFile(
    Uint8List bytes,
    String fileName,
    String bucketName,
  ) async {
    try {
      final filePath = '${DateTime.now().millisecondsSinceEpoch}_$fileName';
      await _supabase.storage.from(bucketName).uploadBinary(filePath, bytes);

      final publicUrl = _supabase.storage
          .from(bucketName)
          .getPublicUrl(filePath);
      return publicUrl;
    } catch (e) {
      throw Exception('Failed to upload file: $e');
    }
  }

  // Save game to Supabase
  Future<void> saveGame({
    required String name,
    required String bannerUrl,
    required String category,
    required List<Map<String, String>> items,
    bool isPremium = false,
    String? emoji,
    String? description,
    String? difficulty,
  }) async {
    try {
      final gameResponse =
          await _supabase
              .from('games')
              .insert({
                'name': name,
                'banner_url': bannerUrl,
                'category': category,
                'is_premium': isPremium,
                'emoji': emoji,
                'description': description,
                'difficulty': difficulty,
              })
              .select()
              .maybeSingle();

      if (gameResponse == null) {
        throw Exception('Game could not be created.');
      }

      final gameId = gameResponse['id'] as String;

      for (final item in items) {
        await _supabase.from('game_items').insert({
          'game_id': gameId,
          'name': item['name'],
          'image_url': item['image'],
        });
      }
    } on PostgrestException catch (e) {
      throw Exception('Failed to save game: ${e.message}');
    } catch (e) {
      throw Exception('Failed to save game: $e');
    }
  }

  // Update existing game
  Future<void> updateGame({
    required String gameId,
    required String name,
    required String bannerUrl,
    required List<Map<String, String>> items,
    String? emoji,
    String? description,
    String? difficulty,
  }) async {
    try {
      await _supabase
          .from('games')
          .update({
            'name': name,
            'banner_url': bannerUrl,
            'emoji': emoji,
            'description': description,
            'difficulty': difficulty,
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('id', gameId);

      // Remove old items
      await _supabase.from('game_items').delete().eq('game_id', gameId);

      // Insert new items
      for (final item in items) {
        await _supabase.from('game_items').insert({
          'game_id': gameId,
          'name': item['name'],
          'image_url': item['image'],
        });
      }
    } on PostgrestException catch (e) {
      throw Exception('Failed to update game: ${e.message}');
    } catch (e) {
      throw Exception('Failed to update game: $e');
    }
  }

  // Get game by ID
  Future<Map<String, dynamic>> getGame(String gameId) async {
    try {
      final response =
          await _supabase
              .from('games')
              .select('*, game_items(*)')
              .eq('id', gameId)
              .maybeSingle();

      if (response == null) {
        throw Exception('Game not found');
      }

      return Map<String, dynamic>.from(response);
    } on PostgrestException catch (e) {
      throw Exception('Failed to fetch game: ${e.message}');
    } catch (e) {
      throw Exception('Failed to fetch game: $e');
    }
  }

  // Get games by category
  Future<List<Map<String, dynamic>>> getGamesByCategory(String category) async {
    try {
      final response = await _supabase
          .from('games')
          .select('*, game_items(*)')
          .eq('category', category);

      return List<Map<String, dynamic>>.from(response);
    } on PostgrestException catch (e) {
      throw Exception('Failed to fetch games: ${e.message}');
    } catch (e) {
      throw Exception('Failed to fetch games: $e');
    }
  }

  // Delete game
  Future<void> deleteGame(String gameId) async {
    try {
      await _supabase.from('games').delete().eq('id', gameId);
    } on PostgrestException catch (e) {
      throw Exception('Failed to delete game: ${e.message}');
    } catch (e) {
      throw Exception('Failed to delete game: $e');
    }
  }
}
