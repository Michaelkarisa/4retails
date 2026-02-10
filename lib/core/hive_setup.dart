import 'package:hive_flutter/hive_flutter.dart';
import 'package:retails/models/hive_adapters/loan_entry_adapter.g.dart';
import 'package:retails/models/loan_entry.dart';
import 'package:retails/models/stock_removal.dart';
import '../models/hive_adapters/product_adapter.g.dart';
import '../models/hive_adapters/resolution_adapter.g.dart';
import '../models/hive_adapters/sale_entry_adapter.g.dart';
import '../models/hive_adapters/stock_entry_adapter.g.dart';
import '../models/product.dart';
import '../models/sale_entry.dart';
import '../models/stock_entry.dart';
import '../models/resolution.dart';

Future<void> initHive() async {
  try {
    await Hive.initFlutter();
    Hive.registerAdapter(ProductAdapter());
    Hive.registerAdapter(SaleEntryAdapter());
    Hive.registerAdapter(StockEntryAdapter());
    Hive.registerAdapter(ResolutionAdapter());
    Hive.registerAdapter(LoanEntryAdapter()); // TypeId 4
    Hive.registerAdapter(PaymentAdapter()); // TypeId 5
    Hive.registerAdapter(StockRemovalAdapter());
    await Hive.openBox<Product>('products');
    await Hive.openBox<SaleEntry>('sales');
    await Hive.openBox<StockEntry>('stock');
    await Hive.openBox<Resolution>('resolutions');
    await Hive.openBox<LoanEntry>('loans');
    await Hive.openBox<Payment>('payments');
    await Hive.openBox<StockRemoval>('stock_removals');
  }catch(e){
    print(e.toString());
  }
}