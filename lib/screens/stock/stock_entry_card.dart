import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:retails/service/data_service.dart';
import '../../models/stock_entry.dart';
import '../../utils/sample_data.dart';

class StockEntryCard extends StatefulWidget {
  final StockEntry entry;

  const StockEntryCard({Key? key, required this.entry}) : super(key: key);

  @override
  State<StockEntryCard> createState() => _StockEntryCardState();
}

class _StockEntryCardState extends State<StockEntryCard> {
  bool _isExpanded = false;
  bool _isEditMode = false;
  bool _isLoading = false;

  final _formKey = GlobalKey<FormState>();
  late TextEditingController _productNameController;
  late TextEditingController _quantityController;
  late TextEditingController _quantityController1;
  late TextEditingController _buyingPriceController;
  late TextEditingController _sellingPriceController;

  late String _primaryUnit;
  late String _secondaryUnit;

  final List<String> _primaryUnits = ['Box', 'Can', 'Carton', 'Bag'];
  final List<String> _secondaryUnits = ['Piece', 'Kg', 'Litre'];

  @override
  void initState() {
    super.initState();
    _initializeControllers();
  }

  void _initializeControllers() {
    _productNameController = TextEditingController(text: widget.entry.product.name);
    _quantityController = TextEditingController(text: widget.entry.primaryUnitQuantity.toString());
    _buyingPriceController = TextEditingController(text: widget.entry.buyingPrice.toStringAsFixed(2));
    _sellingPriceController = TextEditingController(text: widget.entry.sellingPrice.toStringAsFixed(2));
    _quantityController1 = TextEditingController(text: widget.entry.secondaryUnitQuantity.toString());
    _primaryUnit = widget.entry.primaryUnit;
    _secondaryUnit = widget.entry.secondaryUnit;
  }

  @override
  void dispose() {
    _productNameController.dispose();
    _quantityController.dispose();
    _quantityController1.dispose();
    _buyingPriceController.dispose();
    _sellingPriceController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final dateStr = formatDateForDisplay(widget.entry.entryDate);

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Column(
        children: [
          if (_isEditMode)
            _buildEditForm()
          else
            _buildDisplayMode(dateStr),

          _buildActionButtons(),
        ],
      ),
    );
  }

  Widget _buildDisplayMode(String dateStr) {
    return InkWell(
      onTap: () {
        setState(() {
          _isExpanded = !_isExpanded;
        });
      },
      borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.entry.product.name,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        dateStr,
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(
                  _isExpanded ? Icons.expand_less : Icons.expand_more,
                  color: Colors.grey[600],
                ),
              ],
            ),
            if (_isExpanded) ...[
              const Divider(height: 24),
              _buildInfoRow(
                icon: Icons.inventory_2_outlined,
                label: 'Quantity',
                value: '${widget.entry.primaryUnitQuantity} ${widget.entry.primaryUnit}s',
              ),
              const SizedBox(height: 8),
              _buildInfoRow(
                icon: Icons.arrow_downward,
                label: 'Buying Price',
                value: 'KES ${widget.entry.buyingPrice.toStringAsFixed(2)}',
                valueColor: Colors.orange[700],
              ),
              const SizedBox(height: 8),
              _buildInfoRow(
                icon: Icons.arrow_upward,
                label: 'Selling Price',
                value: 'KES ${widget.entry.sellingPrice.toStringAsFixed(2)}',
                valueColor: Colors.blue[700],
              ),
              const SizedBox(height: 12),
              _buildProfitCard(
                profit: widget.entry.projectedProfit,
                isCompact: true,
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow({
    required IconData icon,
    required String label,
    required String value,
    Color? valueColor,
  }) {
    return Row(
      children: [
        Icon(icon, size: 20, color: Colors.grey[600]),
        const SizedBox(width: 8),
        Text(
          '$label: ',
          style: TextStyle(
            fontSize: 14,
            color: Colors.grey[700],
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: valueColor ?? Colors.black87,
          ),
        ),
      ],
    );
  }

  Widget _buildEditForm() {
    return Form(
      key: _formKey,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Edit Stock Entry',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),

            // Product Name
            TextFormField(
              controller: _productNameController,
              decoration: InputDecoration(
                labelText: 'Product Name',
                hintText: 'e.g., Maize Flour, Cooking Oil',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                prefixIcon: const Icon(Icons.inventory),
                filled: true,
                fillColor: Colors.grey[50],
              ),
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
                  flex: 2,
                  child: TextFormField(
                    controller: _quantityController,
                    decoration: InputDecoration(
                      labelText: 'Quantity',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      filled: true,
                      fillColor: Colors.grey[50],
                    ),
                    keyboardType: TextInputType.number,
                    validator: (value) {
                      if (value == null || value.isEmpty) return 'Required';
                      final qty = int.tryParse(value);
                      if (qty == null || qty <= 0) return 'Invalid quantity';
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
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
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

            // Secondary Unit
            DropdownButtonFormField<String>(
              value: _secondaryUnit,
              decoration: InputDecoration(
                labelText: 'Secondary Unit',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
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
            const SizedBox(height: 16),

            // Buying and Selling Price in a Row
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _buyingPriceController,
                    decoration: InputDecoration(
                      labelText: 'Buying Price',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      prefixText: 'KES ',
                      filled: true,
                      fillColor: Colors.grey[50],
                    ),
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    validator: (value) {
                      if (value == null || value.isEmpty) return 'Required';
                      final price = double.tryParse(value);
                      if (price == null || price <= 0) return 'Invalid price';
                      return null;
                    },
                    onChanged: (_) => setState(() {}),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextFormField(
                    controller: _sellingPriceController,
                    decoration: InputDecoration(
                      labelText: 'Selling Price',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      prefixText: 'KES ',
                      filled: true,
                      fillColor: Colors.grey[50],
                    ),
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    validator: (value) {
                      if (value == null || value.isEmpty) return 'Required';
                      final price = double.tryParse(value);
                      if (price == null || price <= 0) return 'Invalid price';
                      return null;
                    },
                    onChanged: (_) => setState(() {}),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Projected Profit Preview
            if (_quantityController.text.isNotEmpty &&
                _buyingPriceController.text.isNotEmpty &&
                _sellingPriceController.text.isNotEmpty)
              _buildProfitPreview(),

            const SizedBox(height: 20),

            // Save Button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _isLoading ? null : _handleUpdate,
                icon: _isLoading
                    ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                )
                    : const Icon(Icons.save),
                label: Text(
                  _isLoading ? 'Updating...' : 'Update Stock',
                  style: const TextStyle(fontSize: 16),
                ),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  backgroundColor: Colors.blue,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProfitPreview() {
    final qty = double.tryParse(_quantityController.text) ?? 0;
    final bp = double.tryParse(_buyingPriceController.text) ?? 0;
    final sp = double.tryParse(_sellingPriceController.text) ?? 0;
    final profit = (sp - bp) * qty;

    return _buildProfitCard(profit: profit, isCompact: false);
  }

  Widget _buildProfitCard({required double profit, required bool isCompact}) {
    final isProfitable = profit >= 0;
    final qty = double.tryParse(_quantityController.text) ?? widget.entry.primaryUnitQuantity.toDouble();
    final bp = double.tryParse(_buyingPriceController.text) ?? widget.entry.buyingPrice;
    final sp = double.tryParse(_sellingPriceController.text) ?? widget.entry.sellingPrice;
    final totalBuying = bp * qty;
    final totalSelling = sp * qty;

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isProfitable
              ? [Colors.green[50]!, Colors.green[100]!]
              : [Colors.red[50]!, Colors.red[100]!],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isProfitable ? Colors.green[200]! : Colors.red[200]!,
          width: 1.5,
        ),
      ),
      child: Padding(
        padding: EdgeInsets.all(isCompact ? 12 : 16),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Icon(
                      isProfitable ? Icons.trending_up : Icons.trending_down,
                      color: isProfitable ? Colors.green[700] : Colors.red[700],
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Projected Profit',
                      style: TextStyle(
                        fontSize: isCompact ? 13 : 14,
                        fontWeight: FontWeight.w600,
                        color: Colors.grey[800],
                      ),
                    ),
                  ],
                ),
                Text(
                  'KES ${profit.toStringAsFixed(2)}',
                  style: TextStyle(
                    fontSize: isCompact ? 18 : 22,
                    fontWeight: FontWeight.bold,
                    color: isProfitable ? Colors.green[700] : Colors.red[700],
                  ),
                ),
              ],
            ),
            if (!isCompact) ...[
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildProfitDetail(
                    label: 'Cost',
                    value: totalBuying,
                    color: Colors.orange[700]!,
                  ),
                  Container(
                    height: 30,
                    width: 1,
                    color: Colors.grey[300],
                  ),
                  _buildProfitDetail(
                    label: 'Revenue',
                    value: totalSelling,
                    color: Colors.blue[700]!,
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildProfitDetail({
    required String label,
    required double value,
    required Color color,
  }) {
    return Column(
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey[600],
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'KES ${value.toStringAsFixed(2)}',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: color,
          ),
        ),
      ],
    );
  }

  Widget _buildActionButtons() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: const BorderRadius.vertical(bottom: Radius.circular(12)),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          // Edit/Cancel Button
          IconButton(
            onPressed: _isLoading ? null : () {
              setState(() {
                _isEditMode = !_isEditMode;
                if (!_isEditMode) {
                  // Reset controllers when canceling edit
                  _initializeControllers();
                }
              });
            },
            icon: Icon(
              _isEditMode ? Icons.close : Icons.edit,
              size: 22,
            ),
            tooltip: _isEditMode ? 'Cancel' : 'Edit',
            color: _isEditMode ? Colors.orange : Colors.blue,
          ),
          const SizedBox(width: 8),
          // Delete Button
          IconButton(
            onPressed: _isLoading ? null : _handleDelete,
            icon: const Icon(
              Icons.delete,
              size: 22,
            ),
            tooltip: 'Delete',
            color: Colors.red,
          ),
        ],
      ),
    );
  }

  Future<void> _handleUpdate() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      await DataService().updateStock(
        StockEntry(
          id: widget.entry.id,
          product: widget.entry.product,
          entryDate: widget.entry.entryDate,
          primaryUnitQuantity: int.parse(_quantityController.text),
          primaryUnit: _primaryUnit,
          secondaryUnit: _secondaryUnit,
          buyingPrice: double.parse(_buyingPriceController.text),
          sellingPrice: double.parse(_sellingPriceController.text),
          picked: widget.entry.picked,
          secondaryUnitQuantity: int.parse(_quantityController1.text),
        ),
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Stock updated successfully'),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
          ),
        );
        setState(() {
          _isEditMode = false;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error updating stock: $e'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _handleDelete() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Stock Entry'),
        content: Text(
          'Are you sure you want to delete "${widget.entry.product.name}"?',
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      setState(() {
        _isLoading = true;
      });

      try {
        await DataService().deleteStock(widget.entry.id);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Stock deleted successfully'),
              backgroundColor: Colors.green,
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error deleting stock: $e'),
              backgroundColor: Colors.red,
              behavior: SnackBarBehavior.floating,
            ),
          );
          setState(() {
            _isLoading = false;
          });
        }
      }
    }
  }
}