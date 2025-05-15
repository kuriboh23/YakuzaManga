import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:yakuza/models/manga_api_model.dart';
import 'package:yakuza/utils/constants.dart';

class JikanApiService {
  final String _baseUrl = AppConstants.jikanApiBaseUrl;
  final http.Client _client;

  JikanApiService({http.Client? client}) : _client = client ?? http.Client();

  Future<JikanMangaSearchResponse> searchManga({String? query, int page = 1}) async {
    final Map<String, String> queryParameters = {
      'page': page.toString(),
      'limit': '25', // You can adjust this per page
    };

    String endpointPath;

    if (query != null && query.trim().isNotEmpty) {
      endpointPath = '/manga'; // Use /manga for active searching
      queryParameters['q'] = query.trim();
      // For /manga search, you might still want to add an order_by if desired
      queryParameters['sort'] = 'asc'; // or 'desc' based on your preference
      queryParameters['order_by'] = 'score';
    } else {
      // LEARN: For default browsing (no query), use the /top/manga endpoint.
      // This is more specific for getting popular/top manga.
      endpointPath = '/top/manga';
      // The /top/manga endpoint might support filters like 'type' or 'filter'
      // e.g., queryParameters['filter'] = 'bypopularity'; (already default)
      queryParameters['typde'] = 'manga'; // if you only want manga type
    }

    final uri = Uri.parse('$_baseUrl$endpointPath').replace(queryParameters: queryParameters);
    
    // LEARN: Added a print statement to see the exact URL being requested.
    // This is very helpful for debugging API calls.
    print('Jikan API Request URI: $uri');

    try {
      final response = await _client.get(uri).timeout(const Duration(seconds: 30));

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);
        final JikanMangaSearchResponse responseModel = JikanMangaSearchResponse.fromJson(data);
        print('Jikan API Response: ${responseModel.toString()}'); // Debug print for response
        return responseModel;
      } else {
        // LEARN: Print the response body for non-200 responses to get more error details from Jikan.
        print('Jikan API Error Response: ${response.body}');
        throw Exception('Failed to load manga: ${response.statusCode} ${response.reasonPhrase}');
      }
    } catch (e) {
      print('Error in searchManga: $e');
      // If the error is from the throw Exception above, it will be re-printed here.
      // If it's a different error (e.g., network issue before getting a status code), this print is useful.
      if (e is! Exception || !e.toString().contains('Failed to load manga')) {
          // Avoid re-printing the URI if it was already part of the caught exception's message details.
          // However, in this case, it's better to always know what URI caused the problem.
      }
      print('Request URI that failed: $uri'); // Helpful for all errors
      throw Exception('Failed to connect or parse manga search results: $e');
    }
  }

  Future<MangaApiModel> getMangaDetails(int mangaId) async {
    final uri = Uri.parse('$_baseUrl/manga/$mangaId');
    print('Jikan API Details Request URI: $uri'); // Debug print for details too

    try {
      final response = await _client.get(uri).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);
        if (data.containsKey('data') && data['data'] != null) {
             final detailResponse = JikanMangaDetailResponse.fromJson(data);
             return detailResponse.data;
        } else {
          throw Exception('Manga details not found in response for ID $mangaId');
        }
      } else {
        print('Jikan API Details Error Response: ${response.body}');
        throw Exception('Failed to load manga details: ${response.statusCode} ${response.reasonPhrase}');
      }
    } catch (e) {
      print('Error in getMangaDetails: $e');
      print('Details Request URI that failed: $uri');
      throw Exception('Failed to connect or parse manga details: $e');
    }
  }

  void dispose() {
    _client.close();
  }
}