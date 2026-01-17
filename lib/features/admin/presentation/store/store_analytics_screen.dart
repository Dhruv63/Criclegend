import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../data/admin_store_repository.dart';

final storeAnalyticsProvider = FutureProvider.autoDispose<Map<String, dynamic>>((ref) async {
  return ref.watch(adminStoreRepositoryProvider).getStoreAnalyticsSummary();
});

class StoreAnalyticsScreen extends ConsumerWidget {
  const StoreAnalyticsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final analyticsAsync = ref.watch(storeAnalyticsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text("Store Analytics"),
        backgroundColor: Colors.white,
        elevation: 0,
        foregroundColor: Colors.black,
      ),
      backgroundColor: Colors.grey[50],
      body: RefreshIndicator(
        onRefresh: () async => ref.refresh(storeAnalyticsProvider),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          physics: const AlwaysScrollableScrollPhysics(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 24),
              
              analyticsAsync.when(
                data: (data) {
                  final totalRevenue = (data['totalRevenue'] as num).toDouble();
                  final totalOrders = (data['totalOrders'] as num).toInt();
                  final avgOrderValue = (data['avgOrderValue'] as num).toDouble();
                  final activeProducts = (data['activeProducts'] as num).toInt();
                  final recentOrders = data['recentOrders'] as List;

                  return Column(
                    children: [
                      // Metrics Grid
                      GridView.count(
                        crossAxisCount: MediaQuery.of(context).size.width > 900 ? 4 : 2,
                        crossAxisSpacing: 16,
                        mainAxisSpacing: 16,
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        childAspectRatio: 1.5,
                        children: [
                          _MetricCard(
                            title: "Total Revenue",
                            value: NumberFormat.currency(symbol: '₹', decimalDigits: 0).format(totalRevenue),
                            icon: Icons.attach_money,
                            color: Colors.green,
                          ),
                          _MetricCard(
                            title: "Total Orders",
                            value: totalOrders.toString(),
                            icon: Icons.shopping_bag,
                            color: Colors.blue,
                          ),
                          _MetricCard(
                            title: "Avg. Order Value",
                            value: NumberFormat.currency(symbol: '₹', decimalDigits: 0).format(avgOrderValue),
                            icon: Icons.trending_up,
                            color: Colors.orange,
                          ),
                          _MetricCard(
                            title: "Active Products",
                            value: activeProducts.toString(),
                            icon: Icons.visibility,
                            color: Colors.purple,
                          ),
                        ],
                      ),
                      const SizedBox(height: 32),
                      
                      // Chart Section
                      const Text("Revenue Trend (Last 7 Days)", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 16),
                      Container(
                        height: 300,
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(color: Colors.grey.withOpacity(0.1), blurRadius: 10, offset: const Offset(0, 4)),
                          ],
                        ),
                        child: recentOrders.isEmpty
                            ? const Center(child: Text("No recent orders data"))
                            : _RevenueChart(orders: recentOrders),
                      ),
                    ],
                  );
                },
                loading: () => const SizedBox(height: 400, child: Center(child: CircularProgressIndicator())),
                error: (err, stack) => Center(child: Text('Error: $err')),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MetricCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color color;

  const _MetricCard({
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 20),
              const SizedBox(width: 8),
              Text(title, style: TextStyle(color: Colors.grey[600], fontSize: 13)),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }
}

class _RevenueChart extends StatelessWidget {
  final List orders;

  const _RevenueChart({required this.orders});

  List<Map<String, dynamic>> _processData() {
    // Group orders by day (last 7 days)
    final now = DateTime.now();
    Map<int, double> dailyRevenue = {};
    
    // Initialize last 7 days with 0
    for (int i = 6; i >= 0; i--) {
      final date = now.subtract(Duration(days: i));
      final dayKey = int.parse(DateFormat('yyyyMMdd').format(date));
      dailyRevenue[dayKey] = 0.0;
    }

    for (var order in orders) {
       final dateStr = order['created_at'];
       if (dateStr != null) {
         final date = DateTime.parse(dateStr).toLocal();
         final dayKey = int.parse(DateFormat('yyyyMMdd').format(date));
         if (dailyRevenue.containsKey(dayKey)) {
           dailyRevenue[dayKey] = (dailyRevenue[dayKey] ?? 0) + (order['total_amount'] as num).toDouble();
         }
       }
    }

    List<Map<String, dynamic>> result = [];
    int index = 0;
    final sortedKeys = dailyRevenue.keys.toList()..sort();
    
    for (var key in sortedKeys) {
      // Reconstruct date for label
      final dateStr = key.toString();
      final date = DateTime.parse("${dateStr.substring(0,4)}-${dateStr.substring(4,6)}-${dateStr.substring(6,8)}"); 
      
      result.add({
        'index': index++,
        'label': DateFormat('E').format(date), // Mon, Tue
        'value': dailyRevenue[key],
      });
    }
    return result;
  }

  @override
  Widget build(BuildContext context) {
    final data = _processData();
    final maxY = data.fold(0.0, (prev, e) => (e['value'] as double) > prev ? (e['value'] as double) : prev);

    return BarChart(
      BarChartData(
        alignment: BarChartAlignment.spaceAround,
        maxY: maxY * 1.2, // Add some headroom
        barTouchData: BarTouchData(
          enabled: true,
          touchTooltipData: BarTouchTooltipData(
            getTooltipColor: (group) => Colors.blueGrey,
            getTooltipItem: (group, groupIndex, rod, rodIndex) {
              return BarTooltipItem(
                '₹${rod.toY.toInt()}',
                const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
              );
            },
          ),
        ),
        titlesData: FlTitlesData(
          show: true,
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (value, meta) {
                if (value.toInt() >= 0 && value.toInt() < data.length) {
                   return Text(
                     data[value.toInt()]['label'],
                     style: const TextStyle(color: Colors.grey, fontSize: 12),
                   );
                }
                return const Text('');
              },
              reservedSize: 30,
            ),
          ),
          leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        ),
        gridData: const FlGridData(show: false),
        borderData: FlBorderData(show: false),
        barGroups: data.map((e) {
          return BarChartGroupData(
            x: e['index'],
            barRods: [
              BarChartRodData(
                toY: e['value'],
                color: Colors.blue,
                width: 16,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
              ),
            ],
          );
        }).toList(),
      ),
    );
  }
}
