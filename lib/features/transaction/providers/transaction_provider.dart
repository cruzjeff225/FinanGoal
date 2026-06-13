import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:finan_goal/core/services/api_service.dart';
import '../data/transaction_database_helper.dart';
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

// Notifier — igual que SavingGoalsNotifier con soporte Offline-First + Sincronización
class TransactionNotifier extends StateNotifier<List<TransactionModel>> {
  TransactionNotifier() : super([]) {
    loadTransactions();
  }

  Future<void> loadTransactions() async {
    try {
      // 1. Intentar cargar desde MongoDB Atlas en la nube
      final List cloudData = await ApiService.getTransactions();
      final cloudTxs = cloudData.map((map) => TransactionModel.fromMap(map)).toList();

      // 2. Si tiene éxito, refrescar el caché local de SQLite
      await TransactionDatabaseHelper.instance.clearTransactions();
      for (final tx in cloudTxs) {
        await TransactionDatabaseHelper.instance.insertTransaction(tx);
      }

      // 3. Emitir el estado fresco leído desde SQLite para tener los IDs autoincrementados correctos
      state = await TransactionDatabaseHelper.instance.getTransactions();
    } catch (e) {
      // 4. Si falla (sin internet), cargar caché local de SQLite como fallback inmediato
      state = await TransactionDatabaseHelper.instance.getTransactions();
    }
  }

  Future<void> addTransaction(TransactionModel tx) async {
    // 1. Guardar localmente en SQLite inmediatamente (soporte offline e instantáneo)
    final localId = await TransactionDatabaseHelper.instance.insertTransaction(tx);
    final localTx = tx.copyWith(id: localId);
    
    // Emitir el nuevo estado local al principio de la lista
    state = [localTx, ...state];

    // 2. Intentar registrar de forma remota en MongoDB Atlas
    try {
      final cloudRes = await ApiService.createTransaction(localTx.toApiMap());
      if (cloudRes.containsKey('_id') || cloudRes.containsKey('id')) {
        final cloudId = cloudRes['_id'] ?? cloudRes['id'];
        
        // Guardar la referencia remota en SQLite
        await TransactionDatabaseHelper.instance.updateCloudId(localId, cloudId);
        
        // Actualizar el estado en memoria para reflejar la sincronización exitosa
        state = [
          for (final t in state)
            if (t.id == localId) t.copyWith(cloudId: cloudId) else t,
        ];
      }
    } catch (e) {
      // Si falla la red, queda guardado localmente listo para sincronizaciones futuras
    }
  }

  Future<void> updateTransaction(TransactionModel tx) async {
    if (tx.id == null) return;

    // 1. Actualizar localmente en SQLite
    await TransactionDatabaseHelper.instance.updateTransaction(tx);

    // Actualizar el estado en memoria
    state = [
      for (final t in state)
        if (t.id == tx.id) tx else t,
    ];

    // 2. Intentar actualizar remotamente si tiene un cloudId
    if (tx.cloudId != null && tx.cloudId!.isNotEmpty) {
      try {
        await ApiService.updateTransaction(tx.cloudId!, tx.toApiMap());
      } catch (e) {
        // Fallo de red silencioso (los cambios locales permanecen en SQLite)
      }
    }
  }

  Future<void> deleteTransaction(int localId) async {
    final txIndex = state.indexWhere((t) => t.id == localId);
    if (txIndex == -1) return;

    final tx = state[txIndex];
    final cloudId = tx.cloudId;

    // 1. Eliminar localmente de SQLite y del estado en memoria
    await TransactionDatabaseHelper.instance.deleteTransaction(localId);
    state = state.where((t) => t.id != localId).toList();

    // 2. Si el registro ya estaba sincronizado en la nube, eliminar de MongoDB Atlas
    if (cloudId != null && cloudId.isNotEmpty) {
      try {
        await ApiService.deleteTransaction(cloudId);
      } catch (e) {
        // Error de red al eliminar remotamente (falla silenciosa)
      }
    }
  }
}