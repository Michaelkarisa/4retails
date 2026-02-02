import 'package:flutter/material.dart';
import 'package:hive_flutter/adapters.dart';
import 'package:uuid/uuid.dart';
import '../../models/product.dart';
import '../../models/stock_entry.dart';
import '../../service/data_service.dart';

class AddStockScreen extends StatefulWidget {
  const AddStockScreen({Key? key}) : super(key: key);

  @override
  State<AddStockScreen> createState() => _AddStockScreenState();
}

class _AddStockScreenState extends State<AddStockScreen> {
  final _formKey = GlobalKey<FormState>();
  String? _productName;
  String _primaryUnit = 'Box';
  String _secondaryUnit = 'Piece';
  final _quantityController = TextEditingController();
  final _quantityController1 = TextEditingController();
  final _buyingPriceController = TextEditingController();
  final _sellingPriceController = TextEditingController();

  final List<String> _primaryUnits = ['Box', 'Can', 'Carton', 'Bag'];
  final List<String> _secondaryUnits = ['Piece', 'Kg', 'Litre'];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Add Stock'),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Product Name
            TextFormField(
              decoration: InputDecoration(
                labelText: 'Product Name',
                hintText: 'e.g., Maize Flour, Cooking Oil',
                border: const OutlineInputBorder(),
                prefixIcon: const Icon(Icons.inventory),
                suffixIcon: _productName != null && _productName!.isNotEmpty
                    ? IconButton(
                  icon: const Icon(Icons.clear, size: 18),
                  onPressed: () {
                    setState(() {
                      _productName = null;
                    });
                  },
                )
                    : null,
              ),
              onChanged: (value) => _productName = value.trim(),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Product name is required';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),

            // Quantity + Primary Unit
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _quantityController,
                    decoration: const InputDecoration(
                      labelText: 'Quantity',
                      border: OutlineInputBorder(),
                    ),
                    keyboardType: TextInputType.number,
                    validator: (value) {
                      if (value == null || value.isEmpty) return 'Required';
                      final qty = int.tryParse(value);
                      if (qty == null || qty <= 0) return 'Enter valid quantity';
                      return null;
                    },
                    onChanged: (_) => setState(() {}),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: DropdownButtonFormField<String>(
                    value: _primaryUnit,
                    decoration: const InputDecoration(
                      labelText: 'Unit',
                      border: OutlineInputBorder(),
                    ),
                    items: _primaryUnits.map((unit) {
                      return DropdownMenuItem(value: unit, child: Text(unit));
                    }).toList(),
                    onChanged: (value) {
                      setState(() {
                        _primaryUnit = value!;
                      });
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Secondary Unit
      Row(
        children: [
          Expanded(
            child: TextFormField(
              controller: _quantityController1,
              decoration: const InputDecoration(
                labelText: 'Quantity',
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.number,
              validator: (value) {
                if (value == null || value.isEmpty) return 'Required';
                final qty = int.tryParse(value);
                if (qty == null || qty <= 0) return 'Enter valid quantity';
                return null;
              },
              onChanged: (_) => setState(() {}),
            ),
          ),
          const SizedBox(width: 12),
            Expanded(
              child: DropdownButtonFormField<String>(
                value: _secondaryUnit,
                decoration: const InputDecoration(
                  labelText: 'Secondary Unit',
                  border: OutlineInputBorder(),
                ),
                items: _secondaryUnits.map((unit) {
                  return DropdownMenuItem(value: unit, child: Text(unit));
                }).toList(),
                onChanged: (value) {
                  setState(() {
                    _secondaryUnit = value!;
                  });
                },
              ),
            ),
            ]),
            const SizedBox(height: 16),

            // Buying Price
            TextFormField(
              controller: _buyingPriceController,
              decoration: const InputDecoration(
                labelText: 'Buying Price (KES)',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.attach_money),
              ),
              keyboardType: TextInputType.number,
              validator: (value) {
                if (value == null || value.isEmpty) return 'Required';
                final price = double.tryParse(value);
                if (price == null || price <= 0) return 'Enter valid price';
                return null;
              },
              onChanged: (_) => setState(() {}),
            ),
            const SizedBox(height: 16),

            // Selling Price
            TextFormField(
              controller: _sellingPriceController,
              decoration: const InputDecoration(
                labelText: 'Selling Price (KES)',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.sell),
              ),
              keyboardType: TextInputType.number,
              validator: (value) {
                if (value == null || value.isEmpty) return 'Required';
                final price = double.tryParse(value);
                if (price == null || price <= 0) return 'Enter valid price';
                return null;
              },
              onChanged: (_) => setState(() {}),
            ),
            const SizedBox(height: 24),

            // Projected Profit Preview
            if (_quantityController.text.isNotEmpty &&
                _buyingPriceController.text.isNotEmpty &&
                _sellingPriceController.text.isNotEmpty)
              _buildProfitPreview(),

            const SizedBox(height: 24),

            // Save Button
            ElevatedButton(
              onPressed: _saveStock,
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                backgroundColor: Colors.blue,
              ),
              child: const Text('Save Stock', style: TextStyle(fontSize: 16, color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProfitPreview() {
    final qty = double.tryParse(_quantityController.text) ?? 0;
    final qty1 = double.tryParse(_quantityController1.text) ?? 0;
    final bp = double.tryParse(_buyingPriceController.text) ?? 0;
    final sp = double.tryParse(_sellingPriceController.text) ?? 0;
    final totalBuying = bp * qty;
    final totalSelling = sp * qty;
    final profit = totalSelling - totalBuying;
    final isProfitable = profit >= 0;

    return Card(
      color: isProfitable ? Colors.green[50] : Colors.red[50],
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            const Text('Projected Profit', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Text(
              'KES ${profit.toStringAsFixed(2)}',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: isProfitable ? Colors.green : Colors.red,
              ),
            ),
            const SizedBox(height: 4),
            Text.rich(
              TextSpan(
                children: [
                  const TextSpan(text: 'Cost: '),
                  TextSpan(text: 'KES ${totalBuying.toStringAsFixed(2)}', style: const TextStyle(color: Colors.blue)),
                  const TextSpan(text: ' | Revenue: '),
                  TextSpan(text: 'KES ${totalSelling.toStringAsFixed(2)}', style: const TextStyle(color: Colors.green)),
                ],
              ),
              style: const TextStyle(fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }

  void _saveStock() async {
    if (_formKey.currentState!.validate()) {
      final productName = _productName!.trim();
      final quantity = int.parse(_quantityController.text);
      final quantity1 = int.parse(_quantityController1.text);
      final buyingPrice = double.parse(_buyingPriceController.text);
      final sellingPrice = double.parse(_sellingPriceController.text);

      // Validate: selling price must be >= buying price
      if (sellingPrice < buyingPrice) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('⚠️ Selling price must be ≥ buying price!')),
        );
        return;
      }

      // Save product if new (or reuse existing)
      final product = await _findOrCreateProduct(productName);

      final stockEntry = StockEntry(
        id: const Uuid().v4(),
        product: product,
        entryDate: DateTime.now(),
        primaryUnitQuantity: quantity,
        primaryUnit: _primaryUnit,
        secondaryUnit: _secondaryUnit,
        buyingPrice: buyingPrice,
        sellingPrice: sellingPrice,
        picked: false,
        secondaryUnitQuantity: quantity1,
      );

      // Save to Hive
      await DataService().addStock(stockEntry);

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('✅ Stock added successfully!')),
      );

      // Reset form
      _formKey.currentState!.reset();
      _productName = null;
      _quantityController.clear();
      _buyingPriceController.clear();
      _sellingPriceController.clear();
      _quantityController1.clear();
      setState(() {});
    }
  }

  Future<Product> _findOrCreateProduct(String name) async {
    final productsBox = Hive.box<Product>('products');

    try {
      final existing = productsBox.values.firstWhere(
            (p) => p.name.toLowerCase() == name.toLowerCase(),
      );
      return existing;
    } catch (_) {
      // Not found → create new
      final newProduct = Product(
        id: const Uuid().v4(),
        name: name,
      );
      await productsBox.put(newProduct.id, newProduct);
      return newProduct;
    }
  }


  @override
  void dispose() {
    _quantityController.dispose();
    _buyingPriceController.dispose();
    _sellingPriceController.dispose();
    _quantityController1.dispose();
    super.dispose();
  }
}