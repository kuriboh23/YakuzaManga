// LEARN: This file is used to store application-wide constants.
// This helps in avoiding magic strings/numbers in the codebase and makes updates easier.

class AppConstants {
  // API Constants
  static const String jikanApiBaseUrl = 'https://api.jikan.moe/v4';

  // Database Constants
  static const String databaseName = 'yakuza.db';
  static const int databaseVersion = 1;

  static const String tableManga = 'manga';
  static const String columnMalId = 'mal_id'; // Manga ID from MyAnimeList (Jikan)
  static const String columnTitle = 'title';
  static const String columnImageUrl = 'image_url';
  static const String columnLocalImagePath = 'local_image_path'; // Path to locally stored image
  static const String columnSynopsis = 'synopsis';
  static const String columnApiScore = 'api_score'; // Score from Jikan API
  static const String columnMangaType = 'manga_type'; // e.g., Manga, Manhwa
  static const String columnApiStatus = 'api_status'; // e.g., Finished, Publishing
  static const String columnChapters = 'chapters';
  static const String columnVolumes = 'volumes';

  // User-specific columns
  static const String columnUserStatus = 'user_status'; // e.g., Reading, Completed
  static const String columnUserNotes = 'user_notes';
  static const String columnUserScore = 'user_score'; // Personal score (1-10)
  static const String columnDateAdded = 'date_added'; // ISO8601 string

  // Predefined user statuses for dropdowns etc.
  static const List<String> userStatuses = [
    'Reading',
    'Completed',
    'On Hold',
    'Dropped',
    'Plan to Read',
  ];
}