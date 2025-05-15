import 'package:flutter/material.dart';
import 'package:yakuza/database/manga_db_model.dart';
import 'package:yakuza/providers/collection_provider.dart';
import 'package:yakuza/screens/manga_details_screen.dart';
import 'package:yakuza/utils/constants.dart';
import 'package:yakuza/widgets/manga_list_item.dart';
import 'package:provider/provider.dart';

// LEARN: This screen displays the user's personal collection of manga
// stored in the local SQLite database.
class MyCollectionScreen extends StatefulWidget {
  const MyCollectionScreen({super.key});

  @override
  State<MyCollectionScreen> createState() => _MyCollectionScreenState();
}

class _MyCollectionScreenState extends State<MyCollectionScreen> {

  @override
  void initState() {
    super.initState();
    // LEARN: It's good practice to fetch initial data in initState or didChangeDependencies.
    // Here, we use `WidgetsBinding.instance.addPostFrameCallback` to ensure that
    // the Provider.of call happens after the widget tree is built, avoiding potential issues.
    // The CollectionProvider constructor already calls fetchCollection, so this might be
    // redundant if the provider is initialized early enough. However, if navigating
    // back and forth, an explicit refresh might be desired or handled by the provider.
    // For this simple app, the provider's constructor fetch should be sufficient.
    // If manual refresh is needed:
    // WidgetsBinding.instance.addPostFrameCallback((_) {
    //   Provider.of<CollectionProvider>(context, listen: false).fetchCollection();
    // });
  }

  void _navigateToDetails(MangaDbModel manga) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => MangaDetailsScreen(mangaId: manga.malId),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // LEARN: `Consumer` widget is a common way to listen to a Provider.
    // It rebuilds its `builder` function whenever the listened-to `CollectionProvider`
    // calls `notifyListeners()`.
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Manga Collection'),
        actions: [
          // LEARN: PopupMenuButton for filter/sort options.
          Consumer<CollectionProvider>( // Consumer specifically for the actions
            builder: (context, provider, child) {
              return PopupMenuButton<String>(
                icon: const Icon(Icons.filter_list),
                onSelected: (String value) {
                  if (value == 'clear_filter') {
                    provider.setFilter(null);
                  } else if (AppConstants.userStatuses.contains(value)) {
                    provider.setFilter(value);
                  } else if (value == 'sort_title') {
                    provider.setSortBy(AppConstants.columnTitle);
                  }
                  // Add more sort options if needed
                },
                itemBuilder: (BuildContext context) {
                  List<PopupMenuEntry<String>> items = [];
                  items.add(const PopupMenuItem<String>(
                    value: 'sort_title',
                    child: Text('Sort by Title'),
                  ));
                  // Add other sort options here (e.g., by date added)

                  items.add(const PopupMenuDivider());
                  items.add(const PopupMenuItem<String>(
                    value: 'clear_filter',
                    child: Text('Show All (Clear Filter)'),
                  ));
                  for (String status in AppConstants.userStatuses) {
                    items.add(CheckedPopupMenuItem<String>(
                      value: status,
                      checked: provider.currentFilter == status,
                      child: Text('Filter: $status'),
                    ));
                  }
                  return items;
                },
              );
            }
          ),
        ],
      ),
      body: Consumer<CollectionProvider>(
        builder: (context, collectionProvider, child) {
          // LEARN: Handling different states: loading, error, empty, or has data.
          if (collectionProvider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          // Error handling could be more sophisticated, e.g., checking an error field in provider
          // For now, we assume if not loading and empty, it's either truly empty or an error occurred during fetch.

          if (collectionProvider.collectedManga.isEmpty) {
            return Center(
              child: Text(
                collectionProvider.currentFilter == null
                    ? 'Your collection is empty.\nGo search and add some manga!'
                    : 'No manga found for filter: "${collectionProvider.currentFilter}".',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.headlineSmall,
              ),
            );
          }

          // LEARN: Displaying the list of collected manga.
          return ListView.builder(
            itemCount: collectionProvider.collectedManga.length,
            itemBuilder: (context, index) {
              final manga = collectionProvider.collectedManga[index];
              return MangaListItem(
                dbManga: manga,
                onTap: () => _navigateToDetails(manga),
              );
            },
          );
        },
      ),
    );
  }
}