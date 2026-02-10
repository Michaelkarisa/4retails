import 'package:hive_flutter/hive_flutter.dart';

@HiveType(typeId: 4)
class LoanEntry {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final List<String> saleIds;

  @HiveField(2)
  final DateTime date;

  @HiveField(3)
  final String name;

  @HiveField(4)
  final String phone;

  @HiveField(5)
  final double totalAmount;

  @HiveField(6)
  final bool isPaid;

  @HiveField(7)
  final DateTime? paidDate;

  @HiveField(8)
  final List<Payment> payments;

  LoanEntry({
    required this.id,
    required this.saleIds,
    required this.date,
    required this.name,
    required this.phone,
    required this.totalAmount,
    this.isPaid = false,
    this.paidDate,
    this.payments = const [],
  });

  double get amountPaid => payments.fold<double>(0.0, (sum, loan) => sum + loan.amount);
  double get balance => totalAmount - amountPaid;

  double get percentagePaid => totalAmount > 0 ? (amountPaid / totalAmount) * 100 : 0.0;

  LoanEntry copyWith({
    String? id,
    String? saleId,
    DateTime? date,
    String? name,
    String? phone,
    double? totalAmount,
    double? amountPaid,
    bool? isPaid,
    DateTime? paidDate,
    List<Payment>? payments,
  }) {
    return LoanEntry(
      id: id ?? this.id,
      saleIds: saleIds ?? this.saleIds,
      date: date ?? this.date,
      name: name ?? this.name,
      phone: phone ?? this.phone,
      totalAmount: totalAmount ?? this.totalAmount,
      isPaid: isPaid ?? this.isPaid,
      paidDate: paidDate ?? this.paidDate,
      payments: payments ?? this.payments,
    );
  }
}

@HiveType(typeId: 5)
class Payment {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final double amount;

  @HiveField(2)
  final DateTime date;

  @HiveField(3)
  final String? notes;

  Payment({
    required this.id,
    required this.amount,
    required this.date,
    this.notes,
  });
}