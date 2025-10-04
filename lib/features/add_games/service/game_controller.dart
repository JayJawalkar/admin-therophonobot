// game_controller.dart
import 'package:admin_therophonobot/features/add_games/service/game_repository.dart';
import 'package:file_picker/file_picker.dart';

class GameController {
  final GameRepository _repository;

  GameController({required GameRepository repository})
    : _repository = repository;

  String? errorMessage;
  bool isLoading = false;
  PlatformFile? gameBanner;
  PlatformFile? currentItemImage;
  final List<Map<String, dynamic>> gameItems = [];

  Future<void> pickImage(bool isBanner) async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.image,
        allowMultiple: false,
        withData: true,
      );

      if (result != null && result.files.isNotEmpty) {
        if (isBanner) {
          gameBanner = result.files.first;
        } else {
          currentItemImage = result.files.first;
        }
        errorMessage = null;
      }
    } catch (e) {
      errorMessage = 'Image selection failed: ${e.toString()}';
    }
  }

  void addGameItem(String itemName) {
    if (itemName.isEmpty || currentItemImage == null) {
      errorMessage = 'Please provide both item name and image';
      return;
    }

    gameItems.add({'name': itemName.trim(), 'file': currentItemImage});
    currentItemImage = null;
    errorMessage = null;
  }

  void removeItem(int index) {
    gameItems.removeAt(index);
  }

  Future<void> saveGame({
    required String gameName,
    required String category,
    bool isPremium = false,
    String? emoji,
    String? description,
    String? difficulty,
  }) async {
    if (gameName.isEmpty) {
      errorMessage = 'Please provide a game name';
      return;
    }

    if (category == 'home' && gameBanner == null) {
      errorMessage = 'Please select a game banner';
      return;
    }

    if (category == 'pathway' && emoji == null) {
      errorMessage = 'Please select an emoji for the game';
      return;
    }

    if (category == 'syllables' && difficulty == null) {
      errorMessage = 'Please select a difficulty category';
      return;
    }

    if (gameItems.isEmpty) {
      errorMessage = 'Please add at least one game item';
      return;
    }

    isLoading = true;
    errorMessage = null;

    try {
      String? bannerUrl;

      // Upload banner only for home category
      if (category == 'home' && gameBanner != null) {
        bannerUrl = await _repository.uploadFile(
          gameBanner!.bytes!,
          gameBanner!.name,
          'game_banners',
        );
      }

      // Upload all item images
      final List<Map<String, String>> itemsWithUrls = [];
      for (final item in gameItems) {
        final PlatformFile file = item['file'];
        final imageUrl = await _repository.uploadFile(
          file.bytes!,
          file.name,
          'game_items',
        );

        itemsWithUrls.add({'name': item['name'], 'image': imageUrl});
      }

      // Save to Supabase
      await _repository.saveGame(
        name: gameName.trim(),
        bannerUrl: bannerUrl ?? '', // Use empty string if no banner
        category: category,
        items: itemsWithUrls,
        isPremium: isPremium,
        emoji: emoji,
        description: description,
        difficulty: difficulty,
      );
    } catch (e) {
      errorMessage = 'Failed to save game: ${e.toString()}';
    } finally {
      isLoading = false;
    }
  }

  void reset() {
    gameBanner = null;
    currentItemImage = null;
    gameItems.clear();
    errorMessage = null;
    isLoading = false;
  }
}
