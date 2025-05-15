// LEARN: This file defines the Dart class that represents a manga record
// as it will be stored in the local SQLite database. It often includes fields
// from the API model plus user-specific data.

import 'package:yakuza/models/manga_api_model.dart';
import 'package:yakuza/utils/constants.dart';

class MangaDbModel {
  final int malId; // Primary Key
  String title;
  String imageUrl; // Original API image URL, can be kept for reference or if local fails
  String? localImagePath; // ADDED: Path to the locally stored image file
  String? synopsis;
  double? apiScore;
  String? mangaType;
  String? apiStatus;
  int? chapters;
  int? volumes;

  // User-specific fields
  String userStatus; // e.g., Reading, Completed
  String userNotes;
  int userScore; // Personal score (1-10)
  String dateAdded; // ISO8601 string

  MangaDbModel({
    required this.malId,
    required this.title,
    required this.imageUrl, // Keep original URL
    this.localImagePath,   // MODIFIED: Now part of constructor
    this.synopsis,
    this.apiScore,
    this.mangaType,
    this.apiStatus,
    this.chapters,
    this.volumes,
    required this.userStatus,
    this.userNotes = '',
    this.userScore = 0, // Default to 0, meaning unrated
    required this.dateAdded,
  });

  // LEARN: A method to convert our MangaDbModel instance into a Map.
  // This is necessary for inserting/updating data in the SQLite database,
  // as sqflite expects data in Map<String, dynamic> format.
  Map<String, dynamic> toMap() {
    return {
      AppConstants.columnMalId: malId,
      AppConstants.columnTitle: title,
      AppConstants.columnImageUrl: imageUrl,
      AppConstants.columnLocalImagePath: localImagePath,
      AppConstants.columnSynopsis: synopsis,
      AppConstants.columnApiScore: apiScore,
      AppConstants.columnMangaType: mangaType,
      AppConstants.columnApiStatus: apiStatus,
      AppConstants.columnChapters: chapters,
      AppConstants.columnVolumes: volumes,
      AppConstants.columnUserStatus: userStatus,
      AppConstants.columnUserNotes: userNotes,
      AppConstants.columnUserScore: userScore,
      AppConstants.columnDateAdded: dateAdded,
    };
  }

  // LEARN: A factory constructor to create a MangaDbModel instance from a Map.
  // This is used when reading data from the SQLite database, as sqflite
  // returns query results as List<Map<String, dynamic>>.
  factory MangaDbModel.fromMap(Map<String, dynamic> map) {
    return MangaDbModel(
      malId: map[AppConstants.columnMalId] as int,
      title: map[AppConstants.columnTitle] as String,
      imageUrl: map[AppConstants.columnImageUrl] as String,
      localImagePath: map[AppConstants.columnLocalImagePath] as String?,
      synopsis: map[AppConstants.columnSynopsis] as String?,
      apiScore: map[AppConstants.columnApiScore] as double?,
      mangaType: map[AppConstants.columnMangaType] as String?,
      apiStatus: map[AppConstants.columnApiStatus] as String?,
      chapters: map[AppConstants.columnChapters] as int?,
      volumes: map[AppConstants.columnVolumes] as int?,
      userStatus: map[AppConstants.columnUserStatus] as String,
      userNotes: map[AppConstants.columnUserNotes] as String,
      userScore: map[AppConstants.columnUserScore] as int,
      dateAdded: map[AppConstants.columnDateAdded] as String,
    );
  }

  // LEARN: A convenience factory constructor to create a MangaDbModel from an ApiMangaModel.
  // This is useful when adding a new manga from API results to the local collection.
  // localImagePath will be set later after download.
  factory MangaDbModel.fromApiModel(
      MangaApiModel apiModel, String initialUserStatus, String initialUserNotes, int initialUserScore) {
    return MangaDbModel(
      malId: apiModel.malId,
      title: apiModel.displayTitle,
      imageUrl: apiModel.imageUrl, // Store the original URL
      // localImagePath is initially null, will be set after image download
      synopsis: apiModel.synopsis,
      apiScore: apiModel.score,
      mangaType: apiModel.type,
      apiStatus: apiModel.status,
      chapters: apiModel.chapters,
      volumes: apiModel.volumes,
      userStatus: initialUserStatus,
      userNotes: initialUserNotes,
      userScore: initialUserScore,
      dateAdded: DateTime.now().toIso8601String(),
    );
  }
}