import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:retails/models/loan_entry.dart';
import 'package:retails/models/sale_entry.dart';
import 'package:retails/service/data_service.dart';
import 'package:uuid/uuid.dart';
import '../../utils/sample_data.dart';

class LoanEntryCard extends StatefulWidget {
  final LoanEntry loanEntry;
  final List<SaleEntry> sales;

  const LoanEntryCard({
    Key? key,
    required this.loanEntry,
    required this.sales,
  }) : super(key: key);

  @override
  State<LoanEntryCard> createState() => _LoanEntryCardState();
}

class _LoanEntryCardState extends State<LoanEntryCard> {
  bool _isExpanded = false;
  final _paymentController = TextEditingController();

  @override
  void initState(){
    super.initState();
   // handlePaid();
  }

  void handlePaid()async{
    final totalSales = widget.sales.fold<double>(0.0, (sum, sale) => sum + sale.total);
    final percentagePaid = (widget.loanEntry.amountPaid/totalSales)*100;

    if(percentagePaid>=100) {
      final updatedLoan = widget.loanEntry.copyWith(
        amountPaid: widget.loanEntry.totalAmount,
        payments: widget.loanEntry.payments,
        isPaid: true,
        paidDate: DateTime.now(),
      );
      await DataService().updateLoan(updatedLoan);
    }
  }
  @override
  void dispose() {
    _paymentController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final dateStr = formatDateForDisplay(widget.loanEntry.date);
    final totalSales = widget.sales.fold<double>(0.0, (sum, sale) => sum + sale.total);
    final balance = totalSales-widget.loanEntry.amountPaid;
    final percentagePaid = (widget.loanEntry.amountPaid/totalSales)*100;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: widget.loanEntry.isPaid ? Colors.green[200]! : Colors.orange[200]!,
          width: 1.5,
        ),
      ),
      child: Column(
        children: [
          InkWell(
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
                            Row(
                              children: [
                                Flexible(
                                  child: Text(
                                    widget.loanEntry.name,
                                    style: const TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                if (widget.loanEntry.isPaid)
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 4,
                                    ),
                                    decoration: BoxDecoration(
                                      color: Colors.green[100],
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(
                                          Icons.check_circle,
                                          size: 14,
                                          color: Colors.green[700],
                                        ),
                                        const SizedBox(width: 4),
                                        Text(
                                          'PAID',
                                          style: TextStyle(
                                            fontSize: 11,
                                            fontWeight: FontWeight.bold,
                                            color: Colors.green[700],
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Text(
                              widget.loanEntry.phone,
                              style: TextStyle(
                                fontSize: 13,
                                color: Colors.grey[600],
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              dateStr,
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey[500],
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
                  const SizedBox(height: 12),

                  // Progress Bar
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Payment Progress',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[600],
                            ),
                          ),
                          Text(
                            '${percentagePaid.toStringAsFixed(0)}%',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: widget.loanEntry.isPaid
                                  ? Colors.green[700]
                                  : Colors.orange[700],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: LinearProgressIndicator(
                          value: percentagePaid / 100,
                          minHeight: 8,
                          backgroundColor: Colors.grey[200],
                          valueColor: AlwaysStoppedAnimation<Color>(
                            widget.loanEntry.isPaid ? Colors.green : Colors.orange,
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 12),

                  // Amount Summary
                  Row(
                    children: [
                      Expanded(
                        child: _buildAmountChip(
                          label: 'Total',
                          amount: totalSales,
                          color: Colors.blue,
                          icon: Icons.shopping_cart,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _buildAmountChip(
                          label: 'Paid',
                          amount: widget.loanEntry.amountPaid,
                          color: Colors.green,
                          icon: Icons.check_circle,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _buildAmountChip(
                          label: 'Balance',
                          amount: balance,
                          color: balance > 0 ? Colors.red : Colors.grey,
                          icon: Icons.account_balance_wallet,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),

          if (_isExpanded) ...[
            const Divider(height: 1),
            _buildExpandedContent(),
          ],

          if (!widget.loanEntry.isPaid) _buildActionButtons(),
        ],
      ),
    );
  }

  Widget _buildAmountChip({
    required String label,
    required double amount,
    required Color color,
    required IconData icon,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 10,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 2),
          Text(
            'KES ${amount.toStringAsFixed(0)}',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildExpandedContent() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Sales List
          const Text(
            'Items on Credit',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          ...widget.sales.map((sale) => _buildSaleItem(sale)),

          // Payment History
          if (widget.loanEntry.payments.isNotEmpty) ...[
            const SizedBox(height: 20),
            const Text(
              'Payment History',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            ...widget.loanEntry.payments.map((payment) => _buildPaymentItem(payment)),
          ],
        ],
      ),
    );
  }

  Widget _buildSaleItem(SaleEntry sale) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.blue[50],
              borderRadius: BorderRadius.circular(6),
            ),
            child: Icon(
              Icons.shopping_bag_outlined,
              size: 20,
              color: Colors.blue[700],
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  sale.product.name,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '${sale.quantity} ${sale.primaryUnit}${sale.quantity > 1 ? 's' : ''} @ KES ${sale.pricePerItem.toStringAsFixed(2)}',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
          Text(
            'KES ${sale.total.toStringAsFixed(2)}',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 14,
              color: Colors.blue[700],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentItem(Payment payment) {
    final dateStr = DateFormat('dd MMM yyyy, hh:mm a').format(payment.date);

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.green[50],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.green[200]!),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.green[100],
              borderRadius: BorderRadius.circular(6),
            ),
            child: Icon(
              Icons.payment,
              size: 20,
              color: Colors.green[700],
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Payment Received',
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  dateStr,
                  style: TextStyle(
                    fontSize: 11,
                    color: Colors.grey[600],
                  ),
                ),
                if (payment.notes != null && payment.notes!.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    payment.notes!,
                    style: TextStyle(
                      fontSize: 11,
                      color: Colors.grey[600],
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ],
              ],
            ),
          ),
          Text(
            'KES ${payment.amount.toStringAsFixed(2)}',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 14,
              color: Colors.green[700],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: const BorderRadius.vertical(bottom: Radius.circular(12)),
      ),
      padding: const EdgeInsets.all(12),
      child: Row(
        children: [
          Expanded(
            child: OutlinedButton.icon(
              onPressed: _showPaymentDialog,
              icon: const Icon(Icons.add_card, size: 18),
              label: const Text('Add Payment'),
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.green[700],
                side: BorderSide(color: Colors.green[300]!),
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: ElevatedButton.icon(
              onPressed: _markAsPaid,
              icon: const Icon(Icons.check_circle, size: 18),
              label: const Text('Mark as Paid'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showPaymentDialog() {
    _paymentController.clear();
    String? notes;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Icon(Icons.payment, color: Colors.green[700]),
            const SizedBox(width: 12),
            const Text('Record Payment'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Balance: KES ${widget.loanEntry.balance.toStringAsFixed(2)}',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[600],
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _paymentController,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: InputDecoration(
                labelText: 'Payment Amount',
                prefixText: 'KES ',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                filled: true,
                fillColor: Colors.grey[50],
              ),
              autofocus: true,
            ),
            const SizedBox(height: 12),
            TextField(
              decoration: InputDecoration(
                labelText: 'Notes (Optional)',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                filled: true,
                fillColor: Colors.grey[50],
              ),
              maxLines: 2,
              onChanged: (value) => notes = value,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              final amount = double.tryParse(_paymentController.text);
              if (amount != null && amount > 0) {
                _recordPayment(amount, notes);
                Navigator.pop(context);
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Please enter a valid amount'),
                    backgroundColor: Colors.red,
                  ),
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
              foregroundColor: Colors.white,
            ),
            child: const Text('Record'),
          ),
        ],
      ),
    );
  }

  Future<void> _recordPayment(double amount, String? notes) async {
    final newPayment = Payment(
      id: const Uuid().v4(),
      amount: amount,
      date: DateTime.now(),
      notes: notes,
    );

    final updatedPayments = [...widget.loanEntry.payments, newPayment];
    final newAmountPaid = widget.loanEntry.amountPaid + amount;
    final isPaid = newAmountPaid >= widget.sales.fold<double>(0.0, (sum, sale) => sum + sale.total);

    final updatedLoan = widget.loanEntry.copyWith(
      amountPaid: newAmountPaid,
      payments: updatedPayments,
      isPaid: isPaid,
      paidDate: isPaid ? DateTime.now() : null,
    );

    await DataService().updateLoan(updatedLoan);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Payment of KES ${amount.toStringAsFixed(2)} recorded'),
          backgroundColor: Colors.green,
          behavior: SnackBarBehavior.floating,
        ),
      );

      // Trigger parent refresh
      setState(() {});
    }
  }

  Future<void> _markAsPaid() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Mark as Paid'),
        content: Text(
          'Mark this debt of KES ${widget.loanEntry.totalAmount.toStringAsFixed(2)} as fully paid?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
              foregroundColor: Colors.white,
            ),
            child: const Text('Confirm'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      final balance = widget.loanEntry.balance;
      Payment? finalPayment;

      if (balance > 0) {
        finalPayment = Payment(
          id: const Uuid().v4(),
          amount: balance,
          date: DateTime.now(),
          notes: 'Final payment - marked as paid',
        );
      }

      final updatedPayments = finalPayment != null
          ? [...widget.loanEntry.payments, finalPayment]
          : widget.loanEntry.payments;

      final updatedLoan = widget.loanEntry.copyWith(
        amountPaid: widget.loanEntry.totalAmount,
        payments: updatedPayments,
        isPaid: true,
        paidDate: DateTime.now(),
      );

      await DataService().updateLoan(updatedLoan);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Debt marked as paid'),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
          ),
        );

        setState(() {});
      }
    }
  }
}