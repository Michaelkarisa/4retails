import 'package:flutter/material.dart';
import '../../models/loan_entry.dart';
import '../../models/sale_entry.dart';
import '../../service/data_service.dart';
import 'lending_card.dart';

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

  void _exportPdf() {
    // TODO: Implement PDF export for debts
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('PDF export coming soon'),
        backgroundColor: Colors.blue,
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

    for (final entry in allDebts.entries) {
      final loan = entry.key;
      totalDebt += loan.totalAmount;
      totalPaid += loan.amountPaid;
      totalBalance += loan.balance;
    }

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