import 'package:flutter/material.dart';
import 'tabs/todays_sales_tab.dart';
import 'tabs/current_stock_tab.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  DateTime _selectedDate = DateTime.now();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('4Retails', style: TextStyle(fontWeight: FontWeight.bold)),
        elevation: 0,
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: "Today's Sales"),
            Tab(text: 'Current Stock'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          TodaysSalesTab(selectedDate: _selectedDate, onDateChanged: _updateDate),
          CurrentStockTab(selectedDate: _selectedDate, onDateChanged: _updateDate),
        ],
      ),
    );
  }

  void _updateDate(DateTime date) {
    setState(() {
      _selectedDate = date;
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }
}