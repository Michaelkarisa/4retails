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
 // String _secondaryUnit = 'Piece';
  final _quantityController = TextEditingController();
  final _priceController = TextEditingController();
  //String _secondaryUnit = 'Piece';
  String _secondaryUnit1 = 'Piece';
  final _quantityController1 = TextEditingController();
  final _quantityController2 = TextEditingController();
  final _buyingPriceController = TextEditingController();
  final _sellingPriceController = TextEditingController();
  final _itemController = TextEditingController();
  Map<String,dynamic> unitPrice ={};
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
            _productSearch(),
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
        final quantity = double.parse(_quantityController.text);
        final pricePerItem = int.parse(_priceController.text);
        // Save product if new (or reuse existing)
        final product = await DataService().findOrCreateProduct(productName);
        final saleId = const Uuid().v4();
        final saleEntry = SaleEntry(
          id: saleId,
          product: product,
          date: DateTime.now(),
          quantity: quantity,
          primaryUnit: _primaryUnit,
          pricePerItem: pricePerItem.toDouble(),
          paid: !loan,
        );

        // Save to Hive
        await DataService().addSale(saleEntry);
        if (loan) {
          final loanEntry = await DataService().findOrCreateLoan(_phone!,_name!);
           loanEntry.saleIds.add(saleId);
          await DataService().updateLoan(
              LoanEntry(id: loanEntry.id,
                  saleIds: loanEntry.saleIds,
                  date: loanEntry.date,
                  name: _name!,
                  phone: _phone!,
                  totalAmount: loanEntry.totalAmount,
                  payments: loanEntry.payments,
              ));
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

  Widget _productSearch(){
    List<Product> products =[];
    return Column(
      children: [
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
          onChanged: (value){
            _productName = value.trim();
            setState(() {
              products = DataService().findProducts(value);
            });
          },
          validator: (value) {
            if (value == null || value.trim().isEmpty) {
              return 'Product name is required';
            }
            return null;
          },
        ),
        const SizedBox(height: 16),
        AnimatedContainer(duration: Duration(milliseconds: 300),
          child: products.isNotEmpty?Column(
            children: products.map((product)=>Container(
              margin: EdgeInsets.symmetric(horizontal: 5,vertical: 5),
              child: Text(product.name),
            )).toList(),
          ):_productName != null && _productName!.isNotEmpty?Column(
            children: [
              Text(
                'Add new product',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey[600],
                ),
              ),
              SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _quantityController2,
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
                  const SizedBox(width: 5),
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      value: _secondaryUnit1,
                      decoration: const InputDecoration(
                        labelText: 'Unit',
                        border: OutlineInputBorder(),
                      ),
                      items: _secondaryUnits.map((unit) {
                        return DropdownMenuItem(value: unit, child: Text(unit));
                      }).toList(),
                      onChanged: (value) {
                        setState(() {
                          _secondaryUnit1 = value!;
                        });
                      },
                    ),
                  ),
                  const SizedBox(width: 5),
                  Expanded(
                    child: TextFormField(
                      controller: _sellingPriceController,
                      decoration: const InputDecoration(
                        labelText: 'Price (KES)',
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
                  ),
                  IconButton(
                    padding: EdgeInsets.zero,
                    icon: const Icon(Icons.add_circle),
                    color: Theme.of(context).colorScheme.primary,
                    iconSize: 30,
                    onPressed: (){
                      unitPrice["${_quantityController2.text}-$_secondaryUnit1"]=double.parse(_sellingPriceController.text);
                      setState(() {});
                    },
                  ),
                ],
              ),
              SizedBox(height: 5,),
              Column(
                children: unitPrice.entries.map((unitp){
                  return Container(
                    margin: EdgeInsets.symmetric(vertical: 5),
                    child: Row(
                      children: [
                        Text(unitp.key.toString()),
                        SizedBox(width: 5,),
                        Text(unitp.value.toString())
                      ],
                    ),
                  );
                }).toList(),
              ),
              SizedBox(height: 10),
              ElevatedButton.icon(
                onPressed: () async {
                  final product = Product(
                      id: const Uuid().v4(),
                      name: _productName.toString(),
                      unitPrice: unitPrice);
                  await DataService().updateProduct(product);
                },
                icon: const Icon(Icons.add),
                label: const Text('Add Product'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 12,
                  ),
                ),
              )
            ],
          ):SizedBox.shrink(),
        ),
      ],
    );
  }


  @override
  void dispose() {
    _quantityController.dispose();
    _priceController.dispose();
    super.dispose();
  }
}