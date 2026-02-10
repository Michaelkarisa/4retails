import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:retails/service/data_service.dart';
import 'package:uuid/uuid.dart';
import '../../models/loan_entry.dart';
import '../../models/sale_entry.dart';
import '../../models/stock_entry.dart';
import '../../utils/sample_data.dart';

class SalesEntryCard extends StatefulWidget {
  final SaleEntry entry;

  const SalesEntryCard({Key? key, required this.entry}) : super(key: key);

  @override
  State<SalesEntryCard> createState() => _SalesEntryCardState();
}

class _SalesEntryCardState extends State<SalesEntryCard> {
  bool _isExpanded = false;
  bool _isEditMode = false;
  bool _isLoading = false;

  final _formKey = GlobalKey<FormState>();
  late TextEditingController _productNameController;
  late TextEditingController _quantityController;
  late TextEditingController _priceController;
  String? _name;
  String? _phone;
  late String _primaryUnit;
  final double _previousPrice = 120.0; // You may want to calculate this dynamically

  final List<String> _primaryUnits = ['Box', 'Can', 'Carton', 'Bag','Piece', 'Kg', 'Litre'];
  bool loan = false;
  @override
  void initState() {
    super.initState();
    _initializeControllers();
  }

  void _initializeControllers() {
    _productNameController = TextEditingController(text: widget.entry.product.name);
    _quantityController = TextEditingController(text: widget.entry.quantity.toString());
    _priceController = TextEditingController(text: widget.entry.pricePerItem.toStringAsFixed(2));
    _primaryUnit = widget.entry.primaryUnit;
  }

  @override
  void dispose() {
    _productNameController.dispose();
    _quantityController.dispose();
    _priceController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final dateStr = formatDateForDisplay(widget.entry.date);

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
    final totalRevenue = widget.entry.quantity * widget.entry.pricePerItem;

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
                value: '${widget.entry.quantity} ${widget.entry.primaryUnit}s',
              ),
              const SizedBox(height: 8),
              _buildInfoRow(
                icon: Icons.sell_outlined,
                label: 'Price per ${widget.entry.primaryUnit}',
                value: 'KES ${widget.entry.pricePerItem.toStringAsFixed(2)}',
                valueColor: Colors.blue[700],
              ),
              const SizedBox(height: 8),
              _buildInfoRow(
                icon: Icons.attach_money,
                label: 'Unit Type',
                value: '${widget.entry.primaryUnit}',
                valueColor: Colors.grey[700],
              ),
              const SizedBox(height: 12),
              _buildRevenueCard(totalRevenue),
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
        Expanded(
          child: Text(
            value,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: valueColor ?? Colors.black87,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildRevenueCard(double totalRevenue) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.green[50]!, Colors.green[100]!],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Colors.green[200]!,
          width: 1.5,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Icon(
                  Icons.payments_outlined,
                  color: Colors.green[700],
                  size: 20,
                ),
                const SizedBox(width: 8),
                Text(
                  'Total Revenue',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey[800],
                  ),
                ),
              ],
            ),
            Text(
              'KES ${totalRevenue.toStringAsFixed(2)}',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.green[700],
              ),
            ),
          ],
        ),
      ),
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
              'Edit Sale Entry',
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
                      labelText: 'Quantity Sold',
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
            const SizedBox(height: 16),

            // Selling Price
            TextFormField(
              controller: _priceController,
              decoration: InputDecoration(
                labelText: 'Selling Price per Unit',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                prefixText: 'KES ',
                prefixIcon: const Icon(Icons.sell),
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
            const SizedBox(height: 20),

            // Price Comparison (if available)
            if (_priceController.text.isNotEmpty) _buildPriceComparison(),

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
            // Total Revenue Preview
            if (_quantityController.text.isNotEmpty && _priceController.text.isNotEmpty)
              _buildRevenuePreview(),

            const SizedBox(height: 20),

            // Update Button
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
                  _isLoading ? 'Updating...' : 'Update Sale',
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
    final percentageChange = _previousPrice > 0
        ? ((difference / _previousPrice) * 100).abs()
        : 0;

    return Container(
      decoration: BoxDecoration(
        color: isPositive ? Colors.green[50] : Colors.red[50],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: isPositive ? Colors.green[200]! : Colors.red[200]!,
          width: 1,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Icon(
                  Icons.compare_arrows,
                  size: 18,
                  color: Colors.grey[700],
                ),
                const SizedBox(width: 8),
                Text(
                  'vs Previous Sale:',
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.grey[700],
                  ),
                ),
              ],
            ),
            Row(
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      '${isPositive ? '+' : ''}KES ${difference.toStringAsFixed(2)}',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: isPositive ? Colors.green[700] : Colors.red[700],
                      ),
                    ),
                    Text(
                      '${isPositive ? '+' : '-'}${percentageChange.toStringAsFixed(1)}%',
                      style: TextStyle(
                        fontSize: 11,
                        color: isPositive ? Colors.green[600] : Colors.red[600],
                      ),
                    ),
                  ],
                ),
                const SizedBox(width: 4),
                Icon(
                  isPositive ? Icons.trending_up : Icons.trending_down,
                  color: isPositive ? Colors.green[700] : Colors.red[700],
                  size: 20,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRevenuePreview() {
    final qty = int.tryParse(_quantityController.text) ?? 0;
    final price = double.tryParse(_priceController.text) ?? 0;
    final totalRevenue = qty * price;

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.blue[50]!, Colors.blue[100]!],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Colors.blue[200]!,
          width: 1.5,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.receipt_long,
                      color: Colors.blue[700],
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    const Text(
                      'Total Revenue',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
                Text(
                  'KES ${totalRevenue.toStringAsFixed(2)}',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Colors.blue[700],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              '$qty ${_primaryUnit}${qty > 1 ? 's' : ''} × KES ${price.toStringAsFixed(2)}',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
      ),
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
      await DataService().updateSale(
        SaleEntry(
          id: widget.entry.id,
          product: widget.entry.product,
          date: widget.entry.date,
          quantity: double.parse(_quantityController.text),
          primaryUnit: _primaryUnit,
          pricePerItem: double.parse(_priceController.text),
          paid: widget.entry.paid,
        ),
      );

      if (loan) {
        final loanEntry = await DataService().findOrCreateLoan(_phone!,_name!);
        loanEntry.saleIds.add(widget.entry.id);
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
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Sale updated successfully'),
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
            content: Text('Error updating sale: $e'),
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
        title: const Text('Delete Sale Entry'),
        content: Text(
          'Are you sure you want to delete this sale of "${widget.entry.product.name}"?',
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
        await DataService().deleteSale(widget.entry.id);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Sale deleted successfully'),
              backgroundColor: Colors.green,
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error deleting sale: $e'),
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