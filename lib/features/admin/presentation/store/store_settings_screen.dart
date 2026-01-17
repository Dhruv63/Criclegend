import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';

class StoreSettingsScreen extends StatefulWidget {
  const StoreSettingsScreen({super.key});

  @override
  State<StoreSettingsScreen> createState() => _StoreSettingsScreenState();
}

class _StoreSettingsScreenState extends State<StoreSettingsScreen> {
  // Delivery
  final _freeDeliveryThresholdCtrl = TextEditingController(text: '1000');
  final _deliveryChargeCtrl = TextEditingController(text: '50');

  // Tax
  bool _enableTax = true;
  final _taxPercentCtrl = TextEditingController(text: '18');

  // Contact
  final _emailCtrl = TextEditingController(text: 'support@criclegend.com');

  bool _storeOpen = true;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: ListView(
        children: [
          const Text(
            "Store Settings",
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 24),

          _buildSection("Delivery Configuration", [
            TextFormField(
              controller: _freeDeliveryThresholdCtrl,
              decoration: const InputDecoration(
                labelText: 'Free Delivery Threshold (₹)',
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _deliveryChargeCtrl,
              decoration: const InputDecoration(
                labelText: 'Standard Delivery Charge (₹)',
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.number,
            ),
          ]),

          _buildSection("Tax Configuration", [
            SwitchListTile(
              title: const Text("Enable Tax (GST)"),
              value: _enableTax,
              onChanged: (v) => setState(() => _enableTax = v),
              contentPadding: EdgeInsets.zero,
            ),
            if (_enableTax)
              TextFormField(
                controller: _taxPercentCtrl,
                decoration: const InputDecoration(
                  labelText: 'GST Percentage (%)',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.number,
              ),
          ]),

          _buildSection("Store Status", [
            SwitchListTile(
              title: const Text("Store Open"),
              subtitle: const Text(
                "Turn off to show maintenance mode to users",
              ),
              value: _storeOpen,
              activeThumbColor: Colors.green,
              onChanged: (v) => setState(() => _storeOpen = v),
              contentPadding: EdgeInsets.zero,
            ),
          ]),

          const SizedBox(height: 32),
          ElevatedButton(
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text("Settings Saved Successfully")),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
            ),
            child: const Text("Save Changes"),
          ),
        ],
      ),
    );
  }

  Widget _buildSection(String title, List<Widget> children) {
    return Card(
      margin: const EdgeInsets.only(bottom: 24),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
            ),
            const Divider(height: 32),
            ...children,
          ],
        ),
      ),
    );
  }
}
