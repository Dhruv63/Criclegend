import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';

class StoreAnalyticsScreen extends StatelessWidget {
  const StoreAnalyticsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text("Store Analytics", style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
          const SizedBox(height: 24),
          
          // Metrics Row
          Row(
            children: [
              _MetricCard(title: "Total Revenue", value: "₹45,200", icon: Icons.currency_rupee, color: Colors.green),
              _MetricCard(title: "Total Orders", value: "128", icon: Icons.shopping_bag, color: Colors.blue),
              _MetricCard(title: "Avg. Order Value", value: "₹353", icon: Icons.trending_up, color: Colors.purple),
              _MetricCard(title: "Product Views", value: "1.2k", icon: Icons.visibility, color: Colors.orange),
            ],
          ),
          
          const SizedBox(height: 32),
          
          // Chart Placeholder
          Expanded(
            child: Card(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text("Revenue Trend (Last 7 Days)", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                    const SizedBox(height: 16),
                    Expanded(
                      child: Center(
                         child: Text("Chart Integration Pending\n(Requires aggregator queries)", textAlign: TextAlign.center, style: TextStyle(color: Colors.grey.shade400)),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _MetricCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color color;

  const _MetricCard({required this.title, required this.value, required this.icon, required this.color});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Card(
        margin: const EdgeInsets.only(right: 16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        elevation: 2,
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(title, style: TextStyle(color: Colors.grey.shade600, fontSize: 12)),
                  Icon(icon, color: color, size: 20),
                ],
              ),
              const SizedBox(height: 12),
              Text(value, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
            ],
          ),
        ),
      ),
    );
  }
}
