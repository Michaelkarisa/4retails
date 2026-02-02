import 'package:fl_chart/fl_chart.dart';
import '../models/sale_entry.dart';
import '../models/stock_entry.dart';

class AnalyticsService {
  // Generate sales chart data for the last 7 days
  static List<FlSpot> generateSalesChartData(List<SaleEntry> sales) {
    final now = DateTime.now();
    final sevenDaysAgo = now.subtract(const Duration(days: 6));

    // Group sales by day
    final Map<int, double> dailySales = {};

    for (int i = 0; i < 7; i++) {
      dailySales[i] = 0.0;
    }

    for (final sale in sales) {
      final daysDiff = sale.date.difference(sevenDaysAgo).inDays;
      if (daysDiff >= 0 && daysDiff < 7) {
        dailySales[daysDiff] = (dailySales[daysDiff] ?? 0) + sale.total;
      }
    }

    return dailySales.entries
        .map((entry) => FlSpot(entry.key.toDouble(), entry.value / 1000))
        .toList();
  }

  // Generate stock chart data for the last 7 days
  static List<FlSpot> generateStockChartData(List<StockEntry> stocks) {
    final now = DateTime.now();
    final sevenDaysAgo = now.subtract(const Duration(days: 6));

    // Group stock by day
    final Map<int, double> dailyStock = {};

    for (int i = 0; i < 7; i++) {
      dailyStock[i] = 0.0;
    }

    for (final stock in stocks) {
      final daysDiff = stock.entryDate.difference(sevenDaysAgo).inDays;
      if (daysDiff >= 0 && daysDiff < 7) {
        dailyStock[daysDiff] = (dailyStock[daysDiff] ?? 0) + stock.primaryUnitQuantity.toDouble();
      }
    }

    return dailyStock.entries
        .map((entry) => FlSpot(entry.key.toDouble(), entry.value))
        .toList();
  }

  // Get sales statistics
  static Map<String, dynamic> getSalesStatistics(List<SaleEntry> sales) {
    if (sales.isEmpty) {
      return {
        'totalRevenue': 0.0,
        'totalTransactions': 0,
        'averageTransaction': 0.0,
        'itemsSold': 0,
        'topProduct': null,
      };
    }

    final totalRevenue = sales.fold<double>(0.0, (sum, sale) => sum + sale.total);
    final itemsSold = sales.fold<int>(0, (sum, sale) => sum + sale.quantity);

    // Find top product
    final productSales = <String, double>{};
    for (final sale in sales) {
      final key = sale.product.name;
      productSales[key] = (productSales[key] ?? 0) + sale.total;
    }

    String? topProduct;
    double maxSales = 0;
    productSales.forEach((product, total) {
      if (total > maxSales) {
        maxSales = total;
        topProduct = product;
      }
    });

    return {
      'totalRevenue': totalRevenue,
      'totalTransactions': sales.length,
      'averageTransaction': totalRevenue / sales.length,
      'itemsSold': itemsSold,
      'topProduct': topProduct,
      'topProductRevenue': maxSales,
    };
  }

  // Get stock statistics
  static Map<String, dynamic> getStockStatistics(List<StockEntry> stocks) {
    if (stocks.isEmpty) {
      return {
        'totalStockValue': 0.0,
        'projectedProfit': 0.0,
        'averageProfit': 0.0,
        'totalItems': 0,
        'lowProfitItems': 0,
      };
    }

    final totalStockValue = stocks.fold<double>(
      0.0,
          (sum, stock) => sum + (stock.buyingPrice * stock.primaryUnitQuantity),
    );

    final projectedProfit = stocks.fold<double>(
      0.0,
          (sum, stock) => sum + stock.projectedProfit,
    );

    final totalItems = stocks.fold<int>(0, (sum, stock) => sum + stock.primaryUnitQuantity);

    // Count items with low profit margin (less than 10%)
    final lowProfitItems = stocks.where((stock) {
      final margin = stock.buyingPrice > 0
          ? ((stock.sellingPrice - stock.buyingPrice) / stock.buyingPrice) * 100
          : 0;
      return margin < 10;
    }).length;

    return {
      'totalStockValue': totalStockValue,
      'projectedProfit': projectedProfit,
      'averageProfit': stocks.isNotEmpty ? projectedProfit / stocks.length : 0.0,
      'totalItems': totalItems,
      'lowProfitItems': lowProfitItems,
    };
  }

  // Compare projected vs actual profit
  static Map<String, dynamic> compareProjectedVsActual(
      List<StockEntry> stocks,
      List<SaleEntry> sales,
      ) {
    // Calculate projected profit from all stocks
    final projectedProfit = stocks.fold<double>(
      0.0,
          (sum, stock) => sum + stock.projectedProfit,
    );

    // Calculate actual profit (need to match sales with original stock)
    double actualProfit = 0.0;
    double profitGap = 0.0;
    int itemsBelowProjected = 0;

    // Map sales to stocks by product
    final stocksByProduct = <String, StockEntry>{};
    for (final stock in stocks) {
      stocksByProduct[stock.product.id] = stock;
    }

    for (final sale in sales) {
      final matchingStock = stocksByProduct[sale.product.id];
      if (matchingStock != null) {
        final profitPerItem = sale.pricePerItem - matchingStock.buyingPrice;
        final projectedProfitPerItem = matchingStock.sellingPrice - matchingStock.buyingPrice;

        actualProfit += profitPerItem * sale.quantity;

        if (sale.pricePerItem < matchingStock.sellingPrice) {
          itemsBelowProjected++;
          profitGap += (projectedProfitPerItem - profitPerItem) * sale.quantity;
        }
      }
    }

    return {
      'projectedProfit': projectedProfit,
      'actualProfit': actualProfit,
      'profitGap': profitGap,
      'itemsBelowProjected': itemsBelowProjected,
      'profitRealization': projectedProfit > 0
          ? (actualProfit / projectedProfit * 100)
          : 0.0,
    };
  }

  // Get product performance ranking
  static List<Map<String, dynamic>> getProductPerformance(
      List<SaleEntry> sales,
      List<StockEntry> stocks,
      ) {
    final productData = <String, Map<String, dynamic>>{};

    // Aggregate sales data
    for (final sale in sales) {
      final productId = sale.product.id;
      if (!productData.containsKey(productId)) {
        productData[productId] = {
          'name': sale.product.name,
          'revenue': 0.0,
          'quantitySold': 0,
          'transactions': 0,
        };
      }
      productData[productId]!['revenue'] =
          (productData[productId]!['revenue'] as double) + sale.total;
      productData[productId]!['quantitySold'] =
          (productData[productId]!['quantitySold'] as int) + sale.quantity;
      productData[productId]!['transactions'] =
          (productData[productId]!['transactions'] as int) + 1;
    }

    // Add stock data
    for (final stock in stocks) {
      final productId = stock.product.id;
      if (productData.containsKey(productId)) {
        productData[productId]!['projectedProfit'] = stock.projectedProfit;
        productData[productId]!['stockValue'] =
            stock.buyingPrice * stock.primaryUnitQuantity;
      }
    }

    // Convert to list and sort by revenue
    final performanceList = productData.values.toList();
    performanceList.sort((a, b) =>
        (b['revenue'] as double).compareTo(a['revenue'] as double));

    return performanceList;
  }

  // Get date labels for charts
  static List<String> getDateLabels() {
    final now = DateTime.now();
    final labels = <String>[];

    for (int i = 6; i >= 0; i--) {
      final date = now.subtract(Duration(days: i));
      labels.add('${date.day}/${date.month}');
    }

    return labels;
  }

  // Get weekly comparison
  static Map<String, dynamic> getWeeklyComparison(
      List<SaleEntry> currentWeekSales,
      List<SaleEntry> previousWeekSales,
      ) {
    final currentTotal = currentWeekSales.fold<double>(
      0.0,
          (sum, sale) => sum + sale.total,
    );

    final previousTotal = previousWeekSales.fold<double>(
      0.0,
          (sum, sale) => sum + sale.total,
    );

    final difference = currentTotal - previousTotal;
    final percentageChange = previousTotal > 0
        ? (difference / previousTotal) * 100
        : 0.0;

    return {
      'currentTotal': currentTotal,
      'previousTotal': previousTotal,
      'difference': difference,
      'percentageChange': percentageChange,
      'isImprovement': difference >= 0,
    };
  }

  // Analyze stock turnover
  static Map<String, dynamic> analyzeStockTurnover(
      List<StockEntry> stocks,
      List<SaleEntry> sales,
      ) {
    final stockByProduct = <String, int>{};
    final salesByProduct = <String, int>{};

    // Count stock by product
    for (final stock in stocks) {
      final productId = stock.product.id;
      stockByProduct[productId] =
          (stockByProduct[productId] ?? 0) + stock.primaryUnitQuantity;
    }

    // Count sales by product
    for (final sale in sales) {
      final productId = sale.product.id;
      salesByProduct[productId] =
          (salesByProduct[productId] ?? 0) + sale.quantity;
    }

    // Calculate turnover rate
    final turnoverData = <String, Map<String, dynamic>>{};
    stockByProduct.forEach((productId, stockQty) {
      final salesQty = salesByProduct[productId] ?? 0;
      final turnoverRate = stockQty > 0 ? (salesQty / stockQty) * 100 : 0.0;

      // Find product name
      String? productName;
      for (final stock in stocks) {
        if (stock.product.id == productId) {
          productName = stock.product.name;
          break;
        }
      }

      turnoverData[productId] = {
        'name': productName,
        'stock': stockQty,
        'sold': salesQty,
        'turnoverRate': turnoverRate,
        'status': turnoverRate > 80
            ? 'High'
            : turnoverRate > 50
            ? 'Medium'
            : 'Low',
      };
    });

    return {
      'products': turnoverData.values.toList(),
      'averageTurnover': turnoverData.values.isEmpty
          ? 0.0
          : turnoverData.values.fold<double>(
        0.0,
            (sum, data) => sum + (data['turnoverRate'] as double),
      ) / turnoverData.values.length,
    };
  }

  // Get insights and recommendations
  static List<Map<String, dynamic>> getInsightsAndRecommendations(
      List<StockEntry> stocks,
      List<SaleEntry> sales,
      ) {
    final insights = <Map<String, dynamic>>[];

    final profitComparison = compareProjectedVsActual(stocks, sales);
    final stockStats = getStockStatistics(stocks);
    final salesStats = getSalesStatistics(sales);

    // Profit gap insight
    if (profitComparison['profitGap'] > 0) {
      insights.add({
        'type': 'warning',
        'title': 'Profit Gap Detected',
        'message':
        'You\'re losing KES ${profitComparison['profitGap'].toStringAsFixed(2)} '
            'by selling ${profitComparison['itemsBelowProjected']} items below projected price.',
        'action': 'Increase selling price',
      });
    }

    // Low profit items
    if (stockStats['lowProfitItems'] > 0) {
      insights.add({
        'type': 'info',
        'title': 'Low Profit Margins',
        'message':
        '${stockStats['lowProfitItems']} items have profit margins below 10%.',
        'action': 'Review pricing strategy',
      });
    }

    // Top performing product
    if (salesStats['topProduct'] != null) {
      insights.add({
        'type': 'success',
        'title': 'Top Performer',
        'message':
        '${salesStats['topProduct']} generated KES ${salesStats['topProductRevenue'].toStringAsFixed(2)}.',
        'action': 'Consider restocking',
      });
    }

    return insights;
  }
}