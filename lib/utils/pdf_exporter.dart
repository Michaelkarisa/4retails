import 'dart:typed_data';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:intl/intl.dart';
import '../models/sale_entry.dart';
import '../models/loan_entry.dart';
import '../models/product.dart';
// lib/utils/pdf_colors.dart
import 'package:pdf/pdf.dart';

class PdfExporter {
  // ==================== SALES REPORT ====================
  static Future<Uint8List> generateSalesReport(
      DateTime date,
      List<SaleEntry> sales,
      double total,
      ) async {
    final pdf = pw.Document();
    final formatter = NumberFormat("#,##0.00", "en_KE");
    final dateFormatter = DateFormat('dd MMM yyyy');
    final timeFormatter = DateFormat('hh:mm a');

    // Calculate statistics
    final totalItems = sales.fold<int>(0, (sum, sale) => sum + sale.quantity.toInt());
    final averageValue = sales.isNotEmpty ? total / sales.length : 0.0;
    final uniqueProducts = sales.map((e) => e.product.name).toSet().length;

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        build: (context) => [
          // Header Section
          _buildHeader(dateFormatter, timeFormatter, date, 'Sales Report'),
          pw.SizedBox(height: 20),
          pw.Divider(thickness: 2),
          pw.SizedBox(height: 20),
          // Summary Cards
          _buildSummarySection(total, totalItems, sales.length, uniqueProducts, formatter),
          pw.SizedBox(height: 30),
          // Sales Table
          _buildSalesTable(sales, formatter),
          pw.SizedBox(height: 20),
          // Total Section
          _buildTotalSection(total, formatter),
        ],
        footer: (context) => _buildFooter(context),
      ),
    );

    return pdf.save();
  }

  // ==================== STOCK REPORT ====================
  // Generate Stock Report
  static Future<Uint8List> generateStockReport(
      DateTime date,
      Map<String, dynamic> stockData,
      ) async {
    final pdf = pw.Document();
    final dateFormatter = DateFormat('dd MMM yyyy');
    final timeFormatter = DateFormat('hh:mm a');

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        build: (context) => [
          // Header
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text(
                    '4Retails',
                    style: pw.TextStyle(
                      fontSize: 28,
                      fontWeight: pw.FontWeight.bold,
                      color: PdfColors.blue700,
                    ),
                  ),
                  pw.SizedBox(height: 4),
                  pw.Text(
                    'Stock Report',
                    style: pw.TextStyle(
                      fontSize: 16,
                      color: PdfColors.grey700,
                    ),
                  ),
                ],
              ),
              pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.end,
                children: [
                  pw.Text(
                    dateFormatter.format(date),
                    style: pw.TextStyle(
                      fontSize: 14,
                      fontWeight: pw.FontWeight.bold,
                    ),
                  ),
                  pw.SizedBox(height: 4),
                  pw.Text(
                    'Generated: ${timeFormatter.format(DateTime.now())}',
                    style: pw.TextStyle(
                      fontSize: 10,
                      color: PdfColors.grey600,
                    ),
                  ),
                ],
              ),
            ],
          ),
          pw.SizedBox(height: 20),
          pw.Divider(thickness: 2),
          pw.SizedBox(height: 20),

          // Stock Overview
          pw.Container(
            padding: const pw.EdgeInsets.all(16),
            decoration: pw.BoxDecoration(
              color: PdfColors.blue50,
              borderRadius: pw.BorderRadius.circular(8),
              border: pw.Border.all(color: PdfColors.blue200, width: 1),
            ),
            child: pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceAround,
              children: [
                _buildSummaryCard(
                  'Stock Received',
                  stockData['received'].toString(),
                  PdfColors.green700,
                ),
                _buildSummaryCard(
                  'Stock Picked',
                  stockData['picked'].toString(),
                  PdfColors.orange700,
                ),
                _buildSummaryCard(
                  'Available Stock',
                  stockData['available'].toString(),
                  PdfColors.blue700,
                ),
              ],
            ),
          ),
        ],
        footer: (context) => _buildFooter(context),
      ),
    );

    return pdf.save();
  }



  // ==================== DEBTS REPORT ====================
  static Future<Uint8List> generateDebtsReport(
      DateTime date,
      Map<LoanEntry, List<SaleEntry>> debtData,
      ) async {
    final pdf = pw.Document();
    final formatter = NumberFormat("#,##0.00", "en_KE");
    final dateFormatter = DateFormat('dd MMM yyyy');
    final timeFormatter = DateFormat('hh:mm a');

    // Calculate statistics
    final allLoans = debtData.keys.toList();
    final pendingLoans = allLoans.where((loan) => !loan.isPaid).toList();
    final paidLoans = allLoans.where((loan) => loan.isPaid).toList();

    final totalDebt = allLoans.fold<double>(0.0, (sum, loan) => sum + loan.totalAmount);
    final totalPaid = allLoans.fold<double>(0.0, (sum, loan) => sum + loan.amountPaid);
    final totalOutstanding = allLoans.fold<double>(0.0, (sum, loan) => sum + loan.balance);

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        build: (context) => [
          // Header
          _buildHeader(dateFormatter, timeFormatter, date, 'Debts Report'),
          pw.SizedBox(height: 20),
          pw.Divider(thickness: 2),
          pw.SizedBox(height: 20),
          // Debt Summary Cards
          _buildDebtSummarySection(
            totalDebt,
            totalPaid,
            totalOutstanding,
            pendingLoans.length,
            paidLoans.length,
            formatter,
          ),
          pw.SizedBox(height: 30),
          // Debtors Table
          if (allLoans.isNotEmpty) ...[
            _buildDebtorsTable(allLoans, formatter),
            pw.SizedBox(height: 30),
          ],
          // Individual Debtor Details
          ..._buildDebtorDetailsSections(debtData, formatter),
        ],
        footer: (context) => _buildFooter(context),
      ),
    );

    return pdf.save();
  }

  // ==================== REUSABLE WIDGETS ====================
  static pw.Widget _buildHeader(
      DateFormat dateFormatter,
      DateFormat timeFormatter,
      DateTime date,
      String reportType,
      ) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          children: [
            pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text(
                  '4Retails',
                  style: pw.TextStyle(
                    fontSize: 28,
                    fontWeight: pw.FontWeight.bold,
                    color: PdfColors.blue700,
                  ),
                ),
                pw.SizedBox(height: 4),
                pw.Text(
                  reportType,
                  style: pw.TextStyle(
                    fontSize: 16,
                    color: PdfColors.grey700,
                  ),
                ),
              ],
            ),
            pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.end,
              children: [
                pw.Text(
                  dateFormatter.format(date),
                  style: pw.TextStyle(
                    fontSize: 14,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
                pw.SizedBox(height: 4),
                pw.Text(
                  'Generated: ${timeFormatter.format(DateTime.now())}',
                  style: pw.TextStyle(
                    fontSize: 10,
                    color: PdfColors.grey600,
                  ),
                ),
              ],
            ),
          ],
        ),
      ],
    );
  }

  static pw.Widget _buildSummarySection(
      double total,
      int totalItems,
      int transactions,
      int uniqueProducts,
      NumberFormat formatter,
      ) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(16),
      decoration: pw.BoxDecoration(
        color: PdfColors.blue50,
        borderRadius: pw.BorderRadius.circular(8),
        border: pw.Border.all(color: PdfColors.blue200, width: 1),
      ),
      child: pw.Column(
        children: [
          pw.Text(
            'Summary',
            style: pw.TextStyle(
              fontSize: 16,
              fontWeight: pw.FontWeight.bold,
              color: PdfColors.blue900,
            ),
          ),
          pw.SizedBox(height: 12),
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceAround,
            children: [
              _buildSummaryCard(
                'Total Revenue',
                'KES ${formatter.format(total)}',
                PdfColors.green700,
              ),
              _buildSummaryCard(
                'Transactions',
                transactions.toString(),
                PdfColors.blue700,
              ),
              _buildSummaryCard(
                'Items Sold',
                totalItems.toString(),
                PdfColors.orange700,
              ),
              _buildSummaryCard(
                'Products',
                uniqueProducts.toString(),
                PdfColors.purple700,
              ),
            ],
          ),
        ],
      ),
    );
  }

  static pw.Widget _buildStockSummarySection(
      Map<String, dynamic> stockData,
      int lowStockItems,
      double totalValue,
      NumberFormat formatter,
      ) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(16),
      decoration: pw.BoxDecoration(
        color: PdfColors.blue50,
        borderRadius: pw.BorderRadius.circular(8),
        border: pw.Border.all(color: PdfColors.blue200, width: 1),
      ),
      child: pw.Column(
        children: [
          pw.Text(
            'Stock Overview',
            style: pw.TextStyle(
              fontSize: 16,
              fontWeight: pw.FontWeight.bold,
              color: PdfColors.blue900,
            ),
          ),
          pw.SizedBox(height: 12),
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceAround,
            children: [
              _buildSummaryCard(
                'Stock Received',
                stockData['received'].toString(),
                PdfColors.green700,
              ),
              _buildSummaryCard(
                'Stock Picked',
                stockData['picked'].toString(),
                PdfColors.orange700,
              ),
              _buildSummaryCard(
                'Available Stock',
                stockData['available'].toString(),
                PdfColors.blue700,
              ),
              _buildSummaryCard(
                'Low Stock Items',
                lowStockItems.toString(),
                PdfColors.red700,
              ),
            ],
          ),
          pw.SizedBox(height: 12),
          pw.Container(
            padding: const pw.EdgeInsets.all(12),
            decoration: pw.BoxDecoration(
              color: PdfColors.green50,
              borderRadius: pw.BorderRadius.circular(6),
              border: pw.Border.all(color: PdfColors.green200, width: 1),
            ),
            child: pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Text(
                  'Total Stock Value',
                  style: pw.TextStyle(
                    fontSize: 14,
                    fontWeight: pw.FontWeight.bold,
                    color: PdfColors.green900,
                  ),
                ),
                pw.Text(
                  'KES ${formatter.format(totalValue)}',
                  style: pw.TextStyle(
                    fontSize: 18,
                    fontWeight: pw.FontWeight.bold,
                    color: PdfColors.green700,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  static pw.Widget _buildDebtSummarySection(
      double totalDebt,
      double totalPaid,
      double totalOutstanding,
      int pendingCount,
      int paidCount,
      NumberFormat formatter,
      ) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(16),
      decoration: pw.BoxDecoration(
        color: PdfColors.blue50,
        borderRadius: pw.BorderRadius.circular(8),
        border: pw.Border.all(color: PdfColors.blue200, width: 1),
      ),
      child: pw.Column(
        children: [
          pw.Text(
            'Debt Summary',
            style: pw.TextStyle(
              fontSize: 16,
              fontWeight: pw.FontWeight.bold,
              color: PdfColors.blue900,
            ),
          ),
          pw.SizedBox(height: 12),
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceAround,
            children: [
              _buildSummaryCard(
                'Total Debt',
                'KES ${formatter.format(totalDebt)}',
                PdfColors.red700,
              ),
              _buildSummaryCard(
                'Paid',
                'KES ${formatter.format(totalPaid)}',
                PdfColors.green700,
              ),
              _buildSummaryCard(
                'Outstanding',
                'KES ${formatter.format(totalOutstanding)}',
                PdfColors.orange700,
              ),
              _buildSummaryCard(
                'Pending',
                pendingCount.toString(),
                PdfColors.red700,
              ),
            ],
          ),
          pw.SizedBox(height: 12),
          if (totalDebt > 0) ...[
            pw.Container(
              padding: const pw.EdgeInsets.all(12),
              decoration: pw.BoxDecoration(
                color: PdfColors.red50,
                borderRadius: pw.BorderRadius.circular(6),
                border: pw.Border.all(color: PdfColors.red200, width: 1),
              ),
              child: pw.Column(
                children: [
                  pw.Text(
                    'Collection Rate',
                    style: pw.TextStyle(
                      fontSize: 14,
                      fontWeight: pw.FontWeight.bold,
                      color: PdfColors.red900,
                    ),
                  ),
                  pw.SizedBox(height: 4),
                  pw.Text(
                    '${(totalPaid / totalDebt * 100).toStringAsFixed(1)}%',
                    style: pw.TextStyle(
                      fontSize: 24,
                      fontWeight: pw.FontWeight.bold,
                      color: PdfColors.red700,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  static pw.Widget _buildSummaryCard(
      String label,
      String value,
      PdfColor color,
      ) {
    return pw.Column(
      children: [
        pw.Text(
          label,
          style: const pw.TextStyle(
            fontSize: 10,
            color: PdfColors.grey600,
          ),
        ),
        pw.SizedBox(height: 4),
        pw.Text(
          value,
          style: pw.TextStyle(
            fontSize: 16,
            fontWeight: pw.FontWeight.bold,
            color: color,
          ),
        ),
      ],
    );
  }

  static pw.Widget _buildSalesTable(
      List<SaleEntry> sales,
      NumberFormat formatter,
      ) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(
          'Sales Details',
          style: pw.TextStyle(
            fontSize: 14,
            fontWeight: pw.FontWeight.bold,
          ),
        ),
        pw.SizedBox(height: 12),
        pw.Table(
          border: pw.TableBorder.all(
            color: PdfColors.grey300,
            width: 0.5,
          ),
          columnWidths: {
            0: const pw.FlexColumnWidth(3),
            1: const pw.FlexColumnWidth(1),
            2: const pw.FlexColumnWidth(1.5),
            3: const pw.FlexColumnWidth(2),
            4: const pw.FlexColumnWidth(2),
          },
          children: [
            // Header Row
            pw.TableRow(
              decoration: const pw.BoxDecoration(
                color: PdfColors.grey200,
              ),
              children: [
                _buildTableHeader('Product'),
                _buildTableHeader('Qty'),
                _buildTableHeader('Unit'),
                _buildTableHeader('Price'),
                _buildTableHeader('Total'),
              ],
            ),
            // Data Rows
            ...sales.asMap().entries.map((entry) {
              final index = entry.key;
              final sale = entry.value;
              final isEven = index % 2 == 0;
              return pw.TableRow(
                decoration: pw.BoxDecoration(
                  color: isEven ? PdfColors.white : PdfColors.grey50,
                ),
                children: [
                  _buildTableCell(sale.product.name, isLeft: true),
                  _buildTableCell(sale.quantity.toString()),
                  _buildTableCell(sale.primaryUnit),
                  _buildTableCell('KES ${formatter.format(sale.pricePerItem)}'),
                  _buildTableCell(
                    'KES ${formatter.format(sale.total)}',
                    isBold: true,
                    color: PdfColors.green700,
                  ),
                ],
              );
            }).toList(),
          ],
        ),
      ],
    );
  }

  /*static pw.Widget _buildStockTable(
      List<Product> products,
      NumberFormat formatter,
      ) {
    // Sort products by stock level (lowest first)
    final sortedProducts = [...products]..sort((a, b) => a.currentStock.compareTo(b.currentStock));

    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(
          'Stock Details',
          style: pw.TextStyle(
            fontSize: 14,
            fontWeight: pw.FontWeight.bold,
          ),
        ),
        pw.SizedBox(height: 12),
        pw.Table(
          border: pw.TableBorder.all(
            color: PdfColors.grey300,
            width: 0.5,
          ),
          columnWidths: {
            0: const pw.FlexColumnWidth(3),
            1: const pw.FlexColumnWidth(1.5),
            2: const pw.FlexColumnWidth(1.5),
            3: const pw.FlexColumnWidth(1.5),
            4: const pw.FlexColumnWidth(2),
          },
          children: [
            // Header Row
            pw.TableRow(
              decoration: const pw.BoxDecoration(
                color: PdfColors.grey200,
              ),
              children: [
                _buildTableHeader('Product'),
                _buildTableHeader('In Stock'),
                _buildTableHeader('Reorder Level'),
                _buildTableHeader('Status'),
                _buildTableHeader('Value (KES)'),
              ],
            ),
            // Data Rows
            ...sortedProducts.asMap().entries.map((entry) {
              final index = entry.key;
              final product = entry.value;
              final isEven = index % 2 == 0;
              final isLowStock = product.currentStock <= product.reorderLevel;

              return pw.TableRow(
                decoration: pw.BoxDecoration(
                  color: isEven ? PdfColors.white : PdfColors.grey50,
                ),
                children: [
                  _buildTableCell(product.name, isLeft: true),
                  _buildTableCell(product.currentStock.toString()),
                  _buildTableCell(product.reorderLevel.toString()),
                  _buildTableCell(
                    isLowStock ? 'LOW STOCK' : 'OK',
                    color: isLowStock ? PdfColors.red700 : PdfColors.green700,
                    isBold: isLowStock,
                  ),
                  _buildTableCell(
                    formatter.format(product.currentStock * product.wholesalePrice),
                    isBold: true,
                  ),
                ],
              );
            }).toList(),
          ],
        ),
      ],
    );
  }*/

  static pw.Widget _buildDebtorsTable(
      List<LoanEntry> loans,
      NumberFormat formatter,
      ) {
    // Sort by balance descending (largest debts first)
    final sortedLoans = [...loans]..sort((a, b) => b.balance.compareTo(a.balance));

    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(
          'Debtors Summary',
          style: pw.TextStyle(
            fontSize: 14,
            fontWeight: pw.FontWeight.bold,
          ),
        ),
        pw.SizedBox(height: 12),
        pw.Table(
          border: pw.TableBorder.all(
            color: PdfColors.grey300,
            width: 0.5,
          ),
          columnWidths: {
            0: const pw.FlexColumnWidth(2.5),
            1: const pw.FlexColumnWidth(2),
            2: const pw.FlexColumnWidth(1.5),
            3: const pw.FlexColumnWidth(1.5),
            4: const pw.FlexColumnWidth(1.5),
          },
          children: [
            // Header Row
            pw.TableRow(
              decoration: const pw.BoxDecoration(
                color: PdfColors.grey200,
              ),
              children: [
                _buildTableHeader('Customer'),
                _buildTableHeader('Phone'),
                _buildTableHeader('Total Debt'),
                _buildTableHeader('Paid'),
                _buildTableHeader('Outstanding'),
              ],
            ),
            // Data Rows
            ...sortedLoans.asMap().entries.map((entry) {
              final index = entry.key;
              final loan = entry.value;
              final isEven = index % 2 == 0;

              return pw.TableRow(
                decoration: pw.BoxDecoration(
                  color: isEven ? PdfColors.white : PdfColors.grey50,
                ),
                children: [
                  _buildTableCell(loan.name, isLeft: true),
                  _buildTableCell(loan.phone),
                  _buildTableCell(
                    'KES ${formatter.format(loan.totalAmount)}',
                    isBold: true,
                  ),
                  _buildTableCell(
                    'KES ${formatter.format(loan.amountPaid)}',
                    color: PdfColors.green700,
                  ),
                  _buildTableCell(
                    'KES ${formatter.format(loan.balance)}',
                    color: loan.isPaid ? PdfColors.grey600 : PdfColors.red700,
                    isBold: !loan.isPaid,
                  ),
                ],
              );
            }).toList(),
            // Total Row
            pw.TableRow(
              decoration: const pw.BoxDecoration(
                color: PdfColors.blue50,
              ),
              children: [
                _buildTableCell('TOTAL', isLeft: true, isBold: true),
                _buildTableCell(''),
                _buildTableCell(
                  'KES ${formatter.format(sortedLoans.fold<double>(0, (sum, l) => sum + l.totalAmount))}',
                  isBold: true,
                  color: PdfColors.blue900,
                ),
                _buildTableCell(
                  'KES ${formatter.format(sortedLoans.fold<double>(0, (sum, l) => sum + l.amountPaid))}',
                  isBold: true,
                  color: PdfColors.green900,
                ),
                _buildTableCell(
                  'KES ${formatter.format(sortedLoans.fold<double>(0, (sum, l) => sum + l.balance))}',
                  isBold: true,
                  color: PdfColors.red900,
                ),
              ],
            ),
          ],
        ),
      ],
    );
  }

  static List<pw.Widget> _buildDebtorDetailsSections(
      Map<LoanEntry, List<SaleEntry>> debtData,
      NumberFormat formatter,
      ) {
    final sections = <pw.Widget>[];
    final sortedDebtors = debtData.entries.toList()
      ..sort((a, b) => b.key.balance.compareTo(a.key.balance));

    for (final entry in sortedDebtors) {
      final loan = entry.key;
      final sales = entry.value;
      final payments = loan.payments;

      sections.add(
        pw.Container(
          padding: const pw.EdgeInsets.all(16),
          decoration: pw.BoxDecoration(
            border: pw.Border.all(color: PdfColors.grey300, width: 1),
            borderRadius: pw.BorderRadius.circular(8),
          ),
          child: pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              // Debtor Header
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text(
                        loan.name,
                        style: pw.TextStyle(
                          fontSize: 16,
                          fontWeight: pw.FontWeight.bold,
                        ),
                      ),
                      pw.SizedBox(height: 4),
                      pw.Text(
                        loan.phone,
                        style: const pw.TextStyle(
                          fontSize: 12,
                          color: PdfColors.grey600,
                        ),
                      ),
                    ],
                  ),
                  pw.Container(
                    padding: const pw.EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: pw.BoxDecoration(
                      color: loan.isPaid ? PdfColors.green50 : PdfColors.red50,
                      borderRadius: pw.BorderRadius.circular(4),
                      border: pw.Border.all(
                        color: loan.isPaid ? PdfColors.green200 : PdfColors.red200,
                        width: 1,
                      ),
                    ),
                    child: pw.Text(
                      loan.isPaid ? 'PAID' : 'OUTSTANDING',
                      style: pw.TextStyle(
                        fontSize: 12,
                        fontWeight: pw.FontWeight.bold,
                        color: loan.isPaid ? PdfColors.green700 : PdfColors.red700,
                      ),
                    ),
                  ),
                ],
              ),
              pw.SizedBox(height: 16),
              pw.Divider(),
              pw.SizedBox(height: 16),

              // Debt Summary
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text('Total Debt:', style:  pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                  pw.Text('KES ${formatter.format(loan.totalAmount)}', style:  pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                ],
              ),
              pw.SizedBox(height: 4),
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text('Amount Paid:', style: pw.TextStyle(color: PdfColors.green700)),
                  pw.Text('KES ${formatter.format(loan.amountPaid)}', style: pw.TextStyle(color: PdfColors.green700, fontWeight: pw.FontWeight.bold)),
                ],
              ),
              pw.SizedBox(height: 4),
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text('Outstanding Balance:', style: pw.TextStyle(color: PdfColors.red700, fontWeight: pw.FontWeight.bold)),
                  pw.Text('KES ${formatter.format(loan.balance)}', style: pw.TextStyle(color: PdfColors.red700, fontWeight: pw.FontWeight.bold, fontSize: 16)),
                ],
              ),
              pw.SizedBox(height: 16),

              // Sales Table (if any)
              if (sales.isNotEmpty) ...[
                pw.Text(
                  'Purchases (${sales.length})',
                  style: pw.TextStyle(
                    fontSize: 14,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
                pw.SizedBox(height: 12),
                pw.Table(
                  border: pw.TableBorder.all(
                    color: PdfColors.grey300,
                    width: 0.5,
                  ),
                  columnWidths: {
                    0: const pw.FlexColumnWidth(3),
                    1: const pw.FlexColumnWidth(1),
                    2: const pw.FlexColumnWidth(2),
                  },
                  children: [
                    pw.TableRow(
                      decoration: const pw.BoxDecoration(color: PdfColors.grey200),
                      children: [
                        _buildTableHeader('Product'),
                        _buildTableHeader('Qty'),
                        _buildTableHeader('Amount'),
                      ],
                    ),
                    ...sales.asMap().entries.map((saleEntry) {
                      final sale = saleEntry.value;
                      return pw.TableRow(
                        children: [
                          _buildTableCell(sale.product.name, fontSize: 9),
                          _buildTableCell(sale.quantity.toString(), fontSize: 9),
                          _buildTableCell('KES ${formatter.format(sale.total)}', fontSize: 9),
                        ],
                      );
                    }).toList(),
                    pw.TableRow(
                      decoration: const pw.BoxDecoration(color: PdfColors.blue50),
                      children: [
                        _buildTableCell('TOTAL', isBold: true, fontSize: 10),
                        _buildTableCell(''),
                        _buildTableCell(
                          'KES ${formatter.format(sales.fold<double>(0, (sum, s) => sum + s.total))}',
                          isBold: true,
                          color: PdfColors.blue900,
                          fontSize: 10,
                        ),
                      ],
                    ),
                  ],
                ),
                pw.SizedBox(height: 16),
              ],

              // Payments Table (if any)
              if (payments.isNotEmpty) ...[
                pw.Text(
                  'Payments (${payments.length})',
                  style: pw.TextStyle(
                    fontSize: 14,
                    fontWeight: pw.FontWeight.bold,
                    color: PdfColors.green900,
                  ),
                ),
                pw.SizedBox(height: 12),
                pw.Table(
                  border: pw.TableBorder.all(
                    color: PdfColors.grey300,
                    width: 0.5,
                  ),
                  columnWidths: {
                    0: const pw.FlexColumnWidth(2),
                    1: const pw.FlexColumnWidth(2),
                    2: const pw.FlexColumnWidth(2),
                  },
                  children: [
                    pw.TableRow(
                      decoration: const pw.BoxDecoration(color: PdfColors.grey200),
                      children: [
                        _buildTableHeader('Date'),
                        _buildTableHeader('Amount'),
                        _buildTableHeader('Notes'),
                      ],
                    ),
                    ...payments.map((payment) {
                      final paymentDate = DateFormat('dd/MM HH:mm').format(payment.date);
                      return pw.TableRow(
                        children: [
                          _buildTableCell(paymentDate, fontSize: 9),
                          _buildTableCell('KES ${formatter.format(payment.amount)}', color: PdfColors.green700, fontSize: 9),
                          _buildTableCell(payment.notes ?? '-', fontSize: 9),
                        ],
                      );
                    }).toList(),
                    pw.TableRow(
                      decoration: const pw.BoxDecoration(color: PdfColors.green50),
                      children: [
                        _buildTableCell('TOTAL PAID', isBold: true, fontSize: 10),
                        _buildTableCell(
                          'KES ${formatter.format(payments.fold<double>(0, (sum, p) => sum + p.amount))}',
                          isBold: true,
                          color: PdfColors.green900,
                          fontSize: 10,
                        ),
                        _buildTableCell(''),
                      ],
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      );

      // Add spacing between debtors (except last one)
      if (entry != sortedDebtors.last) {
        sections.add( pw.SizedBox(height: 24));
      }
    }

    return sections;
  }

  static pw.Widget _buildTableHeader(String text) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      child: pw.Text(
        text,
        style: pw.TextStyle(
          fontSize: 11,
          fontWeight: pw.FontWeight.bold,
          color: PdfColors.grey800,
        ),
      ),
    );
  }

  static pw.Widget _buildTableCell(
      String text, {
        bool isLeft = false,
        bool isBold = false,
        PdfColor? color,
        double fontSize = 10,
      }) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      child: pw.Text(
        text,
        style: pw.TextStyle(
          fontSize: fontSize,
          fontWeight: isBold ? pw.FontWeight.bold : pw.FontWeight.normal,
          color: color ?? PdfColors.grey800,
        ),
        textAlign: isLeft ? pw.TextAlign.left : pw.TextAlign.center,
      ),
    );
  }

  static pw.Widget _buildTotalSection(double total, NumberFormat formatter) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(16),
      decoration: pw.BoxDecoration(
        color: PdfColors.green50,
        borderRadius: pw.BorderRadius.circular(8),
        border: pw.Border.all(color: PdfColors.green200, width: 1.5),
      ),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text(
            'Grand Total',
            style: pw.TextStyle(
              fontSize: 18,
              fontWeight: pw.FontWeight.bold,
              color: PdfColors.green900,
            ),
          ),
          pw.Text(
            'KES ${formatter.format(total)}',
            style: pw.TextStyle(
              fontSize: 24,
              fontWeight: pw.FontWeight.bold,
              color: PdfColors.green700,
            ),
          ),
        ],
      ),
    );
  }

  static pw.Widget _buildFooter(pw.Context context) {
    return pw.Container(
      alignment: pw.Alignment.centerRight,
      margin: const pw.EdgeInsets.only(top: 16),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.end,
        children: [
          pw.Text(
            'Page ${context.pageNumber} of ${context.pagesCount}',
            style: const pw.TextStyle(
              fontSize: 10,
              color: PdfColors.grey600,
            ),
          ),
          pw.SizedBox(height: 4),
          pw.Text(
            'Generated by 4Retails © ${DateTime.now().year}',
            style: const pw.TextStyle(
              fontSize: 8,
              color: PdfColors.grey500,
            ),
          ),
        ],
      ),
    );
  }
}