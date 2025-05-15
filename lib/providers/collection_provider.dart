import 'dart:io'; // ADDED for File and Directory
import 'package:flutter/foundation.dart';
import 'package:yakuza/database/database_service.dart';
import 'package:yakuza/database/manga_db_model.dart';
import 'package:yakuza/models/manga_api_model.dart';
import 'package:yakuza/utils/constants.dart';
import 'package:http/http.dart' as http; // ADDED for image download
import 'package:path_provider/path_provider.dart'; // ADDED for file paths
import 'package:path/path.dart' as p; // ADDED for path manipulation

class CollectionProvider with ChangeNotifier {
  final DatabaseService _dbService = DatabaseService();

  List<MangaDbModel> _collectedManga = [];
  bool _isLoading = false;
  String? _currentFilter;
  String _currentSortBy = AppConstants.columnTitle;

  List<MangaDbModel> get collectedManga => _collectedManga;
  bool get isLoading => _isLoading;
  String? get currentFilter => _currentFilter;
  String get currentSortBy => _currentSortBy;

  CollectionProvider() {
    fetchCollection();
  }

  // NEW METHOD: To download and save image
  Future<String?> _downloadAndSaveImage(String imageUrl, int malId) async {
    if (imageUrl.isEmpty) return null;
    try {
      final http.Response response = await http.get(Uri.parse(imageUrl)).timeout(const Duration(seconds: 20));
      if (response.statusCode == 200) {
        final directory = await getApplicationDocumentsDirectory();
        final imageDir = Directory(p.join(directory.path, 'manga_covers'));
        if (!await imageDir.exists()) {
          await imageDir.create(recursive: true);
        }
        // Try to get a valid extension, default to .jpg
        String fileExtension = p.extension(imageUrl);
        if (fileExtension.isEmpty || fileExtension.length > 5) { // Basic check for valid extension
            fileExtension = '.jpg';
        }
        final filePath = p.join(imageDir.path, '$malId$fileExtension');
        final File file = File(filePath);
        await file.writeAsBytes(response.bodyBytes);
        print('Image saved to: $filePath');
        return filePath;
      } else {
        print('Failed to download image $imageUrl: Status ${response.statusCode}');
      }
    } catch (e) {
      print('Error downloading image $imageUrl: $e');
      return null;
    }
    return null;
  }

  // NEW METHOD: To delete a local image file
  Future<void> _deleteLocalImage(String? localPath) async {
    if (localPath == null || localPath.isEmpty) return;
    try {
      final file = File(localPath);
      if (await file.exists()) {
        await file.delete();
        print('Deleted local image: $localPath');
      }
    } catch (e) {
      print('Error deleting local image $localPath: $e');
    }
  }


  Future<void> fetchCollection() async {
    _isLoading = true;
    notifyListeners();
    try {
      _collectedManga = await _dbService.getAllManga(sortBy: _currentSortBy, filterByStatus: _currentFilter);
    } catch (e) {
      print("Error fetching collection: $e");
      _collectedManga = [];
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // MODIFIED: addMangaToCollection to include image download
  Future<void> addMangaToCollection(MangaApiModel apiManga, String userStatus, String userNotes, int userScore) async {
    final newDbManga = MangaDbModel.fromApiModel(apiManga, userStatus, userNotes, userScore);

    // Download and save image, then update the model
    final String? localPath = await _downloadAndSaveImage(apiManga.imageUrl, apiManga.malId);
    if (localPath != null) {
      newDbManga.localImagePath = localPath;
    } else {
      // Handle image download failure? For now, we'll save without local path.
      // User will see network image or placeholder.
      print('Warning: Failed to download image for ${apiManga.title}. localImagePath will be null.');
    }

    try {
      await _dbService.addManga(newDbManga);
      await fetchCollection(); // Refresh list which now includes the new item
    } catch (e) {
      print("Error adding manga to collection: $e");
      throw Exception("Failed to add manga: $e");
    }
  }

  Future<void> updateMangaInCollection(MangaDbModel mangaToUpdate) async {
    try {
      // If image URL changed and you want to re-download, add logic here.
      // For now, we assume image doesn't change on update of user notes/status.
      await _dbService.updateManga(mangaToUpdate);
      await fetchCollection();
    } catch (e) {
      print("Error updating manga: $e");
      throw Exception("Failed to update manga: $e");
    }
  }

  // MODIFIED: removeMangaFromCollection to also delete local image
  Future<void> removeMangaFromCollection(int malId) async {
    try {
      // Delete from DB and get the model back to find local image path
      MangaDbModel? deletedManga = await _dbService.deleteMangaAndReturn(malId);
      
      if (deletedManga != null) {
        // If manga was successfully deleted from DB, try to delete its local image
        await _deleteLocalImage(deletedManga.localImagePath);
      } else {
        print('Manga with ID $malId not found or failed to delete from DB.');
      }
      await fetchCollection(); // Refresh list
    } catch (e) {
      print("Error removing manga: $e");
      throw Exception("Failed to remove manga: $e");
    }
  }

  MangaDbModel? getCollectedMangaById(int malId) {
    try {
      return _collectedManga.firstWhere((manga) => manga.malId == malId);
    } catch (e) {
      return null;
    }
  }

  bool isMangaInCollection(int malId) {
    return _collectedManga.any((manga) => manga.malId == malId);
  }

  Future<void> setFilter(String? status) async {
    _currentFilter = status;
    await fetchCollection();
  }

  Future<void> setSortBy(String sortBy) async {
    _currentSortBy = sortBy;
    await fetchCollection();
  }
}