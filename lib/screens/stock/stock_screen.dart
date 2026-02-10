import 'package:flutter/material.dart';
import 'package:retails/screens/stock/remove_stock_screen.dart';
import 'package:retails/service/data_service.dart';
import '../../models/stock_entry.dart';
import '../stock/add_stock_screen.dart';
import 'stock_entry_card.dart';
import '../../utils/sample_data.dart';
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:retails/models/sale_entry.dart';
import 'package:retails/screens/sales/sales_entry_card.dart';
import 'package:retails/utils/pdf_exporter.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:share_plus/share_plus.dart';

class StockScreen extends StatefulWidget {
  const StockScreen({Key? key}) : super(key: key);

  @override
  State<StockScreen> createState() => _StockScreenState();
}

class _StockScreenState extends State<StockScreen> with SingleTickerProviderStateMixin {
  bool isExportingPdf = false;
  String? errorMessage;
  @override
  void initState(){
    super.initState();
    getData();
  }
  Future<void> getData() async{
    setState(() {
      isLoading = true;
    });
    stockEntries =  DataService().allStocks();
    setState(() {
      isLoading = false;
    });
  }
  List<StockEntry> stockEntries  = [];
  bool isLoading = true;
  Future<void> _exportPdf() async {
    if (stockEntries.isEmpty) {
      _showSnackBar('No stock data to export', isError: true);
      return;
    }

    setState(() {
      isExportingPdf = true;
    });

    try {
      // Generate PDF
      //final total = stockEntries.fold<double>(0.0, (sum, entry) => sum + entry.total);
      final data = DataService();
      final stockReceived = await data.stockReceived();
      final stockPicked = await data.stockPicked();
      final availableStock = await data.availableStock();
      final lowStock = await data.lowStock();

      final stockMap = {
        'received':stockReceived,
        'picked':stockPicked,
        'available':availableStock,
      };
      final pdfBytes = await PdfExporter.generateStockReport(
        DateTime.now(),
        stockMap,
      );

      // Save PDF internally (no permission required)
      final filePath = await _savePdf(pdfBytes);

      if (filePath != null) {
        setState(() {
          isExportingPdf = false;
        });

        _showExportSuccessDialog(filePath);
      } else {
        setState(() {
          isExportingPdf = false;
        });
        _showSnackBar('Failed to save PDF', isError: true);
      }
    } catch (e) {
      setState(() {
        isExportingPdf = false;
      });
      _showSnackBar('Error exporting PDF: $e', isError: true);
    }
  }

  Future<bool> _requestStoragePermission() async {
    if (Platform.isAndroid) {
      if (await Permission.manageExternalStorage.isPermanentlyDenied ||
          await Permission.storage.isPermanentlyDenied ||
          await Permission.photos.isPermanentlyDenied) {
        await openAppSettings();
        return false;
      }

      // Android 13+
      if (Platform.version.contains('13')) {
        var status = await Permission.photos.status;
        if (!status.isGranted) {
          status = await Permission.photos.request();
        }
        return status.isGranted;
      }
      // Android 10-12
      else if (Platform.version.contains('12') || Platform.version.contains('11') || Platform.version.contains('10')) {
        var status = await Permission.storage.status;
        if (!status.isGranted) {
          status = await Permission.storage.request();
        }
        return status.isGranted;
      }
    }

    return true; // iOS doesn't need extra storage permissions
  }

// Save PDF internally (safe for all Android/iOS)
  Future<String?> _savePdf(Uint8List pdfBytes) async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final fileName = 'stock_report_$timestamp.pdf';
      final file = File('${directory.path}/$fileName');

      await file.writeAsBytes(pdfBytes);
      return file.path;
    } catch (e) {
      debugPrint('Error saving PDF: $e');
      return null;
    }
  }


  void _showExportSuccessDialog(String filePath) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Icon(Icons.check_circle, color: Colors.green[600], size: 28),
            const SizedBox(width: 12),
            const Text('PDF Exported'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Your stock report has been generated successfully!'),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(Icons.folder_outlined, size: 20, color: Colors.grey[600]),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      filePath,
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[600],
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
          ElevatedButton.icon(
            onPressed: () async {
              Navigator.pop(context);
              await Share.shareXFiles(
                [XFile(filePath)],
                text: 'Stock Report - 4Retails',
              );
            },
            icon: const Icon(Icons.share),
            label: const Text('Share'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue,
              foregroundColor: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  void _showSnackBar(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.red : Colors.green,
        behavior: SnackBarBehavior.floating,
        action: isError
            ? SnackBarAction(
          label: 'Retry',
          textColor: Colors.white,
          onPressed: getData,
        )
            : null,
      ),
    );
  }
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Stock Timeline'),
        actions: [
          if (!isLoading && stockEntries.isNotEmpty)
            IconButton(
              icon: isExportingPdf
                  ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              )
                  : const Icon(Icons.picture_as_pdf),
              onPressed: isExportingPdf ? null : _exportPdf,
              tooltip: 'Export PDF',
            ),
          IconButton(
            tooltip: 'Move to Selling Stall',
            icon: const Icon(Icons.outbox),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const RemoveStockScreen(),
                ),
              );
            },
          ),
          const SizedBox(width: 10),
          IconButton(
            tooltip: 'Add New Stock',
            icon: const Icon(Icons.add_box),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const AddStockScreen(),
                ),
              );
            },
          ),
        ],
      ),

      body: _buildBody(),
    );
  }
  Widget _buildBody() {
    if (isLoading) {
      return _buildLoadingState();
    }

    if (errorMessage != null) {
      return _buildErrorState();
    }

    if (stockEntries.isEmpty) {
      return _buildEmptyState();
    }

    return _buildStockList();
  }

  Widget _buildLoadingState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(Colors.blue[700]!),
          ),
          const SizedBox(height: 16),
          Text(
            'Loading sales data...',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStockList() {
    return RefreshIndicator(
      onRefresh: ()async{
        await getData();
      },
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: stockEntries.length,
        itemBuilder: (context, index) {
          return StockEntryCard(entry: stockEntries[index]);
        },
      ),
    );

  }
  Widget _buildErrorState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 80,
              color: Colors.red[300],
            ),
            const SizedBox(height: 16),
            Text(
              'Oops! Something went wrong',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Colors.grey[800],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              errorMessage ?? 'Unknown error',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[600],
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: getData,
              icon: const Icon(Icons.refresh),
              label: const Text('Retry'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 12,
                ),
              ),
            ),
          ],
        ),
      ),
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
              Icons.receipt_long_outlined,
              size: 80,
              color: Colors.grey[300],
            ),
            const SizedBox(height: 16),
            Text(
              'No stock yet',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Start by adding your first stock',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[500],
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () async {
                final result = await Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const AddStockScreen()),
                );

                if (result == true) {
                  getData();
                }
              },
              icon: const Icon(Icons.add),
              label: const Text('Add Stock'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 12,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }


}
