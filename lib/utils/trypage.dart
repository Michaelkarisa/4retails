import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:retails/models/sale_entry.dart';
import 'package:retails/service/data_service.dart';

import '../service/speech_to_text.dart';

class SpeechSalesPage extends StatefulWidget {
  const SpeechSalesPage({super.key});

  @override
  State<SpeechSalesPage> createState() => _SpeechSalesPageState();
}

class _SpeechSalesPageState extends State<SpeechSalesPage> with SingleTickerProviderStateMixin {
  final RetailSpeechService _speechService = RetailSpeechService();
  final RetailSpeechParser _parser = RetailSpeechParser();

  bool _isListening = false;
  String _spokenText = '';
  ParsedSale? _currentParsedSale;
  List<SaleEntry> _pendingSales = [];
  bool _isProcessing = false;

  late AnimationController _pulseController;

  @override
  void initState() {
    super.initState();
    _initializeSpeech();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    )..repeat(reverse: true);
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
        title: const Text('Sales'),
        actions: [
          if (_pendingSales.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(right: 16),
              child: Center(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.green,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    '${_pendingSales.length} sale${_pendingSales.length > 1 ? 's' : ''}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
      body: Column(
        children: [
          // Instructions Card
          Container(
            margin: const EdgeInsets.all(16),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.blue[50],
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.blue[200]!),
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    Icon(Icons.mic, color: Colors.blue[700]),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Say items like: "2 kg sugar" or "half litre milk"',
                        style: TextStyle(
                          color: Colors.blue[900],
                          fontSize: 13,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  'Supported: quarter/half/whole units, kg/litre/piece',
                  style: TextStyle(
                    color: Colors.blue[700],
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),

          // Listening Indicator
          if (_isListening) _buildListeningIndicator(),

          // Spoken Text Display
          if(mounted) _buildSpokenTextDisplay(),

          // Parsed Sale Display
          if (_currentParsedSale != null) _buildParsedSaleCard(),

          const Spacer(),

          // Pending Sales List
          if (_pendingSales.isNotEmpty) _buildPendingSalesList(),

          // Voice Button
          _buildVoiceButton(),
          const SizedBox(height: 32),
        ],
      ),
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