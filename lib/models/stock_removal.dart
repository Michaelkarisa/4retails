import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';


@HiveType(typeId: 6)
class StockRemoval {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final String stockId;

  @HiveField(2)
  final String productName;

  @HiveField(3)
  final int quantity;

  @HiveField(4)
  final RemovalReason reason;

  @HiveField(5)
  final List<String> photosPaths;

  @HiveField(6)
  final String notes;

  @HiveField(7)
  final DateTime removedDate;

  @HiveField(8)
  final String removedBy;

  StockRemoval({
    required this.id,
    required this.stockId,
    required this.productName,
    required this.quantity,
    required this.reason,
    required this.photosPaths,
    required this.notes,
    required this.removedDate,
    required this.removedBy,
  });
}

@HiveType(typeId: 7)
enum RemovalReason {
  @HiveField(0)
  retailStocking,
  @HiveField(1)
  damaged,
  @HiveField(2)
  expired,
  @HiveField(3)
  stolen,
  @HiveField(4)
  returned,
  @HiveField(5)
  other;

  String get displayName {
    switch (this) {
      case RemovalReason.retailStocking:
        return 'Retail Stocking';
      case RemovalReason.damaged:
        return 'Damaged/Broken';
      case RemovalReason.expired:
        return 'Expired';
      case RemovalReason.stolen:
        return 'Stolen/Lost';
      case RemovalReason.returned:
        return 'Returned to Supplier';
      case RemovalReason.other:
        return 'Other';
    }
  }

  String get description {
    switch (this) {
      case RemovalReason.retailStocking:
        return 'Moving stock to retail floor or display';
      case RemovalReason.damaged:
        return 'Item is damaged, broken, or unusable';
      case RemovalReason.expired:
        return 'Item has passed expiration date';
      case RemovalReason.stolen:
        return 'Item was stolen or lost';
      case RemovalReason.returned:
        return 'Returning defective item to supplier';
      case RemovalReason.other:
        return 'Other reason not listed above';
    }
  }

  IconData get icon {
    switch (this) {
      case RemovalReason.retailStocking:
        return Icons.store;
      case RemovalReason.damaged:
        return Icons.broken_image;
      case RemovalReason.expired:
        return Icons.event_busy;
      case RemovalReason.stolen:
        return Icons.warning;
      case RemovalReason.returned:
        return Icons.keyboard_return;
      case RemovalReason.other:
        return Icons.more_horiz;
    }
  }

  Color get color {
    switch (this) {
      case RemovalReason.retailStocking:
        return Colors.blue;
      case RemovalReason.damaged:
        return Colors.red;
      case RemovalReason.expired:
        return Colors.orange;
      case RemovalReason.stolen:
        return Colors.purple;
      case RemovalReason.returned:
        return Colors.teal;
      case RemovalReason.other:
        return Colors.grey;
    }
  }

  bool get requiresPhoto {
    return this == RemovalReason.damaged || this == RemovalReason.expired;
  }
}
