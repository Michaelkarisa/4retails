import 'package:hive_flutter/hive_flutter.dart';
import '../stock_entry.dart';
import '../product.dart';

class StockEntryAdapter extends TypeAdapter<StockEntry> {
  @override
  final int typeId = 2;

  @override
  StockEntry read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return StockEntry(
      id: fields[0] as String,
      product: fields[1] as Product,
      entryDate: fields[2] as DateTime,
      primaryUnitQuantity: fields[3] as int,
      primaryUnit: fields[4] as String,
      secondaryUnit: fields[5] as String,
      buyingPrice: fields[6] as double,
      sellingPrice: fields[7] as double,
      picked: fields[8] as bool,
      secondaryUnitQuantity: fields[9] as int,
      pickedDate:fields[10] as DateTime,
    );
  }

  @override
  void write(BinaryWriter writer, StockEntry obj) {
    writer
      ..writeByte(11)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.product)
      ..writeByte(2)
      ..write(obj.entryDate)
      ..writeByte(3)
      ..write(obj.primaryUnitQuantity)
      ..writeByte(4)
      ..write(obj.primaryUnit)
      ..writeByte(5)
      ..write(obj.secondaryUnit)
      ..writeByte(6)
      ..write(obj.buyingPrice)
      ..writeByte(7)
      ..write(obj.sellingPrice)
      ..writeByte(8)
      ..write(obj.picked)
      ..writeByte(9)
      ..write(obj.pickedDate)
      ..writeByte(10)
      ..write(obj.secondaryUnitQuantity);
  }
}