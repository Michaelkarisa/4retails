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
  String _secondaryUnit1 = 'Piece';
  final _quantityController = TextEditingController();
  final _quantityController1 = TextEditingController();
  final _quantityController2 = TextEditingController();
  final _buyingPriceController = TextEditingController();
  final _sellingPriceController = TextEditingController();
  final _itemController = TextEditingController();
  Map<String, dynamic> unitPrice = {};
  final List<String> _primaryUnits = ['Box', 'Can', 'Carton', 'Bag'];
  final List<String> _secondaryUnits = ['Piece', 'Kg', 'Litre'];

  bool _showNewProductForm = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Add Stock'),
        elevation: 0,
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Product Search Section
            _buildSectionCard(
              title: 'Product Information',
              icon: Icons.inventory_2,
              child: _productSearch(),
            ),

            const SizedBox(height: 16),

            // Stock Details Section
            if (_productName != null && _productName!.isNotEmpty && !_showNewProductForm)
              _buildSectionCard(
                title: 'Stock Details',
                icon: Icons.add_box,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Primary Unit Section
                    _buildSubsectionTitle('Primary Unit'),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          flex: 2,
                          child: TextFormField(
                            controller: _quantityController,
                            decoration: InputDecoration(
                              labelText: 'Quantity',
                              border: const OutlineInputBorder(),
                              filled: true,
                              fillColor: Colors.grey[50],
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
                          flex: 2,
                          child: DropdownButtonFormField<String>(
                            value: _primaryUnit,
                            decoration: InputDecoration(
                              labelText: 'Unit',
                              border: const OutlineInputBorder(),
                              filled: true,
                              fillColor: Colors.grey[50],
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

                    // Items per unit
                    Text(
                      'Items per $_primaryUnit',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: Colors.grey[700],
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _itemController,
                      decoration: InputDecoration(
                        labelText: 'Number of items',
                        border: const OutlineInputBorder(),
                        filled: true,
                        fillColor: Colors.grey[50],
                        prefixIcon: const Icon(Icons.numbers),
                      ),
                      keyboardType: TextInputType.number,
                      onChanged: (_) => setState(() {}),
                    ),

                    const SizedBox(height: 20),

                    // Secondary Unit Section
                    _buildSubsectionTitle('Secondary Unit'),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          flex: 2,
                          child: TextFormField(
                            controller: _quantityController1,
                            decoration: InputDecoration(
                              labelText: 'Quantity',
                              border: const OutlineInputBorder(),
                              filled: true,
                              fillColor: Colors.grey[50],
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
                          flex: 2,
                          child: DropdownButtonFormField<String>(
                            value: _secondaryUnit,
                            decoration: InputDecoration(
                              labelText: 'Unit',
                              border: const OutlineInputBorder(),
                              filled: true,
                              fillColor: Colors.grey[50],
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
                      ],
                    ),

                    const SizedBox(height: 20),

                    // Pricing Section
                    _buildSubsectionTitle('Pricing'),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _buyingPriceController,
                      decoration: InputDecoration(
                        labelText: 'Buying Price (KES)',
                        border: const OutlineInputBorder(),
                        filled: true,
                        fillColor: Colors.grey[50],
                        prefixIcon: const Icon(Icons.attach_money, color: Colors.orange),
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
                  ],
                ),
              ),

            const SizedBox(height: 16),

            // Projected Profit Preview
            if (_quantityController.text.isNotEmpty &&
                _buyingPriceController.text.isNotEmpty &&
                _sellingPriceController.text.isNotEmpty &&
                !_showNewProductForm)
              _buildProfitPreview(),

            const SizedBox(height: 24),

            // Save Button
            if (_productName != null && _productName!.isNotEmpty && !_showNewProductForm)
              ElevatedButton.icon(
                onPressed: _saveStock,
                icon: const Icon(Icons.save),
                label: const Text('Save Stock', style: TextStyle(fontSize: 16)),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  backgroundColor: Colors.blue,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionCard({
    required String title,
    required IconData icon,
    required Widget child,
  }) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: Colors.blue, size: 24),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            child,
          ],
        ),
      ),
    );
  }

  Widget _buildSubsectionTitle(String title) {
    return Text(
      title,
      style: TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w600,
        color: Colors.grey[800],
      ),
    );
  }

  Widget _buildProfitPreview() {
    final qty = double.tryParse(_quantityController.text) ?? 0;
    final bp = double.tryParse(_buyingPriceController.text) ?? 0;
    final sp = double.tryParse(_sellingPriceController.text) ?? 0;
    final totalBuying = bp * qty;
    final totalSelling = sp * qty;
    final profit = totalSelling - totalBuying;
    final isProfitable = profit >= 0;

    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      color: isProfitable ? Colors.green[50] : Colors.red[50],
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  isProfitable ? Icons.trending_up : Icons.trending_down,
                  color: isProfitable ? Colors.green : Colors.red,
                ),
                const SizedBox(width: 8),
                const Text(
                  'Projected Profit',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              'KES ${profit.toStringAsFixed(2)}',
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: isProfitable ? Colors.green[700] : Colors.red[700],
              ),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  Column(
                    children: [
                      Text(
                        'Cost',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[600],
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'KES ${totalBuying.toStringAsFixed(2)}',
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: Colors.orange,
                        ),
                      ),
                    ],
                  ),
                  Container(
                    height: 40,
                    width: 1,
                    color: Colors.grey[300],
                  ),
                  Column(
                    children: [
                      Text(
                        'Revenue',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[600],
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'KES ${totalSelling.toStringAsFixed(2)}',
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: Colors.green,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
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
          const SnackBar(
            content: Text('⚠️ Selling price must be ≥ buying price!'),
            backgroundColor: Colors.orange,
          ),
        );
        return;
      }

      // Save product if new (or reuse existing)
      final product = await DataService().findOrCreateProduct(productName);

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
        const SnackBar(
          content: Text('✅ Stock added successfully!'),
          backgroundColor: Colors.green,
        ),
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

  Widget _productSearch() {
    List<Product> products = [];
    return Column(
      children: [
        TextFormField(
          decoration: InputDecoration(
            labelText: 'Product Name',
            hintText: 'e.g., Maize Flour, Cooking Oil',
            border: const OutlineInputBorder(),
            filled: true,
            fillColor: Colors.grey[50],
            prefixIcon: const Icon(Icons.search),
            suffixIcon: _productName != null && _productName!.isNotEmpty
                ? IconButton(
              icon: const Icon(Icons.clear, size: 20),
              onPressed: () {
                setState(() {
                  _productName = null;
                  _showNewProductForm = false;
                });
              },
            )
                : null,
          ),
          onChanged: (value) {
            _productName = value.trim();
            setState(() {
              products = DataService().findProducts(value);
              _showNewProductForm = value.isNotEmpty && products.isEmpty;
            });
          },
          validator: (value) {
            if (value == null || value.trim().isEmpty) {
              return 'Product name is required';
            }
            return null;
          },
        ),
        const SizedBox(height: 12),
        AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          child: products.isNotEmpty
              ? Container(
            decoration: BoxDecoration(
              color: Colors.blue[50],
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.blue[200]!),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.all(12),
                  child: Text(
                    'Existing Products',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Colors.blue[800],
                    ),
                  ),
                ),
                ...products.map((product) => InkWell(
                  onTap: () {
                    setState(() {
                      _productName = product.name;
                      _showNewProductForm = false;
                    });
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 10,
                    ),
                    decoration: BoxDecoration(
                      border: Border(
                        top: BorderSide(color: Colors.blue[100]!),
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.inventory,
                            size: 20,
                            color: Colors.blue[700]
                        ),
                        const SizedBox(width: 8),
                        Text(
                          product.name,
                          style: const TextStyle(fontSize: 15),
                        ),
                      ],
                    ),
                  ),
                )),
              ],
            ),
          )
              : _showNewProductForm
              ? _buildNewProductForm()
              : const SizedBox.shrink(),
        ),
      ],
    );
  }

  Widget _buildNewProductForm() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.orange[50],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.orange[200]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.add_circle_outline, color: Colors.orange[700]),
              const SizedBox(width: 8),
              Text(
                'Add New Product',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.orange[900],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Unit Price Entry
          Text(
            'Define unit prices for this product:',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[700],
            ),
          ),
          const SizedBox(height: 12),

          Row(
            children: [
              Expanded(
                flex: 2,
                child: TextFormField(
                  controller: _quantityController2,
                  decoration: InputDecoration(
                    labelText: 'Quantity',
                    border: const OutlineInputBorder(),
                    filled: true,
                    fillColor: Colors.white,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 14,
                    ),
                  ),
                  keyboardType: TextInputType.number,
                  validator: (value) {
                    if (value == null || value.isEmpty) return 'Required';
                    final qty = int.tryParse(value);
                    if (qty == null || qty <= 0) return 'Invalid';
                    return null;
                  },
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                flex: 2,
                child: DropdownButtonFormField<String>(
                  value: _secondaryUnit1,
                  decoration: InputDecoration(
                    labelText: 'Unit',
                    border: const OutlineInputBorder(),
                    filled: true,
                    fillColor: Colors.white,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 14,
                    ),
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
              const SizedBox(width: 8),
              Expanded(
                flex: 3,
                child: TextFormField(
                  controller: _sellingPriceController,
                  decoration: const InputDecoration(
                    labelText: 'Price (KES)',
                    border: OutlineInputBorder(),
                    filled: true,
                    fillColor: Colors.white,
                    prefixIcon: Icon(Icons.sell, size: 20),
                    contentPadding: EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 14,
                    ),
                  ),
                  keyboardType: TextInputType.number,
                  validator: (value) {
                    if (value == null || value.isEmpty) return 'Required';
                    final price = double.tryParse(value);
                    if (price == null || price <= 0) return 'Invalid';
                    return null;
                  },
                ),
              ),
              IconButton(
                padding: EdgeInsets.zero,
                icon: const Icon(Icons.add_circle),
                color: Colors.green,
                iconSize: 32,
                onPressed: () {
                  if (_quantityController2.text.isNotEmpty &&
                      _sellingPriceController.text.isNotEmpty) {
                    unitPrice["${_quantityController2.text}-$_secondaryUnit1"] =
                        double.parse(_sellingPriceController.text);
                    _quantityController2.clear();
                    _sellingPriceController.clear();
                    setState(() {});
                  }
                },
              ),
            ],
          ),

          const SizedBox(height: 12),

          // Display added unit prices
          if (unitPrice.isNotEmpty)
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.grey[300]!),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Added Prices:',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: Colors.grey[700],
                    ),
                  ),
                  const SizedBox(height: 8),
                  ...unitPrice.entries.map((unitp) {
                    return Container(
                      margin: const EdgeInsets.only(bottom: 6),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.green[50],
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              Icon(Icons.check_circle,
                                  size: 16,
                                  color: Colors.green[700]
                              ),
                              const SizedBox(width: 8),
                              Text(
                                unitp.key.toString(),
                                style: const TextStyle(
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                          Text(
                            'KES ${unitp.value}',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.green[700],
                            ),
                          ),
                        ],
                      ),
                    );
                  }),
                ],
              ),
            ),

          const SizedBox(height: 16),

          // Save Product Button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: unitPrice.isEmpty
                  ? null
                  : () async {
                final product = Product(
                  id: const Uuid().v4(),
                  name: _productName.toString(),
                  unitPrice: unitPrice,
                );
                await DataService().updateProduct(product);

                if (!mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('✅ Product added successfully!'),
                    backgroundColor: Colors.green,
                  ),
                );

                setState(() {
                  _showNewProductForm = false;
                  unitPrice.clear();
                });
              },
              icon: const Icon(Icons.save),
              label: const Text('Save Product'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _quantityController.dispose();
    _buyingPriceController.dispose();
    _sellingPriceController.dispose();
    _quantityController1.dispose();
    _quantityController2.dispose();
    _itemController.dispose();
    super.dispose();
  }
}