import 'package:hive_flutter/hive_flutter.dart';
import '../loan_entry.dart';

class LoanEntryAdapter extends TypeAdapter<LoanEntry> {
  @override
  final int typeId = 4;

  @override
  LoanEntry read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return LoanEntry(
      id: fields[0] as String,
      saleId: fields[1] as String,
      date: fields[2] as DateTime,
      name: fields[3] as String,
      phone: fields[4] as String,
      totalAmount: fields[5] as double? ?? 0.0,
      amountPaid: fields[6] as double? ?? 0.0,
      isPaid: fields[7] as bool? ?? false,
      paidDate: fields[8] as DateTime?,
      payments: (fields[9] as List?)?.cast<Payment>() ?? [],
    );
  }

  @override
  void write(BinaryWriter writer, LoanEntry obj) {
    writer
      ..writeByte(10) // Updated field count
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.saleId)
      ..writeByte(2)
      ..write(obj.date)
      ..writeByte(3)
      ..write(obj.name)
      ..writeByte(4)
      ..write(obj.phone)
      ..writeByte(5)
      ..write(obj.totalAmount)
      ..writeByte(6)
      ..write(obj.amountPaid)
      ..writeByte(7)
      ..write(obj.isPaid)
      ..writeByte(8)
      ..write(obj.paidDate)
      ..writeByte(9)
      ..write(obj.payments);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
          other is LoanEntryAdapter &&
              runtimeType == other.runtimeType &&
              typeId == other.typeId;
}

class PaymentAdapter extends TypeAdapter<Payment> {
  @override
  final int typeId = 5;

  @override
  Payment read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return Payment(
      id: fields[0] as String,
      amount: fields[1] as double,
      date: fields[2] as DateTime,
      notes: fields[3] as String?,
    );
  }

  @override
  void write(BinaryWriter writer, Payment obj) {
    writer
      ..writeByte(4)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.amount)
      ..writeByte(2)
      ..write(obj.date)
      ..writeByte(3)
      ..write(obj.notes);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
          other is PaymentAdapter &&
              runtimeType == other.runtimeType &&
              typeId == other.typeId;
}