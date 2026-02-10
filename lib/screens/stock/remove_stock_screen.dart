import 'package:flutter/material.dart';
import 'package:hive_flutter/adapters.dart';
import 'package:uuid/uuid.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import '../../models/product.dart';
import '../../models/stock_entry.dart';
import '../../models/stock_removal.dart';
import '../../service/data_service.dart';

class RemoveStockScreen extends StatefulWidget {
  const RemoveStockScreen({super.key});

  @override
  State<RemoveStockScreen> createState() => _RemoveStockScreenState();
}

class _RemoveStockScreenState extends State<RemoveStockScreen> {
  final _formKey = GlobalKey<FormState>();
  final _quantityController = TextEditingController();
  final _notesController = TextEditingController();
  final ImagePicker _imagePicker = ImagePicker();

  StockEntry? _selectedStock;
  RemovalReason? _selectedReason;
  List<String> _photosPaths = [];
  bool _isLoading = false;
  List<StockEntry> _availableStock = [];

  @override
  void initState() {
    super.initState();
    _loadAvailableStock();
  }

  @override
  void dispose() {
    _quantityController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _loadAvailableStock() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final allStock = DataService().allStocks();
      _availableStock = allStock.where((stock) => !stock.picked).toList();

      setState(() {
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading stock: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Remove Stock'),
        actions: [
          if (_availableStock.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(right: 16),
              child: Center(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    '${_availableStock.length} items',
                    style: const TextStyle(fontSize: 12),
                  ),
                ),
              ),
            ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _availableStock.isEmpty
          ? _buildEmptyState()
          : _buildForm(),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.inventory_2_outlined,
              size: 80,
              color: Colors.grey[300],
            ),
            const SizedBox(height: 16),
            Text(
              'No Stock Available',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Add stock to your inventory first',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[500],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildForm() {
    return Form(
      key: _formKey,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Info Card
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.blue[50],
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.blue[200]!),
            ),
            child: Row(
              children: [
                Icon(Icons.info_outline, color: Colors.blue[700], size: 24),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Remove stock from inventory for retail stocking or damaged items',
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.blue[900],
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Select Stock Item
          const Text(
            'Select Item',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          _buildStockSelector(),
          const SizedBox(height: 24),

          // Removal Reason
          const Text(
            'Reason for Removal',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          _buildReasonSelector(),
          const SizedBox(height: 24),

          // Quantity
          const Text(
            'Quantity to Remove (in secondary units)',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: _quantityController,
            keyboardType: TextInputType.number,
            decoration: InputDecoration(
              hintText: 'Enter quantity in ${_selectedStock?.secondaryUnit ?? 'units'}',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              filled: true,
              fillColor: Colors.grey[50],
              prefixIcon: const Icon(Icons.numbers),
              suffixText: _selectedStock != null
                  ? '/ ${_selectedStock!.primaryUnitQuantity * _selectedStock!.secondaryUnitQuantity}'
                  : null,
            ),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Required';
              }
              final qty = int.tryParse(value);
              if (qty == null || qty <= 0) {
                return 'Enter valid quantity';
              }
              if (_selectedStock != null) {
                final maxQty = _selectedStock!.primaryUnitQuantity * _selectedStock!.secondaryUnitQuantity;
                if (qty > maxQty) {
                  return 'Cannot exceed $maxQty';
                }
              }
              return null;
            },
          ),

          if (_selectedStock != null) ...[
            const SizedBox(height: 8),
            Text(
              'Available: ${_selectedStock!.primaryUnitQuantity} ${_selectedStock!.primaryUnit}s (${_selectedStock!.primaryUnitQuantity * _selectedStock!.secondaryUnitQuantity} ${_selectedStock!.secondaryUnit}s)',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[600],
              ),
            ),
          ],
          const SizedBox(height: 24),

          // Photos Section (only for damaged/expired)
          if (_selectedReason == RemovalReason.damaged ||
              _selectedReason == RemovalReason.expired) ...[
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Evidence Photos',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: _photosPaths.isNotEmpty ? Colors.green[50] : Colors.orange[50],
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    _photosPaths.isEmpty ? 'Required' : '${_photosPaths.length} photo(s)',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: _photosPaths.isNotEmpty ? Colors.green[700] : Colors.orange[700],
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            _buildPhotoSection(),
            const SizedBox(height: 24),
          ],

          // Notes
          const Text(
            'Additional Notes',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: _notesController,
            maxLines: 4,
            decoration: InputDecoration(
              hintText: 'Add any additional details...',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              filled: true,
              fillColor: Colors.grey[50],
            ),
          ),
          const SizedBox(height: 32),

          // Submit Button
          SizedBox(
            height: 50,
            child: ElevatedButton(
              onPressed: _selectedStock == null || _selectedReason == null
                  ? null
                  : _handleRemoveStock,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                disabledBackgroundColor: Colors.grey[300],
              ),
              child: const Text(
                'Remove Stock',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStockSelector() {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey[300]!),
        borderRadius: BorderRadius.circular(8),
        color: Colors.grey[50],
      ),
      child: DropdownButtonFormField<StockEntry>(
        value: _selectedStock,
        decoration: const InputDecoration(
          border: InputBorder.none,
          contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          prefixIcon: Icon(Icons.inventory_2),
        ),
        hint: const Text('Select stock item'),
        items: _availableStock.map((stock) {
          final totalItems = stock.primaryUnitQuantity * stock.secondaryUnitQuantity;
          return DropdownMenuItem(
            value: stock,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  stock.product.name,
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
                Text(
                  '${stock.primaryUnitQuantity} ${stock.primaryUnit}s (${totalItems} ${stock.secondaryUnit}s)',
                  style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                ),
              ],
            ),
          );
        }).toList(),
        onChanged: (value) {
          setState(() {
            _selectedStock = value;
          });
        },
        validator: (value) => value == null ? 'Please select an item' : null,
      ),
    );
  }

  Widget _buildReasonSelector() {
    return Column(
      children: RemovalReason.values.map((reason) {
        final isSelected = _selectedReason == reason;
        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          child: InkWell(
            onTap: () {
              setState(() {
                _selectedReason = reason;
              });
            },
            borderRadius: BorderRadius.circular(12),
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: isSelected ? reason.color.withOpacity(0.1) : Colors.grey[50],
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: isSelected ? reason.color : Colors.grey[300]!,
                  width: isSelected ? 2 : 1,
                ),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: reason.color.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(reason.icon, color: reason.color, size: 24),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          reason.displayName,
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: isSelected ? reason.color : Colors.black87,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          reason.description,
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (isSelected)
                    Icon(Icons.check_circle, color: reason.color, size: 24),
                ],
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildPhotoSection() {
    return Column(
      children: [
        if (_photosPaths.isNotEmpty) ...[
          SizedBox(
            height: 120,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: _photosPaths.length,
              itemBuilder: (context, index) {
                return Container(
                  margin: const EdgeInsets.only(right: 12),
                  child: Stack(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Image.file(
                          File(_photosPaths[index]),
                          width: 120,
                          height: 120,
                          fit: BoxFit.cover,
                        ),
                      ),
                      Positioned(
                        top: 4,
                        right: 4,
                        child: InkWell(
                          onTap: () {
                            setState(() {
                              _photosPaths.removeAt(index);
                            });
                          },
                          child: Container(
                            padding: const EdgeInsets.all(4),
                            decoration: BoxDecoration(
                              color: Colors.red,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.close,
                              size: 16,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 12),
        ],
        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () => _addPhoto(ImageSource.camera),
                icon: const Icon(Icons.camera_alt),
                label: const Text('Take Photo'),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  side: BorderSide(color: Colors.blue[300]!),
                  foregroundColor: Colors.blue[700],
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () => _addPhoto(ImageSource.gallery),
                icon: const Icon(Icons.photo_library),
                label: const Text('From Gallery'),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  side: BorderSide(color: Colors.blue[300]!),
                  foregroundColor: Colors.blue[700],
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Future<void> _addPhoto(ImageSource source) async {
    try {
      final XFile? photo = await _imagePicker.pickImage(
        source: source,
        maxWidth: 1920,
        maxHeight: 1080,
        imageQuality: 85,
      );

      if (photo != null) {
        setState(() {
          _photosPaths.add(photo.path);
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error capturing photo: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _handleRemoveStock() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    // Validate photos for damaged/expired items
    if ((_selectedReason == RemovalReason.damaged ||
        _selectedReason == RemovalReason.expired) &&
        _photosPaths.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please add at least one photo for damaged/expired items'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final quantityToRemove = int.parse(_quantityController.text);
      final currentTotalItems = _selectedStock!.primaryUnitQuantity * _selectedStock!.secondaryUnitQuantity;

      // Create stock removal record
      final removal = StockRemoval(
        id: const Uuid().v4(),
        stockId: _selectedStock!.id,
        productName: _selectedStock!.product.name,
        quantity: quantityToRemove,
        reason: _selectedReason!,
        photosPaths: _photosPaths,
        notes: _notesController.text.trim(),
        removedDate: DateTime.now(),
        removedBy: 'Current User', // You can get this from auth
      );

      // Save removal record
      await DataService().addStockRemoval(removal);

      // Update stock quantity
      if (quantityToRemove >= currentTotalItems) {
        // Remove all - mark as picked
        final updatedStock = StockEntry(
          id: _selectedStock!.id,
          product: _selectedStock!.product,
          entryDate: _selectedStock!.entryDate,
          primaryUnitQuantity: _selectedStock!.primaryUnitQuantity,
          primaryUnit: _selectedStock!.primaryUnit,
          secondaryUnitQuantity: _selectedStock!.secondaryUnitQuantity,
          secondaryUnit: _selectedStock!.secondaryUnit,
          buyingPrice: _selectedStock!.buyingPrice,
          sellingPrice: _selectedStock!.sellingPrice,
          picked: true,
          pickedDate: DateTime.now(),
        );
        await DataService().updateStock(updatedStock);
      } else {
        // Partial removal - recalculate quantities
        final remainingSecondaryItems = currentTotalItems - quantityToRemove;
        final newPrimaryQty = remainingSecondaryItems ~/ _selectedStock!.secondaryUnitQuantity;
        final newSecondaryQty = _selectedStock!.secondaryUnitQuantity;

        final updatedStock = StockEntry(
          id: _selectedStock!.id,
          product: _selectedStock!.product,
          entryDate: _selectedStock!.entryDate,
          primaryUnitQuantity: newPrimaryQty,
          primaryUnit: _selectedStock!.primaryUnit,
          secondaryUnitQuantity: newSecondaryQty,
          secondaryUnit: _selectedStock!.secondaryUnit,
          buyingPrice: _selectedStock!.buyingPrice,
          sellingPrice: _selectedStock!.sellingPrice,
          picked: _selectedStock!.picked,
          pickedDate: _selectedStock!.pickedDate,
        );
        await DataService().updateStock(updatedStock);
      }

      setState(() {
        _isLoading = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Removed $quantityToRemove ${_selectedStock!.secondaryUnit}(s) of ${_selectedStock!.product.name}',
            ),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
          ),
        );

        Navigator.pop(context, true);
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error removing stock: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}

// No need for copyWith extension since we're creating new instances