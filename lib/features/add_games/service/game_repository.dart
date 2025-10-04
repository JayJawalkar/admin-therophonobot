// lib/features/add_games/repositories/game_repository.dart
import 'dart:typed_data';
import 'package:admin_therophonobot/features/add_games/service/supabase_game_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class GameRepository {
  final SupabaseGameService _supabaseService;

  GameRepository({required SupabaseClient supabaseClient})
      : _supabaseService = SupabaseGameService(supabaseClient);

  Future<String> uploadFile(Uint8List bytes, String fileName, String path) async {
    return await _supabaseService.uploadFile(bytes, fileName, path);
  }

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
    await _supabaseService.saveGame(
      name: name,
      bannerUrl: bannerUrl,
      category: category,
      items: items,
      isPremium: isPremium,
      emoji: emoji,
      description: description,
      difficulty: difficulty,
    );
  }

  Future<void> updateGame({
    required String gameId,
    required String name,
    required String bannerUrl,
    required List<Map<String, String>> items,
    String? emoji,
    String? description,
    String? difficulty,
  }) async {
    await _supabaseService.updateGame(
      gameId: gameId,
      name: name,
      bannerUrl: bannerUrl,
      items: items,
      emoji: emoji,
      description: description,
      difficulty: difficulty,
    );
  }

  Future<Map<String, dynamic>> getGame(String gameId) async {
    return await _supabaseService.getGame(gameId);
  }

  Future<List<Map<String, dynamic>>> getGamesByCategory(String category) async {
    return await _supabaseService.getGamesByCategory(category);
  }
}