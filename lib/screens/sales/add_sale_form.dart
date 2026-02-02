import 'package:flutter/material.dart';
import 'package:hive_flutter/adapters.dart';
import 'package:retails/models/loan_entry.dart';
import 'package:uuid/uuid.dart';

import '../../models/product.dart';
import '../../models/sale_entry.dart';
import '../../service/data_service.dart';

class AddSaleForm extends StatefulWidget {
  const AddSaleForm({Key? key}) : super(key: key);

  @override
  State<AddSaleForm> createState() => _AddSaleFormState();
}

class _AddSaleFormState extends State<AddSaleForm> {
  final _formKey = GlobalKey<FormState>();
  String? _productName;
  String? _name;
  String? _phone;
  String _primaryUnit = 'Box';
  String _secondaryUnit = 'Piece';
  final _quantityController = TextEditingController();
  final _priceController = TextEditingController();
  final double _previousPrice = 120.0;

  final List<String> _primaryUnits = ['Box', 'Can', 'Carton', 'Bag','Piece', 'Kg', 'Litre'];
  final List<String> _secondaryUnits = ['Piece', 'Kg', 'Litre'];
  bool loan = false;
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Add Sale'),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            TextFormField(
              decoration: const InputDecoration(
                labelText: 'Product Name',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.search),
              ),
              onChanged: (value) => _productName = value,
              validator: (value) => value?.isEmpty == true ? 'Required' : null,
            ),
            const SizedBox(height: 16),
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
                    validator: (value) => value?.isEmpty == true ? 'Required' : null,
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
            TextFormField(
              controller: _priceController,
              decoration: const InputDecoration(
                labelText: 'Selling Price (KES)',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.attach_money),
              ),
              keyboardType: TextInputType.number,
              validator: (value) => value?.isEmpty == true ? 'Required' : null,
              onChanged: (_) => setState(() {}),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.start,
              children: [
                Checkbox(value: loan,
                  onChanged: (bool? value) {
                    setState(() {
                      if(loan) {
                        loan = false;
                      }else{
                        loan = true;
                      }
                    });
                  },),
                const SizedBox(width: 10),
                Text("Debt",style: TextStyle(fontWeight: FontWeight.bold),)
              ],
            ),
            if(loan)_loan(),
            const SizedBox(height: 16),
            if (_priceController.text.isNotEmpty) _buildPriceComparison(),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _saveSale,
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              child: const Text('Record Sale', style: TextStyle(fontSize: 16)),
            ),
          ],
        ),
      ),
    );
  }

Widget _loan(){
    return Column(
      children: [
        const SizedBox(height: 6),
        TextFormField(
          decoration: const InputDecoration(
            labelText: 'Name',
            border: OutlineInputBorder(),
            prefixIcon: Icon(Icons.person),
          ),
          onChanged: (value) => _name = value,
          validator: (value) => value?.isEmpty == true ? 'Required' : null,
        ),
        const SizedBox(height: 16),
        TextFormField(
          decoration: const InputDecoration(
            labelText: 'Phone',
            border: OutlineInputBorder(),
            prefixIcon: Icon(Icons.phone),
          ),
          onChanged: (value) => _phone = value,
          validator: (value) => value?.isEmpty == true ? 'Required' : null,
        ),
      ],
    );
}

  Widget _buildPriceComparison() {
    final currentPrice = double.tryParse(_priceController.text) ?? 0;
    final difference = currentPrice - _previousPrice;
    final isPositive = difference >= 0;

    return Card(
      color: isPositive ? Colors.green[50] : Colors.red[50],
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text('vs Previous Sale:', style: TextStyle(fontSize: 14)),
            Row(
              children: [
                Text(
                  '${isPositive ? '+' : ''}KES ${difference.toStringAsFixed(2)}',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: isPositive ? Colors.green : Colors.red,
                  ),
                ),
                Icon(
                  isPositive ? Icons.arrow_upward : Icons.arrow_downward,
                  color: isPositive ? Colors.green : Colors.red,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _saveSale() async{
    try {
      if (_formKey.currentState!.validate()) {
        final productName = _productName!.trim();
        final quantity = int.parse(_quantityController.text);
        final priceperitem = int.parse(_priceController.text);
        // Save product if new (or reuse existing)
        final product = await _findOrCreateProduct(productName);
        final saleId = const Uuid().v4();
        final saleEntry = SaleEntry(
          id: saleId,
          product: product,
          date: DateTime.now(),
          quantity: quantity,
          primaryUnit: _primaryUnit,
          secondaryUnit: _secondaryUnit,
          pricePerItem: priceperitem.toDouble(),
          paid: !loan,
        );

        // Save to Hive
        await DataService().addSale(saleEntry);
        if (loan) {
          await DataService().addLoan(
              LoanEntry(id: const Uuid().v4(),
                  saleId: saleId,
                  date: DateTime.now(),
                  name: _name!,
                  phone: _phone!,
                  totalAmount: 0));
        }
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Sale recorded successfully!')),
        );
        // Reset form
        _productName = null;
        _name = null;
        _phone = null;
        _quantityController.clear();
        _priceController.clear();
        setState(() {});
      }
    }catch(e){
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error!$e')),
      );
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
    _priceController.dispose();
    super.dispose();
  }
}