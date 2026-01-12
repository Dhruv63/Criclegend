import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../data/analytics_repository.dart';

class ManhattanChart extends StatelessWidget {
  final List<OverSummary> data;
  final Color barColor;

  const ManhattanChart({super.key, required this.data, required this.barColor});

  @override
  Widget build(BuildContext context) {
    if (data.isEmpty) return const Center(child: Text("No data usually means 0 runs or match hasn't started."));

    return AspectRatio(
      aspectRatio: 1.5,
      child: BarChart(
        BarChartData(
          alignment: BarChartAlignment.spaceAround,
          maxY: 25, // Fixed Max Y for simple comparison, or dynamic
          barTouchData: BarTouchData(
            enabled: true,
            touchTooltipData: BarTouchTooltipData(
              getTooltipColor: (_) => Colors.blueGrey,
              getTooltipItem: (group, groupIndex, rod, rodIndex) {
                final over = data[groupIndex];
                return BarTooltipItem(
                  'Over ${over.overNumber}\n',
                  const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                  children: <TextSpan>[
                    TextSpan(
                      text: '${over.runsConceded} Runs\n',
                      style: const TextStyle(color: Colors.white),
                    ),
                    if (over.wicketsInOver > 0)
                      TextSpan(
                        text: '${over.wicketsInOver} Wickets',
                        style: const TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold),
                      ),
                  ],
                );
              },
            ),
          ),
          titlesData: FlTitlesData(
            show: true,
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                getTitlesWidget: (double value, TitleMeta meta) {
                  return Padding(
                    padding: const EdgeInsets.only(top: 8.0),
                    child: Text(
                      (value + 1).toInt().toString(), // 0-index to 1-index
                      style: const TextStyle(color: Colors.grey, fontSize: 10),
                    ),
                  );
                },
                reservedSize: 30,
              ),
            ),
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                getTitlesWidget: (value, meta) => Text(value.toInt().toString(), style: const TextStyle(fontSize: 10, color: Colors.grey)),
                interval: 5,
                reservedSize: 20,
              ),
            ),
            topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          ),
          gridData: FlGridData(
            show: true,
            drawVerticalLine: false,
            horizontalInterval: 5,
            getDrawingHorizontalLine: (value) => FlLine(color: Colors.grey.shade200, strokeWidth: 1),
          ),
          borderData: FlBorderData(show: false),
          barGroups: data.asMap().entries.map((e) {
            final index = e.key;
            final over = e.value;
            final hasWicket = over.wicketsInOver > 0;
            
            return BarChartGroupData(
              x: index,
              barRods: [
                BarChartRodData(
                  toY: over.runsConceded.toDouble(),
                  color: hasWicket ? Colors.orangeAccent : barColor, // Highlight wicket overs
                  width: 12,
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
                  backDrawRodData: BackgroundBarChartRodData(show: true, toY: 25, color: Colors.grey.shade50),
                ),
              ],
            );
          }).toList(),
        ),
      ),
    );
  }
}
