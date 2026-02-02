import 'package:hive_flutter/hive_flutter.dart';
import 'package:retails/models/loan_entry.dart';
import 'package:uuid/uuid.dart';
import '../models/sale_entry.dart';
import '../models/stock_entry.dart';
import '../models/resolution.dart';

class DataService {
  static final DataService _instance = DataService._internal();
  factory DataService() => _instance;
  DataService._internal();

  final _salesBox = Hive.box<SaleEntry>('sales');
  final _stockBox = Hive.box<StockEntry>('stock');
  final _resolutionsBox = Hive.box<Resolution>('resolutions');
  final _loanBox = Hive.box<LoanEntry>('loans');
  bool isNet = false;

  // ==================== SALES ====================
  List<SaleEntry> getSalesByDate(DateTime date) {
    return _salesBox.values
        .where((s) =>
    s.date.year == date.year &&
        s.date.month == date.month &&
        s.date.day == date.day)
        .toList();
  }

  Future<void> updateSale(SaleEntry saleEntry) async {
    await _salesBox.delete(saleEntry.id);
    await _salesBox.put(saleEntry.id, saleEntry);
  }

  double getTotalSalesByDate(DateTime date) {
    return getSalesByDate(date).fold(0.0, (sum, s) => sum + s.total);
  }

  Future<void> addSale(SaleEntry sale) async {
    await _salesBox.put(sale.id, sale);
  }

  List<SaleEntry> allSales() {
    return _salesBox.values.toList();
  }

  Future<void> deleteSale(String id) async {
    await _salesBox.delete(id);
  }

  // ==================== STOCK ====================
  List<StockEntry> getStockByDate(DateTime date) {
    return _stockBox.values
        .where((s) =>
    s.entryDate.year == date.year &&
        s.entryDate.month == date.month &&
        s.entryDate.day == date.day)
        .toList();
  }

  Future<void> updateStock(StockEntry stockEntry) async {
    await _stockBox.delete(stockEntry.id);
    await _stockBox.put(stockEntry.id, stockEntry);
  }

  List<StockEntry> allStocks() {
    return _stockBox.values.toList();
  }

  Future<void> addStock(StockEntry stock) async {
    await _stockBox.put(stock.id, stock);
  }

  Future<void> deleteStock(String id) async {
    await _stockBox.delete(id);
  }

  Future<int> stockReceived() async {
    return getStockByDate(DateTime.now()).length;
  }

  Future<int> stockPicked() async {
    final date = DateTime.now();
    return _stockBox.values
        .where((s) =>
    s.pickedDate?.year == date.year &&
        s.pickedDate?.month == date.month &&
        s.pickedDate?.day == date.day &&
        s.picked == true)
        .toList()
        .length;
  }

  Future<int> availableStock() async {
    return _stockBox.values.where((s) => s.picked == false).toList().length;
  }

  Future<bool> lowStock() async {
    return _stockBox.values.where((s) => s.picked == false).toList().length < 5;
  }

  // ==================== RESOLUTIONS ====================
  Future<void> addResolution(Resolution resolution) async {
    await _resolutionsBox.put(resolution.id, resolution);
  }

  List<Resolution> getResolutions() {
    return _resolutionsBox.values.toList()
      ..sort((a, b) => b.date.compareTo(a.date));
  }

  // ==================== LOANS/DEBTS ====================

  /// Add a new loan entry
  Future<void> addLoan(LoanEntry loanEntry) async {
    await _loanBox.put(loanEntry.id, loanEntry);
  }

  /// Update an existing loan entry
  Future<void> updateLoan(LoanEntry loanEntry) async {
    await _loanBox.delete(loanEntry.id);
    await _loanBox.put(loanEntry.id, loanEntry);
  }

  /// Delete a loan entry
  Future<void> deleteLoan(String id) async {
    await _loanBox.delete(id);
  }

  /// Get all loan entries
  Future<List<LoanEntry>> getDebts() async {
    return _loanBox.values.toList()
      ..sort((a, b) => b.date.compareTo(a.date));
  }

  /// Get all debts with their associated sales
  Future<Map<LoanEntry, List<SaleEntry>>> getAllDebts() async {
    Map<LoanEntry, List<SaleEntry>> allDebts = {};
    List<SaleEntry> allSales = _salesBox.values.toList();
    List<LoanEntry> allLoans = _loanBox.values.toList();

    for (var loan in allLoans) {
      final sales = allSales.where((sale) => sale.id == loan.saleId).toList();
      allDebts[loan] = sales;
    }

    return allDebts;
  }

  /// Get pending (unpaid) debts
  Future<List<LoanEntry>> getPendingDebts() async {
    return _loanBox.values.where((loan) => !loan.isPaid).toList()
      ..sort((a, b) => b.date.compareTo(a.date));
  }

  /// Get paid debts
  Future<List<LoanEntry>> getPaidDebts() async {
    return _loanBox.values.where((loan) => loan.isPaid).toList()
      ..sort((a, b) => b.date.compareTo(a.date));
  }

  /// Record a payment for a loan
  Future<void> recordPayment({
    required String loanId,
    required double amount,
    String? notes,
  }) async {
    final loan = _loanBox.get(loanId);
    if (loan == null) {
      throw Exception('Loan not found');
    }

    if (amount <= 0) {
      throw Exception('Payment amount must be positive');
    }

    if (amount > loan.balance) {
      throw Exception('Payment amount cannot exceed balance');
    }

    final payment = Payment(
      id: const Uuid().v4(),
      amount: amount,
      date: DateTime.now(),
      notes: notes,
    );

    final updatedPayments = [...loan.payments, payment];
    final newAmountPaid = loan.amountPaid + amount;
    final isPaid = newAmountPaid >= loan.totalAmount;

    final updatedLoan = loan.copyWith(
      amountPaid: newAmountPaid,
      payments: updatedPayments,
      isPaid: isPaid,
      paidDate: isPaid ? DateTime.now() : null,
    );

    await updateLoan(updatedLoan);
  }

  /// Mark a loan as fully paid
  Future<void> markLoanAsPaid(String loanId) async {
    final loan = _loanBox.get(loanId);
    if (loan == null) {
      throw Exception('Loan not found');
    }

    if (loan.isPaid) {
      return; // Already paid
    }

    final balance = loan.balance;
    Payment? finalPayment;

    // If there's a remaining balance, create a final payment
    if (balance > 0) {
      finalPayment = Payment(
        id: const Uuid().v4(),
        amount: balance,
        date: DateTime.now(),
        notes: 'Final payment - marked as paid',
      );
    }

    final updatedPayments = finalPayment != null
        ? [...loan.payments, finalPayment]
        : loan.payments;

    final updatedLoan = loan.copyWith(
      amountPaid: loan.totalAmount,
      payments: updatedPayments,
      isPaid: true,
      paidDate: DateTime.now(),
    );

    await updateLoan(updatedLoan);
  }

  /// Get total outstanding debt across all loans
  Future<double> getTotalOutstandingDebt() async {
    return _loanBox.values
        .where((loan) => !loan.isPaid)
        .fold<double>(0.0, (sum, loan) => sum + loan.balance);
  }

  /// Get total debt amount across all loans
  Future<double> getTotalDebtAmount() async {
    return _loanBox.values
        .fold<double>(0.0, (sum, loan) => sum + loan.totalAmount);
  }

  /// Get total amount paid across all loans
  Future<double> getTotalAmountPaid() async {
    return _loanBox.values
        .fold<double>(0.0, (sum, loan) => sum + loan.amountPaid);
  }

  /// Get loans for a specific customer (by name or phone)
  Future<List<LoanEntry>> getLoansByCustomer({
    String? name,
    String? phone,
  }) async {
    return _loanBox.values.where((loan) {
      if (name != null && loan.name.toLowerCase().contains(name.toLowerCase())) {
        return true;
      }
      if (phone != null && loan.phone.contains(phone)) {
        return true;
      }
      return false;
    }).toList()
      ..sort((a, b) => b.date.compareTo(a.date));
  }

  /// Get debt statistics
  Future<Map<String, dynamic>> getDebtStatistics() async {
    final allLoans = _loanBox.values.toList();
    final pendingLoans = allLoans.where((loan) => !loan.isPaid).toList();
    final paidLoans = allLoans.where((loan) => loan.isPaid).toList();

    final totalDebt = allLoans.fold<double>(0.0, (sum, loan) => sum + loan.totalAmount);
    final totalPaid = allLoans.fold<double>(0.0, (sum, loan) => sum + loan.amountPaid);
    final totalBalance = allLoans.fold<double>(0.0, (sum, loan) => sum + loan.balance);

    return {
      'totalLoans': allLoans.length,
      'pendingLoans': pendingLoans.length,
      'paidLoans': paidLoans.length,
      'totalDebt': totalDebt,
      'totalPaid': totalPaid,
      'totalBalance': totalBalance,
      'collectionRate': totalDebt > 0 ? (totalPaid / totalDebt) * 100 : 0.0,
    };
  }
}