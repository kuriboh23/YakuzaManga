import 'dart:async';
import 'package:flutter/material.dart';
import 'package:yakuza/api/jikan_api_service.dart';
import 'package:yakuza/models/manga_api_model.dart';
import 'package:yakuza/screens/manga_details_screen.dart';
import 'package:yakuza/utils/helpers.dart';
import 'package:yakuza/widgets/manga_list_item.dart';
import 'dart:io';


// LEARN: This screen now acts as a browse/search screen.
// It fetches an initial list of manga and supports pagination and searching.
class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final TextEditingController _searchController = TextEditingController();
  final JikanApiService _apiService = JikanApiService();
  final ScrollController _scrollController = ScrollController(); // For pagination

  List<MangaApiModel> _mangaList = [];
  Pagination? _paginationInfo;
  int _currentPage = 1;
  String? _currentQuery; // To store the current search query for pagination

  bool _isLoading = false;
  bool _isLoadingMore = false; // For loading next page
  String? _error;
  bool _isGridView = false; // Toggle for list/grid view
  Timer? _debounce; // For debouncing search input

  @override
  void initState() {
    super.initState();
    _fetchManga(); // Fetch initial list
    _scrollController.addListener(_onScroll);
    _searchController.addListener(_onSearchChanged); // Add listener for debouncing
  }

  @override
  void dispose() {
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    _apiService.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  // LEARN: Debouncing search to avoid API calls on every keystroke
  void _onSearchChanged() {
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    _debounce = Timer(const Duration(milliseconds: 700), () {
      if (_searchController.text.trim() != (_currentQuery ?? "").trim()) {
         _performSearch();
      }
    });
  }

  Future<void> _fetchManga({bool isSearch = false, bool loadMore = false}) async {
    if (!loadMore) { // Full reload or new search
      setState(() {
        _isLoading = true;
        _error = null;
        if (!isSearch) { // If not a search, it's a default fetch
          _currentQuery = null; // Reset query for default fetch
        }
      });
    } else { // Loading more items
      if (!_paginationInfo!.hasNextPage || _isLoadingMore) return; // No more pages or already loading
      setState(() {
        _isLoadingMore = true;
      });
    }

    try {
      final response = await _apiService.searchManga(
        query: _currentQuery,
        page: _currentPage,
      );

      if (mounted) {
        setState(() {
          if (loadMore) {
            _mangaList.addAll(response.data); // Append new data
          } else {
            _mangaList = response.data; // Replace with new data
          }
          _paginationInfo = response.pagination;
          if (_mangaList.isEmpty && (_currentQuery != null && _currentQuery!.isNotEmpty)) {
            _error = 'No results found for "$_currentQuery".';
          }
        });
      }
    } catch (e) {
    if (mounted) {
      String errorMessage = e.toString();
      if (e is TimeoutException) {
        errorMessage = 'The request timed out. The server might be busy or your connection is slow. Please try again later.';
      } else if (e is SocketException) { // dart:io, for network unreachable type errors
        errorMessage = 'Could not connect to the server. Please check your internet connection.';
      }
      setState(() {
        _error = errorMessage;
        // If loading more failed, we might show a snackbar instead of clearing the list
        // if (!loadMore) { _mangaList = []; } // Only clear if it's not a "load more" operation
      });
      // Only show snackbar if it's not an initial load error where _error text is displayed
      if (loadMore || _mangaList.isNotEmpty) {
        showAppSnackBar(context, 'Error: $errorMessage', isError: true);
      }
    }
  } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _isLoadingMore = false;
        });
      }
    }
  }

  // LEARN: Called when user submits search or debounce triggers
  void _performSearch() {
    final query = _searchController.text.trim();
    if (query.isEmpty && _currentQuery == null) return; // No change from default list

    _currentPage = 1; // Reset to first page for new search
    _currentQuery = query.isEmpty ? null : query; // If empty, fetch default list
    _mangaList.clear(); // Clear previous results for a new search
    _paginationInfo = null; // Reset pagination
    _fetchManga(isSearch: true);
  }

  void _onScroll() {
    // LEARN: Detect if user has scrolled to the bottom of the list
    if (_scrollController.position.pixels >= _scrollController.position.maxScrollExtent - 200 && // -200 to load a bit before end
        _paginationInfo != null &&
        _paginationInfo!.hasNextPage &&
        !_isLoadingMore && !_isLoading) {
      _currentPage++;
      _fetchManga(loadMore: true);
    }
  }

  void _navigateToDetails(MangaApiModel manga) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => MangaDetailsScreen(mangaId: manga.malId, initialApiManga: manga),
      ),
    );
  }

  void _toggleView() {
    setState(() {
      _isGridView = !_isGridView;
    });
  }

  Widget _buildMangaContent() {
    if (_mangaList.isEmpty) {
      if (_isLoading) return const SizedBox.shrink(); // Loading indicator handled globally
      if (_error != null && _error!.isNotEmpty) return Center(child: Text(_error!, style: const TextStyle(color: Colors.red)));
      return const Center(child: Text('No manga found. Try searching or check connection.'));
    }

    // LEARN: Conditional rendering for ListView or GridView
    if (_isGridView) {
      return GridView.builder(
        controller: _scrollController,
        padding: const EdgeInsets.all(8.0),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2, // Or 3 for smaller items
          childAspectRatio: 0.65, // Adjust for your item's look
          crossAxisSpacing: 8.0,
          mainAxisSpacing: 8.0,
        ),
        itemCount: _mangaList.length + (_isLoadingMore ? 1 : 0), // +1 for loader
        itemBuilder: (context, index) {
          if (index == _mangaList.length && _isLoadingMore) {
            return const Center(child: CircularProgressIndicator());
          }
          final manga = _mangaList[index];
          return MangaListItem(
            apiManga: manga,
            onTap: () => _navigateToDetails(manga),
            isGridView: true,
          );
        },
      );
    } else {
      return ListView.builder(
        controller: _scrollController,
        itemCount: _mangaList.length + (_isLoadingMore ? 1 : 0), // +1 for loader
        itemBuilder: (context, index) {
          if (index == _mangaList.length && _isLoadingMore) {
            return const Padding(
              padding: EdgeInsets.symmetric(vertical: 16.0),
              child: Center(child: CircularProgressIndicator()),
            );
          }
          final manga = _mangaList[index];
          return MangaListItem(
            apiManga: manga,
            onTap: () => _navigateToDetails(manga),
            isGridView: false,
          );
        },
      );
    }
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Browse & Search Manga'),
        actions: [
          IconButton(
            icon: Icon(_isGridView ? Icons.view_list : Icons.grid_view),
            onPressed: _toggleView,
            tooltip: _isGridView ? 'List View' : 'Grid View',
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                labelText: 'Search manga title',
                hintText: 'e.g., Berserk, One Piece',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchController.clear();
                          _performSearch(); // This will fetch default list
                        },
                      )
                    : null,
                border: const OutlineInputBorder(),
              ),
              // onSubmitted: (_) => _performSearch(), // Debounce handles this
            ),
          ),
          // LEARN: Global loading indicator for initial load or full search reload
          if (_isLoading && !_isLoadingMore)
            const Expanded(child: Center(child: CircularProgressIndicator()))
          else
            Expanded(child: _buildMangaContent()),
        ],
      ),
    );
  }
}