import 'package:flutter/material.dart';
import 'package:hive_flutter/adapters.dart';
import 'package:uuid/uuid.dart';
import '../../models/product.dart';
import '../../models/stock_entry.dart';
import '../../service/data_service.dart';



class RemoveStockScreen extends StatefulWidget {
  const RemoveStockScreen({super.key});

  @override
  State<RemoveStockScreen> createState() => _RemoveStockScreenState();
}

class _RemoveStockScreenState extends State<RemoveStockScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Remove Stock"),
      ),
      body: Column(
        children: [

        ],
      ),
    );
  }
}
