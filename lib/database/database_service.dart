import 'dart:io'; // ADDED for File operations if deleting images with DB records

import 'package:yakuza/database/manga_db_model.dart';
import 'package:yakuza/utils/constants.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart' as p; // Alias for path package
import 'package:path_provider/path_provider.dart';

// LEARN: This service class handles all SQLite database operations.
// It encapsulates database initialization, table creation, and CRUD operations.
class DatabaseService {
  // LEARN: Singleton pattern. This ensures that only one instance of DatabaseService
  // exists throughout the app, preventing multiple database connections.
  static final DatabaseService _instance = DatabaseService._internal();
  factory DatabaseService() => _instance;
  DatabaseService._internal();

  static Database? _database;

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB();
    return _database!;
  }

  Future<Database> _initDB() async {
    final documentsDirectory = await getApplicationDocumentsDirectory();
    final path = p.join(documentsDirectory.path, AppConstants.databaseName);

    return await openDatabase(
      path,
      version: AppConstants.databaseVersion, // Ensure this is 1 if you uninstalled, or increment if migrating
      onCreate: _onCreate,
      // onUpgrade: _onUpgrade, // Needed for schema migrations
    );
  }

  // LEARN: This method is called only when the database is created for the first time.
  // It's where you define your table schemas.
  Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE ${AppConstants.tableManga} (
        ${AppConstants.columnMalId} INTEGER PRIMARY KEY,
        ${AppConstants.columnTitle} TEXT NOT NULL,
        ${AppConstants.columnImageUrl} TEXT NOT NULL,
        ${AppConstants.columnLocalImagePath} TEXT, 
        ${AppConstants.columnSynopsis} TEXT,
        ${AppConstants.columnApiScore} REAL,
        ${AppConstants.columnMangaType} TEXT,
        ${AppConstants.columnApiStatus} TEXT,
        ${AppConstants.columnChapters} INTEGER,
        ${AppConstants.columnVolumes} INTEGER,
        ${AppConstants.columnUserStatus} TEXT NOT NULL,
        ${AppConstants.columnUserNotes} TEXT,
        ${AppConstants.columnUserScore} INTEGER,
        ${AppConstants.columnDateAdded} TEXT NOT NULL
      )
    ''');
  }

  // --- CRUD Operations ---

  // CREATE
  Future<int> addManga(MangaDbModel manga) async {
    final db = await database;
    return await db.insert(
      AppConstants.tableManga,
      manga.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  // READ one
  Future<MangaDbModel?> getMangaById(int malId) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      AppConstants.tableManga,
      where: '${AppConstants.columnMalId} = ?',
      whereArgs: [malId],
    );

    if (maps.isNotEmpty) {
      return MangaDbModel.fromMap(maps.first);
    }
    return null;
  }

  // READ all (with optional filter and sort)
  Future<List<MangaDbModel>> getAllManga({String? sortBy, String? filterByStatus}) async {
    final db = await database;
    String? whereClause;
    List<dynamic>? whereArgs;
    String? orderBy;

    if (filterByStatus != null && filterByStatus.isNotEmpty) {
      whereClause = '${AppConstants.columnUserStatus} = ?';
      whereArgs = [filterByStatus];
    }

    if (sortBy != null) {
      if (sortBy == AppConstants.columnTitle) {
        orderBy = '${AppConstants.columnTitle} ASC';
      }
    } else {
      orderBy = '${AppConstants.columnDateAdded} DESC'; // Default sort
    }

    final List<Map<String, dynamic>> maps = await db.query(
      AppConstants.tableManga,
      where: whereClause,
      whereArgs: whereArgs,
      orderBy: orderBy,
    );

    return List.generate(maps.length, (i) {
      return MangaDbModel.fromMap(maps[i]);
    });
  }

  // UPDATE
  Future<int> updateManga(MangaDbModel manga) async {
    final db = await database;
    return await db.update(
      AppConstants.tableManga,
      manga.toMap(),
      where: '${AppConstants.columnMalId} = ?',
      whereArgs: [manga.malId],
    );
  }

  // DELETE
  // MODIFIED: Now returns the MangaDbModel for potential image deletion by caller
  Future<MangaDbModel?> deleteMangaAndReturn(int malId) async {
    final db = await database;
    // First, get the manga to access its localImagePath
    MangaDbModel? mangaToDelete = await getMangaById(malId);

    if (mangaToDelete != null) {
      final count = await db.delete(
        AppConstants.tableManga,
        where: '${AppConstants.columnMalId} = ?',
        whereArgs: [malId],
      );
      if (count > 0) {
        return mangaToDelete; // Return the model if deletion was successful
      }
    }
    return null; // Return null if manga not found or deletion failed
  }


  Future<void> close() async {
    final db = await database;
    db.close();
    _database = null;
  }
}