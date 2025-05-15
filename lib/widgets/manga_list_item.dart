import 'dart:io'; // ADDED for File
import 'package:flutter/material.dart';
import 'package:yakuza/database/manga_db_model.dart';
import 'package:yakuza/models/manga_api_model.dart';

class MangaListItem extends StatelessWidget {
  final MangaApiModel? apiManga;
  final MangaDbModel? dbManga;
  final VoidCallback onTap;
  final bool isGridView;

  const MangaListItem({
    super.key,
    this.apiManga,
    this.dbManga,
    required this.onTap,
    this.isGridView = false,
  }) : assert(apiManga != null || dbManga != null, 'Either apiManga or dbManga must be provided');

  
  Widget _buildImageWidget(BuildContext context) {
    String? currentImageUrl = apiManga?.imageUrl ?? dbManga?.imageUrl;
    String? localPath = dbManga?.localImagePath;

    if (localPath != null && localPath.isNotEmpty) {
      // LEARN: Try to load from local file first if dbManga and localPath exist
      File imageFile = File(localPath);
      // Check if file actually exists, can be slow, usually optimistic load
      // if (await imageFile.exists()) { // This await makes the build method async, which is not ideal.
      // For simplicity, we'll assume if path exists, file exists, or Image.file handles error.
      return Image.file(
        imageFile,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) {
          // Fallback if local file is broken or path is invalid
          print("Error loading local image $localPath: $error. Falling back to network.");
          if (currentImageUrl != null && currentImageUrl.isNotEmpty) {
            return Image.network(
              currentImageUrl,
              fit: BoxFit.cover,
              loadingBuilder: (ctx, child, progress) => progress == null ? child : Container(color: Colors.grey[300], child: const Center(child: CircularProgressIndicator(strokeWidth: 2.0))),
              errorBuilder: (ctx, err, st) => Container(color: Colors.grey[300], child: const Icon(Icons.broken_image, size: 40, color: Colors.grey)),
            );
          }
          return Container(color: Colors.grey[300], child: const Icon(Icons.broken_image, size: 40, color: Colors.grey));
        },
      );
      // }
    }
    
    if (currentImageUrl != null && currentImageUrl.isNotEmpty) {
      // LEARN: Fallback to network image if no local path or apiManga
      return Image.network(
        currentImageUrl,
        fit: BoxFit.cover,
        loadingBuilder: (context, child, loadingProgress) {
          if (loadingProgress == null) return child;
          return Container(color: Colors.grey[300], child: const Center(child: CircularProgressIndicator(strokeWidth: 2.0)));
        },
        errorBuilder: (context, error, stackTrace) {
          return Container(color: Colors.grey[300], child: const Icon(Icons.broken_image, size: 40, color: Colors.grey));
        },
      );
    }
    
    // Default placeholder if no image source
    return Container(color: Colors.grey[300], child: const Icon(Icons.image_not_supported, size: 40, color: Colors.grey));
  }


  @override
  Widget build(BuildContext context) {
    final String title = apiManga?.displayTitle ?? dbManga?.title ?? 'No Title';
    // final String imageUrl = apiManga?.imageUrl ?? dbManga?.imageUrl ?? ''; // Replaced by _buildImageWidget
    final String? scoreText = apiManga?.score?.toStringAsFixed(2) ?? dbManga?.apiScore?.toStringAsFixed(2);
    final String? typeText = apiManga?.type ?? dbManga?.mangaType;

    if (isGridView) {
      return Card(
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                flex: 3,
                // MODIFIED: Use _buildImageWidget
                child: _buildImageWidget(context),
              ),
              Expanded(
                flex: 2,
                child: Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      if (typeText != null && typeText.isNotEmpty)
                        Text(
                          typeText,
                          style: Theme.of(context).textTheme.bodySmall,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      if (dbManga != null && dbManga!.userStatus.isNotEmpty)
                        Text(
                          dbManga!.userStatus,
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(fontStyle: FontStyle.italic),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    } else {
      // List view
      return Card(
        margin: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
        child: InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox( // MODIFIED: Wrap image in SizedBox for consistent sizing
                  width: 80,
                  height: 120,
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(4.0),
                    // MODIFIED: Use _buildImageWidget
                    child: _buildImageWidget(context),
                  )
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      if (typeText != null && typeText.isNotEmpty)
                        Text('Type: $typeText', style: Theme.of(context).textTheme.bodySmall),
                      if (scoreText != null)
                        Text('API Score: $scoreText', style: Theme.of(context).textTheme.bodySmall),
                      if (dbManga != null) ...[
                        const SizedBox(height: 4),
                        Text('Status: ${dbManga!.userStatus}', style: Theme.of(context).textTheme.bodySmall?.copyWith(fontStyle: FontStyle.italic)),
                        if (dbManga!.userScore > 0)
                           Text('My Score: ${dbManga!.userScore}/10', style: Theme.of(context).textTheme.bodySmall?.copyWith(fontStyle: FontStyle.italic)),
                      ]
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }
  }
}