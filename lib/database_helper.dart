import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:task_management/task_model.dart';
import 'package:task_management/transaction_model.dart';

class DatabaseHelper {
  static Database? _database;

  // Membuka database
  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB();
    return _database!;
  }

  Future<Database> _initDB() async {
    String path = join(await getDatabasesPath(), 'task.db');
    return await openDatabase(
      path,
      version: 1,
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE tasks (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            title TEXT,
            description TEXT,
            time TEXT,
            date TEXT,
            isDone INTEGER
          )
        ''');
        await db.execute('''
          CREATE TABLE transactions (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          title TEXT,
          amount INTEGER,
          isExpense INTEGER,
          date TEXT,
          category TEXT)
          ''');
      },
      onUpgrade: (db, oldVersion, newVersion) async {
        if (oldVersion < 2) {
          await db.execute('''
          CREATE TABLE transaction IF NOT EXIST (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            title TEXT,
            amount INTEGER,
            isExpense INTEGER,
            date TEXT,
            category TEXT
          )
        ''');
        }
      },
    );
  }

  Future<void> insertTask(TaskItem task) async {
    final db = await database;
    await db.insert('tasks', task.toMap());
  }

  Future<void> updateTask(TaskItem task) async {
    final db = await database;
    await db.update(
      'tasks',
      task.toMap(),
      where: 'id = ?',
      whereArgs: [task.id],
    );
  }

  Future<List<TaskItem>> getTasksByDate(String date) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'tasks',
      where: 'date = ?',
      whereArgs: [date],
    );
    return List.generate(maps.length, (i) => TaskItem.fromMap(maps[i]));
  }

  Future<void> insertTransaction(TransactionItem item) async {
    final db = await database;
    await db.insert('transactions', item.toMap());
  }

  Future<List<TransactionItem>> getTransactions() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'transactions',
      orderBy: "date DESC",
    );
    return List.generate(maps.length, (i) => TransactionItem.fromMap(maps[i]));
  }

  Future<void> _ensureTransactionTable(Database db) async {
    final result = await db.rawQuery(
      "SELECT name FROM sqlite_master WHERE type='table' AND name='transactions'",
    );

    if (result.isEmpty) {
      await db.execute('''
          CREATE TABLE transaction IF NOT EXIST (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            title TEXT,
            amount INTEGER,
            isExpense INTEGER,
            date TEXT,
            category TEXT
          )
        ''');
    }
  }
}
