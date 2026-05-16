import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/ransaction_model.dart';
import '../models/transaction_model.dart';

class TransactionDatabaseHelper {
  static final TransactionDatabaseHelper instance =
  TransactionDatabaseHelper._init();
  static Database? _database;

  TransactionDatabaseHelper._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('finangoal_transactions.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);
    return await openDatabase(path, version: 1, onCreate: _createDB);
  }

  Future _createDB(Database db, int version) async {
    await db.execute('''
      CREATE TABLE transactions (
        id          INTEGER PRIMARY KEY AUTOINCREMENT,
        amount      REAL    NOT NULL,
        description TEXT    NOT NULL,
        category    TEXT    NOT NULL,
        isIncome    INTEGER NOT NULL,
        date        TEXT    NOT NULL
      )
    ''');
  }

  Future<int> insertTransaction(TransactionModel tx) async {
    final db = await instance.database;
    return await db.insert('transactions', tx.toMap());
  }

  Future<List<TransactionModel>> getTransactions() async {
    final db = await instance.database;
    final result = await db.query('transactions', orderBy: 'date DESC');
    return result.map((map) => TransactionModel.fromMap(map)).toList();
  }

  Future<int> deleteTransaction(int id) async {
    final db = await instance.database;
    return await db.delete('transactions', where: 'id = ?', whereArgs: [id]);
  }
}