import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/saving_goal.dart';

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._init();
  static Database? _database;

  DatabaseHelper._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('finangoal_goals.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);

    return await openDatabase(path, version: 1, onCreate: _createDB);
  }

  Future _createDB(Database db, int version) async {
    await db.execute('''
      CREATE TABLE saving_goals (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        targetAmount REAL NOT NULL,
        savedAmount REAL NOT NULL,
        emoji TEXT NOT NULL
      )
    ''');
  }

  Future<int> insertGoal(SavingGoal goal) async {
    final db = await instance.database;
    return await db.insert('saving_goals', goal.toMap());
  }

  Future<List<SavingGoal>> getGoals() async {
    final db = await instance.database;
    final result = await db.query('saving_goals');
    return result.map((map) => SavingGoal.fromMap(map)).toList();
  }

  Future<int> updateGoal(SavingGoal goal) async {
    final db = await instance.database;
    return await db.update(
      'saving_goals',
      goal.toMap(),
      where: 'id = ?',
      whereArgs: [goal.id],
    );
  }
}
