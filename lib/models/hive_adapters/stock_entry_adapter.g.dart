import 'package:hive_flutter/hive_flutter.dart';
import '../stock_entry.dart';
import '../product.dart';
import '../stock_removal.dart';

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

class StockRemovalAdapter extends TypeAdapter<StockRemoval> {
  @override
  final int typeId = 6;

  @override
  StockRemoval read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return StockRemoval(
      id: fields[0] as String,
      stockId: fields[1] as String,
      productName: fields[2] as String,
      quantity: fields[3] as int,
      reason: fields[4] as RemovalReason,
      photosPaths: (fields[5] as List).cast<String>(),
      notes: fields[6] as String,
      removedDate: fields[7] as DateTime,
      removedBy: fields[8] as String,
    );
  }

  @override
  void write(BinaryWriter writer, StockRemoval obj) {
    writer
      ..writeByte(9)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.stockId)
      ..writeByte(2)
      ..write(obj.productName)
      ..writeByte(3)
      ..write(obj.quantity)
      ..writeByte(4)
      ..write(obj.reason)
      ..writeByte(5)
      ..write(obj.photosPaths)
      ..writeByte(6)
      ..write(obj.notes)
      ..writeByte(7)
      ..write(obj.removedDate)
      ..writeByte(8)
      ..write(obj.removedBy);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
          other is StockRemovalAdapter &&
              runtimeType == other.runtimeType &&
              typeId == other.typeId;
}

class RemovalReasonAdapter extends TypeAdapter<RemovalReason> {
  @override
  final int typeId = 7;

  @override
  RemovalReason read(BinaryReader reader) {
    final index = reader.readByte();
    return RemovalReason.values[index];
  }

  @override
  void write(BinaryWriter writer, RemovalReason obj) {
    writer.writeByte(obj.index);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
          other is RemovalReasonAdapter &&
              runtimeType == other.runtimeType &&
              typeId == other.typeId;
}