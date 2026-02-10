import 'package:hive_flutter/hive_flutter.dart';
import '../sale_entry.dart';
import '../product.dart';

class SaleEntryAdapter extends TypeAdapter<SaleEntry> {
  @override
  final int typeId = 1;

  @override
  SaleEntry read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return SaleEntry(
      id: fields[0] as String,
      product: fields[1] as Product,
      date: fields[2] as DateTime,
      quantity: fields[3] as double,
      primaryUnit: fields[4] as String,
      pricePerItem: fields[5] as double,
      paid: fields[6] as bool? ?? false,
      paidDate: fields[7] as DateTime?,
    );
  }

  @override
  void write(BinaryWriter writer, SaleEntry obj) {
    writer
      ..writeByte(7)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.product)
      ..writeByte(2)
      ..write(obj.date)
      ..writeByte(3)
      ..write(obj.quantity)
      ..writeByte(4)
      ..write(obj.primaryUnit)
      ..writeByte(5)
      ..write(obj.pricePerItem);
  }
}