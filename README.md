# Manga Collector - Flutter App

A Flutter application that allows users to search for manga using the Jikan.moe API, view details, and maintain a personal collection of tracked manga. Collected manga includes custom notes, statuses, and scores, with cover images downloaded and stored locally for offline access using SQLite.

## Présentation du projet (Project Overview)

This application serves as a practical exercise in Flutter development, focusing on:
*   Fetching data from a public API (Jikan.moe), including browsing top manga and specific searches.
*   Implementing pagination for API results.
*   Parsing JSON data into Dart objects.
*   Downloading and storing images locally for offline use.
*   Local data persistence using SQLite via the `sqflite` plugin, including storing paths to local images.
*   Implementing CRUD (Create, Read, Update, Delete) operations for the local collection.
*   Building an intuitive user interface with Flutter widgets, including a toggleable list/grid view.
*   Basic state management using the `provider` package.

## Objectifs pédagogiques (Learning Objectives)

*   Mastering HTTP requests in Flutter (`http` package), including handling different API endpoints.
*   Understanding JSON parsing in Dart (`dart:convert`).
*   Using SQLite with `sqflite` for local storage, including storing file paths.
*   Implementing file download and local file system operations (`dart:io`, `path_provider`, `path`).
*   Managing and deleting local files associated with database records.
*   Implementing full CRUD operations.
*   Organizing a Flutter application with a simple architecture (UI, Services, Models, Providers).
*   Learning fundamental Flutter widgets, UI construction (ListView, GridView), and stateful interactions.
*   Implementing UI features like pagination, search debouncing, and view toggles.

## Description fonctionnelle (Functional Description)

The "Manga Collector" app enables users to:

1.  **Parcourir les mangas populaires (Browse Popular Manga):** View a list of top/popular manga from Jikan.moe upon opening the search/browse screen, with infinite scrolling pagination.
2.  **Rechercher des mangas (Search Manga):** Search for specific manga by title via the Jikan.moe API, with results also paginated.
3.  **Consulter les détails d'un manga (View Manga Details):** Displaying information like synopsis, score, type, image, etc.
4.  **Ajouter un manga à sa collection personnelle (Add to Collection):** Store manga details, download its cover image locally, and save user-defined status (e.g., "Reading", "Completed"), personal notes, and a personal score in a local SQLite database.
5.  **Modifier les informations personnelles (Edit Personal Info):** Update the status, notes, and score for a manga in the collection.
6.  **Supprimer un manga de sa collection (Remove from Collection):** Delete a manga from the local SQLite database and remove its downloaded cover image from the device.
7.  **Afficher la collection hors ligne (View Collection Offline):** View collected manga details and their cover images even without an internet connection.
8.  **Filtrer/Trier la collection (Filter/Sort Collection):** Filter collected manga by user status and sort by title.
9.  **Changer la vue d'affichage (Toggle View):** Switch between list view and grid view for displaying manga lists.

## Exigences techniques (Technical Requirements)

### Partie 1: API et HTTP (API and HTTP)

*   **Service API (`jikan_api_service.dart`):** Manages API calls using the `http` package to `/top/manga` (for browsing) and `/manga` (for search and details).
*   **Recherche et Navigation (Search and Browse):** Implemented with pagination support.
*   **Parsing JSON:** JSON data is parsed into Dart objects (`MangaApiModel`, `Pagination`).
*   **Gestion des erreurs (Error Handling):** Basic error handling for network connection issues (timeouts, socket exceptions) and API error responses.
*   **Affichage des résultats (Displaying Results):** Search/browse results are displayed in a scrollable list/grid on the `SearchScreen`.

### Partie 2: SQLite, Fichiers Locaux et sqflite (SQLite, Local Files, and sqflite)

*   **Configuration SQLite (`database_service.dart`):** `sqflite` is configured to initialize a database named `manga_collection.db`. The schema includes a column (`local_image_path`) to store the file path of downloaded cover images.
*   **Téléchargement et Gestion d'Images (`collection_provider.dart`):**
    *   Images are downloaded using the `http` package when a manga is added to the collection.
    *   Images are saved to the application's documents directory using `path_provider` and `dart:io`.
    *   Local image files are deleted when a manga is removed from the collection.
*   **Opérations CRUD (CRUD Operations):**
    *   **Create:** `addManga()` adds a new manga to the `manga` table (after downloading its image).
    *   **Read:** `getMangaById()` retrieves a specific manga, `getAllManga()` retrieves all (with filter/sort).
    *   **Update:** `updateManga()` modifies an existing manga's user-specific data.
    *   **Delete:** `deleteMangaAndReturn()` removes a manga from the table and returns the model to facilitate image file deletion by the provider.
*   **Modèle de données local (`manga_db_model.dart`):** `MangaDbModel` defines the structure for manga stored locally, including API fields, user-specific fields, and `localImagePath`.
*   **Synchronisation UI/DB (UI/DB Sync):** The `CollectionProvider` manages the state of the local collection, coordinates image downloads/deletions, fetches data from `DatabaseService`, and uses `notifyListeners()` to update the UI.
*   **Filtre/Tri (Filter/Sort):** `MyCollectionScreen` allows filtering by user status and sorting by title.

## Diagramme de structure de l'application (Application Structure Diagram)

```mermaid
graph TD
    subgraph UI Layer (Screens & Widgets)
        MainScreen -- Manages Navigation --> SearchScreen
        MainScreen -- Manages Navigation --> MyCollectionScreen
        SearchScreen -- Navigates to --> MangaDetailsScreen
        MyCollectionScreen -- Navigates to --> MangaDetailsScreen

        SearchScreen -- Uses --> JikanApiService
        MangaDetailsScreen -- Uses --> JikanApiService
        MangaDetailsScreen -- Interacts with --> CollectionProvider
        MyCollectionScreen -- Interacts with --> CollectionProvider
        SearchScreen -- Displays --> MangaListItem
        MyCollectionScreen -- Displays --> MangaListItem
        MangaListItem -- Displays Image from --> LocalFileSystem[Local File System (via Image.file)]
        MangaListItem -- Or Displays Image from --> Network[Network (via Image.network - fallback/API search)]
    end

    subgraph State Management
        CollectionProvider[CollectionProvider (Provider)]
    end

    subgraph Service Layer
        JikanApiService -- HTTP Requests --> JikanAPI[api.jikan.moe]
        DatabaseService -- SQLite Ops --> SQLiteDatabase[SQLite (sqflite)]
        ImageFileService[Image File Service (Integrated in CollectionProvider)] -- File I/O --> LocalFileSystem
    end

    subgraph Model Layer
        MangaApiModel[API Manga Model (includes Pagination)]
        MangaDbModel[Local DB Manga Model (includes localImagePath)]
    end

    CollectionProvider -- Uses --> DatabaseService
    CollectionProvider -- Uses --> ImageFileService
    CollectionProvider -- Uses --> JikanApiService indirectly for image URL to download

    JikanApiService -- Parses to --> MangaApiModel
    DatabaseService -- Uses/Stores --> MangaDbModel
    UI Layer -- Displays data from --> MangaApiModel
    UI Layer -- Displays/Manipulates --> MangaDbModel

    %% Data Flow for Image Download
    %% MangaDetailsScreen -- Add Action --> CollectionProvider
    %% CollectionProvider -- Gets imageURL from ApiMangaModel --> ImageFileService
    %% ImageFileService -- Downloads image from Network --> Network
    %% ImageFileService -- Saves image to --> LocalFileSystem
    %% ImageFileService -- Returns localPath to --> CollectionProvider
    %% CollectionProvider -- Updates MangaDbModel with localPath --> DatabaseService
```

**Explanation of Diagram Additions:**

*   `MangaListItem` now conditionally loads images from the `Local File System` (if a local path is available in `MangaDbModel`) or falls back to the `Network`.
*   An "Image File Service" concept (currently integrated within `CollectionProvider`) is shown to handle the download, saving, and deletion of image files from the `Local File System`.

## Choix d'implémentation (Implementation Choices)

*   **Langage/Framework:** Flutter (Dart) for cross-platform mobile development.
*   **API Client:** `http` package.
*   **Local Database:** `sqflite` for direct SQL control over the SQLite database.
*   **Local Image Storage:** Manual download and storage of images to the application's document directory (`path_provider`, `dart:io`). This ensures full offline availability of collected manga covers at the cost of increased storage and implementation complexity. The alternative, `cached_network_image`, was considered but full offline control was prioritized for this implementation.
*   **State Management:** `provider` package (`ChangeNotifier`, `Consumer`) for its simplicity and effectiveness for this application's scale.
*   **Architecture:** A layered approach (UI, Providers, Services, Models) to maintain separation of concerns.
*   **Error Handling:** `try-catch` blocks for API and file operations, with errors propagated to the UI (SnackBars, text messages). Specific handling for `TimeoutException` and `SocketException` for network calls.
*   **User Experience:** Material Design components, loading indicators, pagination for long lists, debounced search, list/grid view toggle, and clear error/feedback messages.
*   **Code Comments:** Standard comments and `// LEARN:` educational comments.

## Livrables (Deliverables)

*   Code source complet et organisé (Complete and organized source code).
*   Démonstration fonctionnelle de l'application (Functional demonstration - this document and code serve as the basis).
*   Un rapport court expliquant les choix d'implémentation (This section).
*   Un diagramme de classes ou de structure de l'application (Included above).

## Critères d'évaluation (Evaluation Criteria) - Self-Assessment

*   **Qualité et organisation du code:** Code is organized into logical folders. Classes and methods aim for single responsibility.
*   **Respect des bonnes pratiques Flutter/Dart:** Use of `const`, `async/await`, proper resource disposal, `provider` for state management, immutable principles where practical.
*   **Fonctionnalités implémentées correctement:** Browsing, searching, pagination, details view, add/edit/delete from collection (including local image management), offline image display for collection, filter/sort.
*   **Interface utilisateur intuitive et responsive:** UI uses standard Material components. Basic responsiveness handled by Flutter's layout widgets.