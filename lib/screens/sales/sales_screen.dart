import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:retails/models/sale_entry.dart';
import 'package:retails/screens/sales/sales_entry_card.dart';
import 'package:retails/utils/pdf_exporter.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:share_plus/share_plus.dart';
import '../../service/data_service.dart';
import '../../service/speech_to_text.dart';
import 'add_sale_form.dart';

class SalesScreen extends StatefulWidget {
  const SalesScreen({Key? key}) : super(key: key);

  @override
  State<SalesScreen> createState() => _SalesScreenState();
}

class _SalesScreenState extends State<SalesScreen>
    with SingleTickerProviderStateMixin {
  final RetailSpeechService _speechService = RetailSpeechService();
  final RetailSpeechParser _parser = RetailSpeechParser();

  bool _isListening = false;
  String _spokenText = '';
  ParsedSale? _currentParsedSale;
  List<SaleEntry> _pendingSales = [];
  bool _isProcessing = false;

  late AnimationController _pulseController;

  List<SaleEntry> salesEntries = [];
  bool isLoading = true;
  bool isExportingPdf = false;
  String? errorMessage;
  String? _name;
  String? _phone;
  @override
  void initState() {
    super.initState();
    _initializeSpeech();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    )..repeat(reverse: true);
    getData();
  }

  Future<void> getData() async {
    setState(() {
      isLoading = true;
      errorMessage = null;
    });

    try {
      salesEntries = DataService().allSales();
      setState(() {
        isLoading = false;
      });
    } catch (e) {
      setState(() {
        isLoading = false;
        errorMessage = 'Failed to load sales data: $e';
      });
    }
  }

  Future<void> _exportPdf() async {
    if (salesEntries.isEmpty) {
      _showSnackBar('No sales data to export', isError: true);
      return;
    }

    setState(() {
      isExportingPdf = true;
    });

    try {
      // Generate PDF
      final total = salesEntries.fold<double>(0.0, (sum, entry) => sum + entry.total);
      final pdfBytes = await PdfExporter.generateSalesReport(
        DateTime.now(),
        salesEntries,
        total,
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
      final fileName = 'sales_report_$timestamp.pdf';
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
            const Text('Your sales report has been generated successfully!'),
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
                text: 'Sales Report - 4Retails',
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
  void dispose() {
    _pulseController.dispose();
    _speechService.stopListening();
    super.dispose();
  }

  Future<bool> requestMicrophonePermission() async {
    PermissionStatus status = await Permission.microphone.status;

    if (status.isGranted) {
      return true;
    }

    if (status.isDenied) {
      status = await Permission.microphone.request();
      return status.isGranted;
    }

    if (status.isPermanentlyDenied) {
      // Open app settings if user permanently denied
      await openAppSettings();
      return false;
    }

    return false;
  }

  Future<void> _initializeSpeech() async {
    bool hasPermission = await requestMicrophonePermission();
    if (!hasPermission) {
      debugPrint('Microphone permission not granted');
      return;
    }
    final initialized = await _speechService.init((status){
      print("status: $status");
      if(status=='done'){
        _stopListening();
      }else if(status=='listening'){
        _isListening = true;
      }else if(status=='notListening'){
        _stopListening();
      }
      setState(() {});
    },(error){
      print("error: $error");
      if(error.errorMsg.isNotEmpty){
        _isListening = false;
        _stopListening();
      }
      setState(() {});
    });
  }

  void _toggleListening() {
    if (_isListening) {
      _stopListening();
    } else {
      _startListening();
    }
  }

  void _startListening() {
    setState(() {
      _isListening = true;
      _spokenText = '';
      _currentParsedSale = null;
    });

    _speechService.startListening((text) {
      setState(() {
        _spokenText = text;
      });
      _processSpeech(text);
    });
  }

  void _stopListening() {
    _speechService.stopListening();
    setState(() {
      _isListening = false;
    });
  }

  Future<void> _processSpeech(String text) async {
    setState(() {
      _isProcessing = true;
    });

    try {
      final intent = _parser.detectIntent(text);

      switch (intent) {
        case SpeechIntent.sale:
          final parsedSale = await _parser.parseSale(text);
          setState(() {
            _currentParsedSale = parsedSale;
            _isProcessing = false;
          });
          break;

        case SpeechIntent.confirm:
          if (_currentParsedSale != null) {
            await _confirmSale();
          }
          break;

        case SpeechIntent.cancel:
          setState(() {
            _currentParsedSale = null;
            _spokenText = '';
          });
          break;

        case SpeechIntent.priceQuery:
        case SpeechIntent.stockQuery:
        // Handle queries
          break;
      }
    } catch (e) {
      setState(() {
        _isProcessing = false;
      });
    }
  }

  Future<void> _confirmSale() async {
    if (_currentParsedSale == null) return;

    if (_currentParsedSale!.needsPriceConfiguration) {
      _showPriceConfigDialog();
      return;
    }

    setState(() {
      _isProcessing = true;
    });

    try {
      final saleEntry = await _parser.createSaleEntry(_currentParsedSale!);

      if (saleEntry != null) {
        await DataService().addSale(saleEntry);

        setState(() {
          _pendingSales.add(saleEntry);
          _currentParsedSale = null;
          _spokenText = '';
          _isProcessing = false;
        });

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Sale added: ${_currentParsedSale!.toString()}'),
              backgroundColor: Colors.green,
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      }
    } catch (e) {
      setState(() {
        _isProcessing = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _showPriceConfigDialog() {
    final priceController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Configure Price'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'No price found for:\n${_currentParsedSale!.quantity} ${_currentParsedSale!.unit} of ${_currentParsedSale!.productName}',
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            TextField(
              controller: priceController,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: const InputDecoration(
                labelText: 'Price (KES)',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              final price = double.tryParse(priceController.text);
              if (price != null && price > 0) {
                // Add price to product
                // Then confirm sale
                Navigator.pop(context);
                await _confirmSale();
              }
            },
            child: const Text('Save & Continue'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Sales Timeline'),
            if (salesEntries.isNotEmpty)
              Text(
                '${salesEntries.length} ${salesEntries.length == 1 ? 'sale' : 'sales'}',
                style: const TextStyle(fontSize: 12),
              ),
          ],
        ),
        actions: [
          if (!isLoading && salesEntries.isNotEmpty)
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
            icon: const Icon(Icons.add_box),
            onPressed: () async {
              final result = await Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const AddSaleForm()),
              );

              // Refresh data if a sale was added
              if (result == true) {
                getData();
              }
            },
            tooltip: 'Add Sale',
          ),
        ],
      ),
      body: Stack(
        children: [
          _buildBody(),
          Align(
              alignment: Alignment.bottomCenter,
              child: Padding(
                padding: EdgeInsets.only(bottom: MediaQuery.of(context).size.height*0.1),
                child: _bottomSheet(),
              )),
          Align(
            alignment: AlignmentGeometry.bottomCenter,
            child: Padding(
              padding: const EdgeInsets.all(5.0),
              child: _buildVoiceButton(),
            ),
          )
        ],
      ),
    );
  }

  Widget _buildBody() {
    if (isLoading) {
      return _buildLoadingState();
    }

    if (errorMessage != null) {
      return _buildErrorState();
    }

    if (salesEntries.isEmpty) {
      return _buildEmptyState();
    }

    return _buildSalesList();
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
              'No sales yet',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 8),
           /* Text(
              'Start by adding your first sale',
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
                  MaterialPageRoute(builder: (context) => const AddSaleForm()),
                );

                if (result == true) {
                  getData();
                }
              },
              icon: const Icon(Icons.add),
              label: const Text('Add Sale'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 12,
                ),
              ),
            ),*/
          ],
        ),
      ),
    );
  }

  Widget _buildSalesList() {
    final total = salesEntries.fold<double>(0.0, (sum, entry) => sum + entry.total);

    return Column(
      children: [
        // Summary Card
        Container(
          margin: const EdgeInsets.all(16),
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.blue[700]!, Colors.blue[900]!],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.blue.withOpacity(0.3),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Total Sales',
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'KES ${total.toStringAsFixed(2)}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  Icons.trending_up,
                  color: Colors.greenAccent[400],
                  size: 32,
                ),
              ),
            ],
          ),
        ),

        // Sales List
        Expanded(
          child: RefreshIndicator(
            onRefresh: getData,
            child: ListView.builder(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              itemCount: salesEntries.length,
              itemBuilder: (context, index) {
                return SalesEntryCard(
                  entry: salesEntries[index],
                  key: ValueKey(salesEntries[index].id),
                );
              },
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildListeningIndicator() {
    return AnimatedBuilder(
      animation: _pulseController,
      builder: (context, child) {
        return Container(
          margin: const EdgeInsets.symmetric(horizontal: 16),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.red.withOpacity(0.1 + (_pulseController.value * 0.2)),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: Colors.red.withOpacity(0.3 + (_pulseController.value * 0.3)),
              width: 2,
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.mic,
                color: Colors.red[700],
                size: 20,
              ),
              const SizedBox(width: 12),
              Text(
                'Listening...',
                style: TextStyle(
                  color: Colors.red[700],
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildSpokenTextDisplay() {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(20),
      width: double.infinity,
      constraints: const BoxConstraints(minHeight: 100),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.record_voice_over, size: 20, color: Colors.grey[600]),
              const SizedBox(width: 8),
              Text(
                'You said:',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            _spokenText.isEmpty
                ? 'Your spoken words will appear here...'
                : _spokenText,
            style: TextStyle(
              fontSize: 18,
              color: _spokenText.isEmpty ? Colors.grey[400] : Colors.black87,
              fontStyle: _spokenText.isEmpty ? FontStyle.italic : FontStyle.normal,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildParsedSaleCard() {
    final sale = _currentParsedSale!;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: sale.needsPriceConfiguration ? Colors.orange[50] : Colors.green[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: sale.needsPriceConfiguration ? Colors.orange[200]! : Colors.green[200]!,
          width: 2,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                sale.needsPriceConfiguration ? Icons.warning : Icons.check_circle,
                color: sale.needsPriceConfiguration ? Colors.orange[700] : Colors.green[700],
              ),
              const SizedBox(width: 12),
              Text(
                sale.needsPriceConfiguration ? 'Price Needed' : 'Parsed Sale',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: sale.needsPriceConfiguration ? Colors.orange[900] : Colors.green[900],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _buildDetailRow('Product', sale.productName),
          _buildDetailRow('Quantity', '${sale.quantity}'),
          _buildDetailRow('unit', '${sale.unit}'),
          if (!sale.needsPriceConfiguration) ...[
            _buildDetailRow('Price', 'KES ${sale.pricePerItem.toStringAsFixed(2)}'),
            const Divider(),
            _buildDetailRow(
              'Total',
              'KES ${sale.total.toStringAsFixed(2)}',
              isBold: true,
            ),
          ],
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () {
                    setState(() {
                      _currentParsedSale = null;
                      _spokenText = '';
                    });
                  },
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.red,
                    side: const BorderSide(color: Colors.red),
                  ),
                  child: const Text('Cancel'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton(
                  onPressed: _isProcessing ? null : _confirmSale,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    foregroundColor: Colors.white,
                  ),
                  child: _isProcessing
                      ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation(Colors.white),
                    ),
                  )
                      : const Text('Confirm'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value, {bool isBold = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(fontSize: 14),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: 14,
              fontWeight: isBold ? FontWeight.bold : FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPendingSalesList() {
    return Container(
      margin: const EdgeInsets.all(16),
      constraints: const BoxConstraints(maxHeight: 150),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Recent Sales',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: Colors.grey[700],
            ),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: ListView.builder(
              itemCount: _pendingSales.length,
              itemBuilder: (context, index) {
                final sale = _pendingSales[_pendingSales.length - 1 - index];
                return Container(
                  margin: const EdgeInsets.only(bottom: 6),
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.green[50],
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.green[200]!),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        '${sale.product.name} - ${sale.quantity} ${sale.primaryUnit}',
                        style: const TextStyle(fontSize: 13),
                      ),
                      Text(
                        'KES ${sale.total.toStringAsFixed(2)}',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: Colors.green[700],
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget  _bottomSheet(){
    return AnimatedContainer(
      height: _currentParsedSale != null?MediaQuery.of(context).size.height*0.55:0,
      width: MediaQuery.of(context).size.width,
      margin: EdgeInsets.symmetric(horizontal: 5),
      decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.only(topLeft:Radius.circular(8) ,topRight:Radius.circular(8))
      ),
      duration: Duration(milliseconds: 400),
      child:Column(
        children: [
          // Spoken Text Display
          if(mounted) _buildSpokenTextDisplay(),
          // Parsed Sale Display
          if (_currentParsedSale != null) _buildParsedSaleCard(),
          const Spacer(),
          // Pending Sales List
          if (_pendingSales.isNotEmpty) _buildPendingSalesList(),
        ],
      ),
    );
  }

  Widget _buildVoiceButton() {
    return GestureDetector(
      onTap: _toggleListening,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        width: 120,
        height: 120,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: _isListening ? Colors.red : Colors.blue,
          boxShadow: [
            BoxShadow(
              color: (_isListening ? Colors.red : Colors.blue).withOpacity(0.4),
              blurRadius: 20,
              spreadRadius: 5,
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              _isListening ? Icons.mic : Icons.mic_none,
              size: 48,
              color: Colors.white,
            ),
            const SizedBox(height: 8),
            Text(
              _isListening ? 'Stop' : 'Start',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }
}