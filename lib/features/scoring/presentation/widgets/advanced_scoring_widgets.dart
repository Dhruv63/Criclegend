import 'dart:math';
import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../../../core/theme/app_colors.dart';

// --- WAGON WHEEL SELECTOR ---

class WagonWheelSelector extends StatelessWidget {
  const WagonWheelSelector({super.key});

  @override
  Widget build(BuildContext context) {
    // 8 Zones
    final zones = [
      'Long Off', 'Long On', 'Deep Mid Wicket', 'Deep Square Leg',
      'Fine Leg', 'Third Man', 'Deep Point', 'Deep Cover'
    ];

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.all(12),
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Colors.white,
          shape: BoxShape.circle,
          border: Border.all(color: AppColors.deepTeal, width: 4),
          boxShadow: const [BoxShadow(blurRadius: 20, color: Colors.black45)],
        ),
        child: AspectRatio(
          aspectRatio: 1,
          child: LayoutBuilder(
            builder: (context, constraints) {
              final radius = constraints.maxWidth / 2;
              return Stack(
                alignment: Alignment.center,
                children: [
                  // Field Background
                  Container(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.green.shade50,
                      border: Border.all(color: Colors.green.shade200),
                    ),
                  ),
                  // Render 8 Slices
                  ...List.generate(8, (index) {
                    final angle = (2 * pi / 8) * index;
                    // Adjust angle to start from top
                    final rotatedAngle = angle - (pi / 2) - (pi/8); 
                    
                    return Transform.rotate(
                      angle: (2 * pi / 8) * index,
                      child: Align(
                        alignment: Alignment.topCenter,
                        child: _SliceButton(
                          label: zones[index],
                          onTap: () => Navigator.pop(context, zones[index]),
                        ),
                      ),
                    );
                  }),
                  // Pitch Area
                  Container(
                    width: 40, height: 80,
                    decoration: BoxDecoration(
                      color: const Color(0xFFECD2A6),
                      borderRadius: BorderRadius.circular(4),
                      border: Border.all(color: Colors.brown.shade300),
                    ),
                    child: Center(child: Icon(LucideIcons.crosshair, color: Colors.brown, size: 24)),
                  ),
                ],
              );
            }
          ),
        ),
      ),
    );
  }
}

class _SliceButton extends StatelessWidget {
  final String label;
  final VoidCallback onTap;
  const _SliceButton({required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 120, // Approximate half-radius
        width: 80,
        alignment: Alignment.topCenter,
        padding: const EdgeInsets.only(top: 20),
        color: Colors.transparent, // Hit test
        child: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 4)],
          ),
          child: Text(label, textAlign: TextAlign.center, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold)),
        ),
      ),
    );
  }
}

// --- DISMISSAL MODAL ---

class DismissalDialog extends StatefulWidget {
  final List<Map<String, dynamic>> fieldingTeam;
  final List<Map<String, dynamic>> battingTeam;
  
  const DismissalDialog({
    super.key, 
    required this.fieldingTeam, 
    required this.battingTeam
  });

  @override
  State<DismissalDialog> createState() => _DismissalDialogState();
}

class _DismissalDialogState extends State<DismissalDialog> {
  String _type = 'Caught';
  String? _fielderId;
  String? _newStrikerId;

  final _types = ['Bowled', 'Caught', 'LBW', 'Run Out', 'Stumped', 'Hit Wicket'];

  @override
  Widget build(BuildContext context) {
    final needsFielder = ['Caught', 'Run Out', 'Stumped'].contains(_type);

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: const BoxDecoration(color: AppColors.error, shape: BoxShape.circle),
                child: const Icon(Icons.logout, color: Colors.white, size: 20),
              ),
              const SizedBox(width: 12),
              const Text('Wicket Fall!', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            ],
          ),
          const SizedBox(height: 24),
          
          // 1. Dismissal Type
          DropdownButtonFormField<String>(
            value: _type,
            decoration: const InputDecoration(labelText: 'How?', border: OutlineInputBorder()),
            items: _types.map((t) => DropdownMenuItem(value: t, child: Text(t))).toList(),
            onChanged: (val) => setState(() => _type = val!),
          ),
          const SizedBox(height: 16),

          // 2. Fielder (Conditional)
          if (needsFielder) ...[
            DropdownButtonFormField<String>(
              value: _fielderId,
              decoration: const InputDecoration(labelText: 'Who caught/fielded it?', border: OutlineInputBorder()),
              items: widget.fieldingTeam.map((p) {
                final name = p['profile_json']?['name'] ?? 'Unknown';
                return DropdownMenuItem(value: p['id'] as String, child: Text(name));
              }).toList(),
              onChanged: (val) => setState(() => _fielderId = val),
            ),
            const SizedBox(height: 16),
          ],

          // 3. New Batsman
          DropdownButtonFormField<String>(
            value: _newStrikerId,
            decoration: const InputDecoration(labelText: 'Who is coming in?', border: OutlineInputBorder()),
            items: widget.battingTeam.map((p) {
              final name = p['profile_json']?['name'] ?? 'Unknown';
              return DropdownMenuItem(value: p['id'] as String, child: Text(name));
            }).toList(),
            onChanged: (val) => setState(() => _newStrikerId = val),
          ),
          const SizedBox(height: 32),

          // Submit
          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.error, foregroundColor: Colors.white),
              onPressed: () {
                if (_newStrikerId == null) {
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please select the new batsman')));
                  return;
                }
                Navigator.pop(context, {
                  'type': _type,
                  'fielderId': needsFielder ? _fielderId : null,
                  'newStrikerId': _newStrikerId,
                });
              },
              child: const Text('CONFIRM WICKET'),
            ),
          ),
        ],
      ),
    );
  }
}
