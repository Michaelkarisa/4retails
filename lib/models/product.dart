import 'package:hive_flutter/hive_flutter.dart';


@HiveType(typeId: 0)
class Product {
  @HiveField(0)
  final String id;
  @HiveField(1)
  final String name;
  @HiveField(2)
  final Map<String,dynamic> unitPrice;
  Product({required this.id, required this.name,required this.unitPrice});
}