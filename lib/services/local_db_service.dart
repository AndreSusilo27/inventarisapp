import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class LocalDBService {
  static final LocalDBService _instance = LocalDBService._internal();
  static Database? _database;

  LocalDBService._internal();

  factory LocalDBService() => _instance;

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB();
    return _database!;
  }

  Future<Database> _initDB() async {
    String path = join(await getDatabasesPath(), 'inventory_app.db');
    return await openDatabase(
      path,
      version: 2, // Incremented version for database migration
      onCreate: _onCreateDB,
      onUpgrade: _onUpgradeDB,
    );
  }

  Future<void> _onCreateDB(Database db, int version) async {
    await db.execute('''
      CREATE TABLE Users (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        email TEXT UNIQUE NOT NULL,
        name TEXT,
        password TEXT,
        photo TEXT,  -- Column for user photo
        role TEXT
      )
    ''');

    await db.execute('''
      CREATE TABLE Categories (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        description TEXT
      )
    ''');

    await db.execute('''
      CREATE TABLE Items (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        category TEXT,
        quantity INTEGER NOT NULL,
        location TEXT,
        description TEXT,
        photo TEXT
      )
    ''');

    await db.execute('''
      CREATE TABLE Transactions (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        item_id INTEGER NOT NULL,
        transaction_type TEXT NOT NULL,
        quantity INTEGER NOT NULL,
        date TEXT NOT NULL,
        user_id INTEGER NOT NULL,
        notes TEXT,
        FOREIGN KEY (item_id) REFERENCES Items(id),
        FOREIGN KEY (user_id) REFERENCES Users(id)
      )
    ''');
  }

  Future<void> _onUpgradeDB(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      await db.execute('ALTER TABLE Users ADD COLUMN photo TEXT');
    }
  }

  // CRUD Operations for Users Table

  Future<int> addUser(Map<String, dynamic> user) async {
    final db = await database;
    return await db.insert(
      'Users',
      user,
      conflictAlgorithm: ConflictAlgorithm.replace, // Overwrite if user exists
    );
  }

  Future<Map<String, dynamic>?> getUserByEmail(String email) async {
    final db = await database;
    final result = await db.query(
      'Users',
      where: 'email = ?',
      whereArgs: [email],
    );
    return result.isNotEmpty ? result.first : null;
  }

  Future<Map<String, dynamic>?> getUserByEmailAndPassword(
      String email, String password) async {
    final db = await database;
    final result = await db.query(
      'Users',
      where: 'email = ? AND password = ?',
      whereArgs: [email, password],
    );
    return result.isNotEmpty ? result.first : null;
  }

  Future<int> updateUser(String email, Map<String, dynamic> updatedData) async {
    final db = await database;
    return await db.update(
      'Users',
      updatedData,
      where: 'email = ?',
      whereArgs: [email],
    );
  }

  Future<List<Map<String, dynamic>>> getAllUsers() async {
    final db = await database;
    return await db.query('Users');
  }

  // saveUser: Add or update user data based on email
  Future<void> saveUser(Map<String, dynamic> user) async {
    final existingUser = await getUserByEmail(user['email']);
    if (existingUser == null) {
      await addUser(user); // Insert new user if not exists
    } else {
      await updateUser(user['email'], user); // Update if user already exists
    }
  }

  // Categories Table
  Future<int> addCategory(Map<String, dynamic> category) async {
    final db = await database;
    return await db.insert('Categories', category);
  }

  Future<List<Map<String, dynamic>>> getAllCategories() async {
    final db = await database;
    return await db.query('Categories');
  }

  // Items Table
  Future<int> addItem(Map<String, dynamic> item) async {
    final db = await database;
    return await db.insert('Items', item);
  }

  Future<List<Map<String, dynamic>>> getAllItems() async {
    final db = await database;
    return await db.query('Items');
  }

  Future<int> updateItem(int id, Map<String, dynamic> item) async {
    final db = await database;
    return await db.update(
      'Items',
      item,
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<int> deleteItem(int id) async {
    final db = await database;
    return await db.delete(
      'Items',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // Transactions Table
  Future<int> addTransaction(Map<String, dynamic> transaction) async {
    final db = await database;
    return await db.insert('Transactions', transaction);
  }

  Future<List<Map<String, dynamic>>> getTransactionsByItemId(int itemId) async {
    final db = await database;
    return await db.query(
      'Transactions',
      where: 'item_id = ?',
      whereArgs: [itemId],
    );
  }

  Future<List<Map<String, dynamic>>> getAllTransactions() async {
    final db = await database;
    return await db.query('Transactions');
  }
}
