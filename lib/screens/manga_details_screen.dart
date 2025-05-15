import 'dart:io'; // ADDED for File
import 'package:flutter/material.dart';
import 'package:yakuza/api/jikan_api_service.dart';
import 'package:yakuza/database/manga_db_model.dart';
import 'package:yakuza/models/manga_api_model.dart';
import 'package:yakuza/providers/collection_provider.dart';
import 'package:yakuza/utils/constants.dart';
import 'package:yakuza/utils/helpers.dart';
import 'package:yakuza/widgets/status_dropdown.dart';
import 'package:provider/provider.dart';

class MangaDetailsScreen extends StatefulWidget {
  final int mangaId;
  final MangaApiModel? initialApiManga;

  const MangaDetailsScreen({
    super.key,
    required this.mangaId,
    this.initialApiManga,
  });

  @override
  State<MangaDetailsScreen> createState() => _MangaDetailsScreenState();
}

class _MangaDetailsScreenState extends State<MangaDetailsScreen> {
  final JikanApiService _apiService = JikanApiService();
  MangaApiModel? _apiManga;
  MangaDbModel? _dbManga;

  bool _isLoading = true;
  String? _error;

  final _formKey = GlobalKey<FormState>();
  String? _selectedUserStatus;
  final TextEditingController _notesController = TextEditingController();
  int _currentUserScore = 0;

  @override
  void initState() {
    super.initState();
    if (widget.initialApiManga != null) {
      _apiManga = widget.initialApiManga;
    }
    _loadMangaData();
  }

  Future<void> _loadMangaData() async {
    // LEARN: It's important to call setState at the beginning of async UI updates
    // and also within the `then` or `catchError` or `finally` blocks if those
    // also trigger UI changes.
    if(mounted) setState(() { _isLoading = true; _error = null; });

    final collectionProvider = Provider.of<CollectionProvider>(context, listen: false);
    // Try to get from DB first
    _dbManga = collectionProvider.getCollectedMangaById(widget.mangaId);

    if (_dbManga != null) {
      _selectedUserStatus = _dbManga!.userStatus;
      _notesController.text = _dbManga!.userNotes;
      _currentUserScore = _dbManga!.userScore;
      // If we have DB manga, we might not need to fetch API manga if _apiManga is already populated
      // or if we decide DB data is sufficient for display.
      // For full details, always try to have _apiManga.
      if (_apiManga == null) { // If we navigated directly to details of a collected item
        try {
          // Fetch API data to ensure we have the most complete info for display,
          // even if some of it is already in _dbManga.
          _apiManga = await _apiService.getMangaDetails(widget.mangaId);
        } catch (e) {
          if (mounted) {
            setState(() => _error = "Could not fetch latest API details: $e. Displaying cached data.");
          }
        }
      }
    } else if (_apiManga == null) { // Not in collection AND no initial data
      try {
        _apiManga = await _apiService.getMangaDetails(widget.mangaId);
      } catch (e) {
        if (mounted) setState(() => _error = e.toString());
      }
    }
    // If _apiManga is still null at this point (e.g. initialApiManga was null and fetch failed)
    // and _dbManga is also null, then we have a problem.

    if (mounted) setState(() => _isLoading = false);
  }


  @override
  void dispose() {
    _notesController.dispose();
    _apiService.dispose();
    super.dispose();
  }

  Widget _buildInfoRow(String label, String? value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(width: 100, child: Text('$label:', style: const TextStyle(fontWeight: FontWeight.bold))),
          Expanded(child: Text(value ?? 'N/A')),
        ],
      ),
    );
  }

  Widget _buildSynopsis(String? synopsis) {
    if (synopsis == null || synopsis.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Synopsis:', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 4),
          Text(synopsis, textAlign: TextAlign.justify),
        ],
      ),
    );
  }

  void _showEditAddDialog({bool isEditing = false}) {
    if (isEditing && _dbManga != null) {
      _selectedUserStatus = _dbManga!.userStatus;
      _notesController.text = _dbManga!.userNotes;
      _currentUserScore = _dbManga!.userScore;
    } else {
      _selectedUserStatus = AppConstants.userStatuses.first;
      _notesController.clear();
      _currentUserScore = 0;
    }

    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: Text(isEditing ? 'Edit Manga Details' : 'Add to Collection'),
              content: SingleChildScrollView(
                child: Form(
                  key: _formKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: <Widget>[
                      StatusDropdown(
                        currentStatus: _selectedUserStatus,
                        onChanged: (value) {
                          setDialogState(() { _selectedUserStatus = value; });
                        },
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _notesController,
                        decoration: const InputDecoration(
                          labelText: 'Your Notes',
                          border: OutlineInputBorder(),
                        ),
                        maxLines: 3,
                      ),
                      const SizedBox(height: 16),
                      Text('Your Score: $_currentUserScore / 10'),
                      Slider(
                        value: _currentUserScore.toDouble(),
                        min: 0,
                        max: 10,
                        divisions: 10,
                        label: _currentUserScore.toString(),
                        onChanged: (double value) {
                          setDialogState(() { _currentUserScore = value.toInt(); });
                        },
                      ),
                    ],
                  ),
                ),
              ),
              actions: <Widget>[
                TextButton(
                  child: const Text('Cancel'),
                  onPressed: () => Navigator.of(dialogContext).pop(),
                ),
                ElevatedButton(
                  child: Text(isEditing ? 'Save Changes' : 'Add Manga'),
                  onPressed: () async {
                    if (_formKey.currentState!.validate()) {
                      final collectionProvider = Provider.of<CollectionProvider>(context, listen: false);
                      // Show a loading indicator on the button or dialog
                      // For simplicity, we'll just let it run.
                      try {
                        if (isEditing && _dbManga != null) {
                          _dbManga!.userStatus = _selectedUserStatus!;
                          _dbManga!.userNotes = _notesController.text;
                          _dbManga!.userScore = _currentUserScore;
                          await collectionProvider.updateMangaInCollection(_dbManga!);
                          if (mounted) showAppSnackBar(context, 'Manga updated successfully!');
                        } else if (_apiManga != null) {
                          await collectionProvider.addMangaToCollection(
                            _apiManga!,
                            _selectedUserStatus!,
                            _notesController.text,
                            _currentUserScore,
                          );
                           if (mounted) showAppSnackBar(context, '${_apiManga!.displayTitle} added to collection!');
                        }
                        await _loadMangaData(); // Refresh main screen data
                        if (mounted) Navigator.of(dialogContext).pop();
                      } catch (e) {
                        if (mounted) showAppSnackBar(dialogContext, 'Error: $e', isError: true);
                      }
                    }
                  },
                ),
              ],
            );
          }
        );
      },
    );
  }

  void _confirmRemoveManga() async {
      final collectionProvider = Provider.of<CollectionProvider>(context, listen: false);
      final bool? confirmed = await showConfirmationDialog(
        context,
        'Remove Manga',
        'Are you sure you want to remove "${_dbManga?.title ?? _apiManga?.displayTitle}" from your collection?\nThis will also delete its downloaded cover image.',
        confirmText: "Remove"
      );

      if (confirmed == true && (_dbManga != null || _apiManga != null)) {
        try {
          int idToRemove = _dbManga?.malId ?? _apiManga!.malId;
          String titleRemoved = _dbManga?.title ?? _apiManga!.displayTitle;
          await collectionProvider.removeMangaFromCollection(idToRemove);
          if (mounted) {
            showAppSnackBar(context, '$titleRemoved removed from collection.');
            // After removal, _dbManga will be null.
            // _loadMangaData will refresh the state to reflect this.
             _loadMangaData(); // This will set _dbManga to null
          }
        } catch (e) {
           if (mounted) showAppSnackBar(context, 'Error removing manga: $e', isError: true);
        }
      }
  }

  // NEW HELPER WIDGET for cleaner image handling in details screen
  Widget _buildDetailImageWidget(BuildContext context) {
    // Use _dbManga for local path if available, otherwise _apiManga for network URL
    String? localPath = _dbManga?.localImagePath;
    String? networkUrl = _apiManga?.imageUrl ?? _dbManga?.imageUrl; // Fallback to dbManga's stored URL

    if (localPath != null && localPath.isNotEmpty) {
      File imageFile = File(localPath);
      return Image.file(
        imageFile,
        height: 250,
        fit: BoxFit.contain,
        errorBuilder: (context, error, stackTrace) {
          print("Error loading local image $localPath on details screen: $error. Falling back to network.");
          if (networkUrl != null && networkUrl.isNotEmpty) {
            return Image.network(
              networkUrl,
              height: 250, fit: BoxFit.contain,
              loadingBuilder: (ctx, child, progress) => progress == null ? child : Container(height: 250, color: Colors.grey[300], child: const Center(child: CircularProgressIndicator())),
              errorBuilder: (ctx, err, st) => Container(height: 250, color: Colors.grey[300], child: const Icon(Icons.broken_image, size: 60)),
            );
          }
          return Container(height: 250, color: Colors.grey[300], child: const Icon(Icons.broken_image, size: 60));
        },
      );
    }
    
    if (networkUrl != null && networkUrl.isNotEmpty) {
      return Image.network(
        networkUrl,
        height: 250,
        fit: BoxFit.contain,
        loadingBuilder: (context, child, loadingProgress) {
          if (loadingProgress == null) return child;
          return Container(height: 250, color: Colors.grey[300], child: const Center(child: CircularProgressIndicator()));
        },
        errorBuilder: (context, error, stackTrace) => Container(height: 250, color: Colors.grey[300], child: const Icon(Icons.broken_image, size: 60)),
      );
    }
    
    return Container(height: 250, color: Colors.grey[300], child: const Icon(Icons.image_not_supported, size: 60));
  }


  @override
  Widget build(BuildContext context) {
    // Determine if the manga is in collection by checking _dbManga AFTER _loadMangaData
    final bool isInCollection = _dbManga != null;

    final displayTitle = _apiManga?.displayTitle ?? _dbManga?.title ?? 'Loading...';

    return Scaffold(
      appBar: AppBar(
        title: Text(displayTitle, overflow: TextOverflow.ellipsis),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : (_apiManga == null && _dbManga == null) // If both are null after loading
              ? Center(child: Text('Error: Manga data not found. $_error', style: const TextStyle(color: Colors.red)))
              : _buildMangaContent(_apiManga, _dbManga), // Pass both, logic inside will pick
      floatingActionButton: _isLoading || (_apiManga == null && _dbManga == null)
        ? null
        : isInCollection
            ? FloatingActionButton.extended(
                onPressed: () => _showEditAddDialog(isEditing: true),
                label: const Text('Edit My Details'),
                icon: const Icon(Icons.edit),
              )
            : FloatingActionButton.extended(
                onPressed: () {
                  if(_apiManga != null) { // Ensure we have API manga to add
                     _showEditAddDialog(isEditing: false);
                  } else {
                    showAppSnackBar(context, "Cannot add to collection: API details missing.", isError: true);
                  }
                },
                label: const Text('Add to Collection'),
                icon: const Icon(Icons.add_circle_outline),
              ),
    );
  }

  Widget _buildMangaContent(MangaApiModel? apiData, MangaDbModel? dbData) {
    // Prioritize API data for general info, use dbData for user-specific or as fallback
    final String title = apiData?.displayTitle ?? dbData?.title ?? 'N/A';
    // Image display is handled by _buildDetailImageWidget
    final String? synopsis = apiData?.synopsis ?? dbData?.synopsis;
    final String? apiScore = (apiData?.score ?? dbData?.apiScore)?.toStringAsFixed(2);
    final String? type = apiData?.type ?? dbData?.mangaType;
    final String? status = apiData?.status ?? dbData?.apiStatus;
    final String? chapters = (apiData?.chapters ?? dbData?.chapters)?.toString();
    final String? volumes = (apiData?.volumes ?? dbData?.volumes)?.toString();

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (_error != null && apiData == null && dbData != null) // Show error if API failed but we have DB cache
            Padding(
              padding: const EdgeInsets.only(bottom: 8.0),
              child: Text('Warning: $_error', style: const TextStyle(color: Colors.orangeAccent)),
            ),
          Center(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(8.0),
              // MODIFIED: Use _buildDetailImageWidget
              child: _buildDetailImageWidget(context),
            ),
          ),
          const SizedBox(height: 16),
          Center(
            child: Text(
              title,
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(height: 16),
          _buildInfoRow('API Score', apiScore),
          _buildInfoRow('Type', type),
          _buildInfoRow('API Status', status),
          _buildInfoRow('Chapters', chapters),
          _buildInfoRow('Volumes', volumes),
          _buildSynopsis(synopsis),

          if (dbData != null) ...[
            const Divider(height: 32, thickness: 1),
            Text('My Collection Details:', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 8),
            _buildInfoRow('My Status', dbData.userStatus),
            _buildInfoRow('My Score', dbData.userScore > 0 ? '${dbData.userScore}/10' : 'Not Rated'),
            _buildInfoRow('My Notes', dbData.userNotes.isNotEmpty ? dbData.userNotes : 'No notes yet.'),
            _buildInfoRow('Date Added', dbData.dateAdded.substring(0,10)),
            const SizedBox(height: 20),
            Center(
              child: TextButton.icon(
                icon: const Icon(Icons.delete_outline, color: Colors.red),
                label: const Text('Remove from Collection', style: TextStyle(color: Colors.red)),
                onPressed: _confirmRemoveManga,
                style: TextButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10)),
              ),
            ),
          ],
          const SizedBox(height: 70),
        ],
      ),
    );
  }
}