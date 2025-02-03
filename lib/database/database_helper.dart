import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class DatabaseHelper {
  static final DatabaseHelper _instance = DatabaseHelper._();
  static Database? _database;

  DatabaseHelper._();

  factory DatabaseHelper() => _instance;

  // Getter for the database
  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  // Initialize the SQLite database
  Future<Database> _initDatabase() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, 'todo_app.db');

    return await openDatabase(
      path,
      version: 2, // Increment the version to trigger the schema update
      onCreate: _onCreate,
      onUpgrade: _onUpgrade, // Handle schema updates
    );
  }

  // Create the necessary tables
  Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE users (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        username TEXT NOT NULL,
        email TEXT NOT NULL,
        password TEXT NOT NULL,
        profile_picture TEXT
      )
    ''');

    await db.execute('''
      CREATE TABLE tasks (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        task TEXT NOT NULL,
        isDone INTEGER NOT NULL,
        dateAdded TEXT NOT NULL,
        username TEXT NOT NULL
      )
    ''');
  }

  // Handle schema updates
  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      // Add the profile_picture column to the users table
      await db.execute('ALTER TABLE users ADD COLUMN profile_picture TEXT');
    }
  }

  // Insert a new user into the database
  Future<int> insertUser(Map<String, dynamic> user) async {
    final db = await database;
    return await db.insert('users', user);
  }

  // Fetch user by credentials
  Future<Map<String, dynamic>?> getUser(String username, String password) async {
    final db = await database;
    final results = await db.query(
      'users',
      where: 'username = ? AND password = ?',
      whereArgs: [username, password],
    );
    return results.isNotEmpty ? results.first : null;
  }

  // Update the profile picture path for a user
  Future<void> updateProfilePicture(String username, String imagePath) async {
    final db = await database;
    await db.update(
      'users',
      {'profile_picture': imagePath},
      where: 'username = ?',
      whereArgs: [username],
    );
  }

  // Get the profile picture path for a user
  Future<String?> getProfilePicture(String username) async {
    final db = await database;
    final results = await db.query(
      'users',
      columns: ['profile_picture'],
      where: 'username = ?',
      whereArgs: [username],
    );
    return results.isNotEmpty ? results.first['profile_picture'] as String? : null;
  }

  // Insert a new task into the database
  Future<int> insertTask(Map<String, dynamic> task) async {
    final db = await database;
    return await db.insert('tasks', task);
  }

  // Get all tasks for a specific user
  Future<List<Map<String, dynamic>>> getTasksByUser(String username) async {
    final db = await database;
    return await db.query(
      'tasks',
      where: 'username = ?',
      whereArgs: [username],
      orderBy: 'dateAdded DESC',
    );
  }

  // Delete a task by ID
  Future<int> deleteTask(int id) async {
    final db = await database;
    return await db.delete('tasks', where: 'id = ?', whereArgs: [id]);
  }

  // Update the status of a task
  Future<int> updateTaskStatus(int id, bool isDone) async {
    final db = await database;
    return await db.update(
      'tasks',
      {'isDone': isDone ? 1 : 0},
      where: 'id = ?',
      whereArgs: [id],
    );
  }
}