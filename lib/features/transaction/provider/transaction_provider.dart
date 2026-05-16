import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/transaction_database_helper.dart';
import '../models/ransaction_model.dart';
import '../models/transaction_model.dart';

// Provider principal — igual que savingGoalsProvider
final transactionProvider =
StateNotifierProvider<TransactionNotifier, List<TransactionModel>>(
      (ref) => TransactionNotifier(),
);

// Total de ingresos
final totalIncomeProvider = Provider<double>((ref) {
  final transactions = ref.watch(transactionProvider);
  return transactions
      .where((t) => t.isIncome)
      .fold(0.0, (sum, t) => sum + t.amount);
});

// Total de gastos
final totalExpenseProvider = Provider<double>((ref) {
  final transactions = ref.watch(transactionProvider);
  return transactions
      .where((t) => !t.isIncome)
      .fold(0.0, (sum, t) => sum + t.amount);
});

// Balance = ingresos - gastos
final balanceProvider = Provider<double>((ref) {
  return ref.watch(totalIncomeProvider) - ref.watch(totalExpenseProvider);
});

// Notifier — igual que SavingGoalsNotifier
class TransactionNotifier extends StateNotifier<List<TransactionModel>> {
  TransactionNotifier() : super([]) {
    loadTransactions();
  }

  Future<void> loadTransactions() async {
    state = await TransactionDatabaseHelper.instance.getTransactions();
  }

  Future<void> addTransaction(TransactionModel tx) async {
    final id =
    await TransactionDatabaseHelper.instance.insertTransaction(tx);
    state = [tx.copyWith(id: id), ...state];
  }

  Future<void> deleteTransaction(int id) async {
    await TransactionDatabaseHelper.instance.deleteTransaction(id);
    state = state.where((t) => t.id != id).toList();
  }
}

