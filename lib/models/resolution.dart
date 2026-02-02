import 'package:hive_flutter/hive_flutter.dart';

@HiveType(typeId: 3)
class Resolution {
  @HiveField(0)
  final String id;
  @HiveField(1)
  final DateTime date;
  @HiveField(2)
  final String resolution;
  @HiveField(3)
  final String dataSnapshot; // e.g., JSON snapshot

  Resolution({
    required this.id,
    required this.date,
    required this.resolution,
    required this.dataSnapshot,
  });
}