import 'package:hive_flutter/hive_flutter.dart';
import 'product.dart';


@HiveType(typeId: 1)
class SaleEntry {
  @HiveField(0)
  final String id;
  @HiveField(1)
  final Product product;
  @HiveField(2)
  final DateTime date;
  @HiveField(3)
  final int quantity;
  @HiveField(4)
  final String primaryUnit;
  @HiveField(5)
  final String secondaryUnit;
  @HiveField(6)
  final double pricePerItem;
  @HiveField(7)
  final bool paid;
  @HiveField(8)
  final DateTime? paidDate;
  SaleEntry({
    required this.id,
    required this.product,
    required this.date,
    required this.quantity,
    required this.primaryUnit,
    required this.secondaryUnit,
    required this.pricePerItem,
    required this.paid,
    this.paidDate,
  });

  double get total => quantity * pricePerItem;
}