import 'dart:io';

import 'package:flutter/material.dart';
import '../../models/loan_entry.dart';
import '../../models/sale_entry.dart';
import '../../service/data_service.dart';
import 'lending_card.dart';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:retails/models/sale_entry.dart';
import 'package:retails/screens/sales/sales_entry_card.dart';
import 'package:retails/utils/pdf_exporter.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:share_plus/share_plus.dart';

class Lending extends StatefulWidget {
  const Lending({super.key});

  @override
  State<Lending> createState() => _LendingState();
}

class _LendingState extends State<Lending> with SingleTickerProviderStateMixin {
  Map<LoanEntry, List<SaleEntry>> allDebts = {};
  bool isLoading = true;
  bool isExportingPdf = false;
  String? errorMessage;

  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    getData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> getData() async {
    setState(() {
      isLoading = true;
      errorMessage = null;
    });

    try {
      allDebts = await DataService().getAllDebts();
      setState(() {
        isLoading = false;
      });
    } catch (e) {
      setState(() {
        isLoading = false;
        errorMessage = 'Failed to load debts data: $e';
      });
    }
  }

  Future<void> _exportPdf() async {
    if (allDebts.isEmpty) {
      _showSnackBar('No debt data to export', isError: true);
      return;
    }

    setState(() {
      isExportingPdf = true;
    });

    try {
      final pdfBytes = await PdfExporter.generateDebtsReport(
        DateTime.now(),
        allDebts,
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
      final fileName = 'debt_report_$timestamp.pdf';
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
            const Text('Your debt report has been generated successfully!'),
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
                text: 'Debt Report - 4Retails',
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
    final stats = _calculateStats();

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Debts Management'),
            if (allDebts.isNotEmpty)
              Text(
                '${allDebts.length} ${allDebts.length == 1 ? 'debtor' : 'debtors'}',
                style: const TextStyle(fontSize: 12),
              ),
          ],
        ),
        bottom: TabBar(
          controller: _tabController,
          tabs: [
            Tab(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.pending_actions, size: 18),
                  const SizedBox(width: 8),
                  Text('Pending (${stats['pending']})'),
                ],
              ),
            ),
            Tab(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.check_circle, size: 18),
                  const SizedBox(width: 8),
                  Text('Paid (${stats['paid']})'),
                ],
              ),
            ),
          ],
        ),
        actions: [
          if (!isLoading && allDebts.isNotEmpty)
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
        ],
      ),
      body: _buildBody(stats),
    );
  }

  Map<String, int> _calculateStats() {
    final pending = allDebts.keys.where((loan) => !loan.isPaid).length;
    final paid = allDebts.keys.where((loan) => loan.isPaid).length;

    return {
      'pending': pending,
      'paid': paid,
      'total': allDebts.length,
    };
  }

  Widget _buildBody(Map<String, int> stats) {
    if (isLoading) {
      return _buildLoadingState();
    }

    if (errorMessage != null) {
      return _buildErrorState();
    }

    if (allDebts.isEmpty) {
      return _buildEmptyState();
    }

    return Column(
      children: [
        _buildSummaryCards(),
        Expanded(
          child: TabBarView(
            controller: _tabController,
            children: [
              _buildDebtsList(false), // Pending
              _buildDebtsList(true),  // Paid
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSummaryCards() {
    double totalDebt = 0;
    double totalPaid = 0;
    double totalBalance = 0;
    List<SaleEntry> allSales = [];
    for (final entry in allDebts.entries) {
      final loan = entry.key;
      //totalDebt += loan.totalAmount;
      totalPaid += loan.amountPaid;
      totalBalance += loan.balance;
      allSales.addAll(entry.value);
    }
     totalDebt = allSales.fold<double>(0.0, (sum, sale) => sum + sale.total);
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.orange[700]!, Colors.orange[900]!],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.orange.withOpacity(0.3),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: _buildSummaryItem(
                  icon: Icons.account_balance_wallet,
                  label: 'Total Debt',
                  value: 'KES ${totalDebt.toStringAsFixed(0)}',
                  color: Colors.white,
                ),
              ),
              Container(
                width: 1,
                height: 50,
                color: Colors.white.withOpacity(0.3),
              ),
              Expanded(
                child: _buildSummaryItem(
                  icon: Icons.check_circle,
                  label: 'Paid',
                  value: 'KES ${totalPaid.toStringAsFixed(0)}',
                  color: Colors.greenAccent[400]!,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.trending_down,
                      color: Colors.redAccent[200],
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    const Text(
                      'Outstanding Balance',
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
                Text(
                  'KES ${totalBalance.toStringAsFixed(2)}',
                  style: TextStyle(
                    color: Colors.redAccent[200],
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryItem({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Column(
      children: [
        Icon(icon, color: color, size: 24),
        const SizedBox(height: 8),
        Text(
          value,
          style: TextStyle(
            color: color,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: const TextStyle(
            color: Colors.white70,
            fontSize: 12,
          ),
        ),
      ],
    );
  }

  Widget _buildDebtsList(bool showPaid) {
    final filteredDebts = Map.fromEntries(
      allDebts.entries.where((entry) => entry.key.isPaid == showPaid),
    );

    if (filteredDebts.isEmpty) {
      return _buildEmptyTabState(showPaid);
    }

    return RefreshIndicator(
      onRefresh: getData,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: filteredDebts.length,
        itemBuilder: (context, index) {
          final loanEntry = filteredDebts.keys.toList()[index];
          final sales = filteredDebts[loanEntry]!;
          return LoanEntryCard(
            key: ValueKey(loanEntry.id),
            loanEntry: loanEntry,
            sales: sales,
          );
        },
      ),
    );
  }

  Widget _buildEmptyTabState(bool isPaidTab) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              isPaidTab ? Icons.check_circle_outline : Icons.receipt_long_outlined,
              size: 80,
              color: Colors.grey[300],
            ),
            const SizedBox(height: 16),
            Text(
              isPaidTab ? 'No paid debts' : 'No pending debts',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              isPaidTab
                  ? 'Cleared debts will appear here'
                  : 'Outstanding debts will appear here',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[500],
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLoadingState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(Colors.orange[700]!),
          ),
          const SizedBox(height: 16),
          Text(
            'Loading debts data...',
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
                backgroundColor: Colors.orange,
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
              Icons.account_balance_wallet_outlined,
              size: 80,
              color: Colors.grey[300],
            ),
            const SizedBox(height: 16),
            Text(
              'No debts recorded',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Credit sales will appear here',
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
}