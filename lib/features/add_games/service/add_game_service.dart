// // lib/features/add_games/controllers/game_controller.dart
// import 'dart:typed_data';
// import 'package:cloud_firestore/cloud_firestore.dart';
// import 'package:file_picker/file_picker.dart';
// import 'package:firebase_storage/firebase_storage.dart';

// class GameController {
//   final GameRepository _repository;

//   GameController({required GameRepository repository}) : _repository = repository;

//   String? _errorMessage;
//   String? get errorMessage => _errorMessage;

//   bool _isLoading = false;
//   bool get isLoading => _isLoading;

//   PlatformFile? _gameBanner;
//   PlatformFile? get gameBanner => _gameBanner;

//   PlatformFile? _currentItemImage;
//   PlatformFile? get currentItemImage => _currentItemImage;

//   final List<Map<String, dynamic>> _gameItems = [];
//   List<Map<String, dynamic>> get gameItems => _gameItems;

//   Future<void> pickImage(bool isBanner) async {
//     try {
//       final result = await FilePicker.platform.pickFiles(
//         type: FileType.image,
//         allowMultiple: false,
//         withData: true,
//       );

//       if (result != null && result.files.isNotEmpty) {
//         if (isBanner) {
//           _gameBanner = result.files.first;
//         } else {
//           _currentItemImage = result.files.first;
//         }
//         _errorMessage = null;
//       }
//     } catch (e) {
//       _errorMessage = 'Image selection failed: ${e.toString()}';
//     }
//   }

//   void addGameItem(String itemName) {
//     if (itemName.isEmpty || _currentItemImage == null) {
//       _errorMessage = 'Please provide both item name and image';
//       return;
//     }

//     _gameItems.add({
//       'name': itemName.trim(),
//       'file': _currentItemImage,
//     });
//     _currentItemImage = null;
//     _errorMessage = null;
//   }

//   void removeItem(int index) {
//     _gameItems.removeAt(index);
//   }

//   Future<void> saveGame(String gameName) async {
//     if (gameName.isEmpty) {
//       _errorMessage = 'Please provide a game name';
//       return;
//     }

//     if (_gameBanner == null) {
//       _errorMessage = 'Please select a game banner';
//       return;
//     }

//     if (_gameItems.isEmpty) {
//       _errorMessage = 'Please add at least one game item';
//       return;
//     }

//     _isLoading = true;
//     _errorMessage = null;

//     try {
//       // Upload banner
//       final bannerUrl = await _repository.uploadFile(
//         _gameBanner!.bytes!,
//         '${DateTime.now().millisecondsSinceEpoch}_${_gameBanner!.name}',
//         'game_banners',
//       );

//       // Upload all item images
//       final List<Map<String, String>> itemsWithUrls = [];
//       for (final item in _gameItems) {
//         final PlatformFile file = item['file'];
//         final imageUrl = await _repository.uploadFile(
//           file.bytes!,
//           '${DateTime.now().millisecondsSinceEpoch}_${file.name}',
//           'game_items',
//         );

//         itemsWithUrls.add({
//           'name': item['name'],
//           'image': imageUrl,
//         });
//       }

//       // Save to Firestore
//       await _repository.saveGame(
//         name: gameName.trim(),
//         bannerUrl: bannerUrl,
//         items: itemsWithUrls,
//       );
//     } catch (e) {
//       _errorMessage = 'Failed to save game: ${e.toString()}';
//     } finally {
//       _isLoading = false;
//     }
//   }

//   void reset() {
//     _gameBanner = null;
//     _currentItemImage = null;
//     _gameItems.clear();
//     _errorMessage = null;
//     _isLoading = false;
//   }
// }


// class GameRepository {
//   final FirebaseStorage _storage;
//   final FirebaseFirestore _firestore;

//   GameRepository({
//     FirebaseStorage? storage,
//     FirebaseFirestore? firestore,
//   })  : _storage = storage ?? FirebaseStorage.instance,
//         _firestore = firestore ?? FirebaseFirestore.instance;

//   Future<String> uploadFile(Uint8List bytes, String fileName, String path) async {
//     try {
//       final ref = _storage.ref().child('$path/$fileName');
//       await ref.putData(bytes);
//       return await ref.getDownloadURL();
//     } catch (e) {
//       throw Exception('Failed to upload file: ${e.toString()}');
//     }
//   }

//   Future<void> saveGame({
//     required String name,
//     required String bannerUrl,
//     required List<Map<String, String>> items,
//   }) async {
//     try {
//       await _firestore.collection('games').add({
//         'name': name,
//         'bannerUrl': bannerUrl,
//         'items': items,
//         'createdAt': FieldValue.serverTimestamp(),
//         'updatedAt': FieldValue.serverTimestamp(),
//       });
//     } catch (e) {
//       throw Exception('Failed to save game: ${e.toString()}');
//     }
//   }
// }