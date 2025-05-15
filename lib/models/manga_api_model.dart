// LEARN: This file defines Dart classes to represent the structure of data
// received from the Jikan API. This is crucial for type safety and easy data handling
// after parsing JSON.

import 'dart:convert';

// Helper function to safely extract a string, returning an empty string if null or not a string
String _getString(dynamic value) => value is String ? value : '';
// Helper function to safely extract an int, returning 0 if null or not an int
int _getInt(dynamic value) => value is int ? value : (value is double ? value.toInt() : 0);
// Helper function to safely extract a double, returning 0.0 if null or not a double/int
double _getDouble(dynamic value) => value is double ? value : (value is int ? value.toDouble() : 0.0);


class Pagination {
  final int lastVisiblePage;
  final bool hasNextPage;
  final int currentPage;
  final PageItems items;

  Pagination({
    required this.lastVisiblePage,
    required this.hasNextPage,
    required this.currentPage,
    required this.items,
  });

  factory Pagination.fromJson(Map<String, dynamic> json) {
    return Pagination(
      lastVisiblePage: _getInt(json['last_visible_page']),
      hasNextPage: json['has_next_page'] is bool ? json['has_next_page'] : false,
      currentPage: _getInt(json['current_page']),
      items: PageItems.fromJson(json['items'] ?? {}),
    );
  }
}

class PageItems {
  final int count;
  final int total;
  final int perPage;

  PageItems({required this.count, required this.total, required this.perPage});

  factory PageItems.fromJson(Map<String, dynamic> json) {
    return PageItems(
      count: _getInt(json['count']),
      total: _getInt(json['total']),
      perPage: _getInt(json['per_page']),
    );
  }
}

// --- API Response Structures ---

class JikanMangaSearchResponse {
  final List<MangaApiModel> data;
  final Pagination? pagination;

  JikanMangaSearchResponse({required this.data, this.pagination});

  factory JikanMangaSearchResponse.fromJson(Map<String, dynamic> json) {
    var list = json['data'] as List?;
    List<MangaApiModel> mangaList = list != null
        ? list.map((i) => MangaApiModel.fromJson(i)).toList()
        : [];

    // LEARN: Safely parse pagination. It might not always be present or could be null.
    Pagination? paginationData;
    if (json.containsKey('pagination') && json['pagination'] != null) {
        paginationData = Pagination.fromJson(json['pagination']);
    }
    return JikanMangaSearchResponse(data: mangaList, pagination: paginationData);
  }
}

class JikanMangaDetailResponse {
  final MangaApiModel data;

  JikanMangaDetailResponse({required this.data});

  factory JikanMangaDetailResponse.fromJson(Map<String, dynamic> json) {
    return JikanMangaDetailResponse(
      data: MangaApiModel.fromJson(json['data']),
    );
  }
}

// --- Core Manga Model from API ---

class MangaApiModel {
  final int malId;
  final String url;
  final MangaImages images;
  final String title;
  final String? titleEnglish;
  final String? titleJapanese;
  final String type; // e.g., Manga, Novel, Manhwa, Manhua, Doujinshi
  final int? chapters;
  final int? volumes;
  final String status; // e.g., Finished, Publishing, On Hiatus
  final bool publishing;
  final double? score;
  final int? scoredBy;
  final int? rank;
  final int? popularity;
  final int? members;
  final int? favorites;
  final String? synopsis;
  final String? background;
  // final List<MangaGenre> genres; // Simplified for this app
  // final List<MangaAuthor> authors; // Simplified for this app
  // final List<MangaSerialization> serializations; // Simplified for this app

  MangaApiModel({
    required this.malId,
    required this.url,
    required this.images,
    required this.title,
    this.titleEnglish,
    this.titleJapanese,
    required this.type,
    this.chapters,
    this.volumes,
    required this.status,
    required this.publishing,
    this.score,
    this.scoredBy,
    this.rank,
    this.popularity,
    this.members,
    this.favorites,
    this.synopsis,
    this.background,
  });

  // LEARN: factory constructor. This is a common pattern for creating instances
  // from JSON. It allows the constructor to return an instance of a subtype,
  // or even a cached instance, though here it's used for cleaner JSON parsing.
  factory MangaApiModel.fromJson(Map<String, dynamic> json) {
    return MangaApiModel(
      malId: _getInt(json['mal_id']),
      url: _getString(json['url']),
      images: MangaImages.fromJson(json['images'] ?? {}),
      title: _getString(json['title']),
      titleEnglish: _getString(json['title_english']),
      titleJapanese: _getString(json['title_japanese']),
      type: _getString(json['type']),
      chapters: _getInt(json['chapters']),
      volumes: _getInt(json['volumes']),
      status: _getString(json['status']),
      publishing: json['publishing'] is bool ? json['publishing'] : false,
      score: _getDouble(json['score']),
      scoredBy: _getInt(json['scored_by']),
      rank: _getInt(json['rank']),
      popularity: _getInt(json['popularity']),
      members: _getInt(json['members']),
      favorites: _getInt(json['favorites']),
      synopsis: _getString(json['synopsis']),
      background: _getString(json['background']),
    );
  }

  // Convenience getter for the primary image URL
  String get imageUrl => images.jpg.imageUrl.isNotEmpty
      ? images.jpg.imageUrl
      : images.webp.imageUrl; // Fallback to webp if jpg is empty

  String get displayTitle => titleEnglish ?? title;
}

class MangaImages {
  final MangaImageSet jpg;
  final MangaImageSet webp;

  MangaImages({required this.jpg, required this.webp});

  factory MangaImages.fromJson(Map<String, dynamic> json) {
    return MangaImages(
      jpg: MangaImageSet.fromJson(json['jpg'] ?? {}),
      webp: MangaImageSet.fromJson(json['webp'] ?? {}),
    );
  }
}

class MangaImageSet {
  final String imageUrl;
  final String smallImageUrl;
  final String largeImageUrl;

  MangaImageSet({
    required this.imageUrl,
    required this.smallImageUrl,
    required this.largeImageUrl,
  });

  factory MangaImageSet.fromJson(Map<String, dynamic> json) {
    return MangaImageSet(
      imageUrl: _getString(json['image_url']),
      smallImageUrl: _getString(json['small_image_url']),
      largeImageUrl: _getString(json['large_image_url']),
    );
  }
}

// Example for how you might extend for Genres, Authors etc. if needed
// class MangaGenre {
//   final int malId;
//   final String type;
//   final String name;
//   final String url;
//   MangaGenre({required this.malId, required this.type, required this.name, required this.url});
//   factory MangaGenre.fromJson(Map<String, dynamic> json) { /* ... */ }
// }