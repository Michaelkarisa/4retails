import 'package:intl/intl.dart';
import '../models/product.dart';
import '../models/sale_entry.dart';
import '../models/stock_entry.dart';

String formatDateForDisplay(DateTime date) {
  final now = DateTime.now();
  if (date.day == now.day && date.month == now.month && date.year == now.year) {
    return 'Today';
  }
  return DateFormat('dd/MM/yyyy').format(date);
}