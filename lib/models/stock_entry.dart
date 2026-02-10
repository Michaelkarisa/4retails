import 'package:hive_flutter/hive_flutter.dart';
import 'product.dart';


@HiveType(typeId: 2)
class StockEntry {
  @HiveField(0)
  final String id;
  @HiveField(1)
  final Product product;
  @HiveField(2)
  final DateTime entryDate;
  @HiveField(3)
  final String primaryUnit;
  @HiveField(4)
  final String secondaryUnit;
  @HiveField(5)
  final double buyingPrice;
  @HiveField(6)
  final double sellingPrice;
  @HiveField(7)
  final bool picked;
  @HiveField(8)
  final DateTime? pickedDate;
  @HiveField(9)
  final int primaryUnitQuantity;
  @HiveField(10)
  final int secondaryUnitQuantity;
  StockEntry({
    required this.id,
    required this.product,
    required this.entryDate,
    required this.primaryUnitQuantity,
    required this.primaryUnit,
    required this.secondaryUnitQuantity,
    required this.secondaryUnit,
    required this.buyingPrice,
    required this.sellingPrice,
    required this.picked,
    this.pickedDate,
  });

  double get projectedProfit => (sellingPrice  * secondaryUnitQuantity*primaryUnitQuantity) - buyingPrice;
}
