import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../data/analytics_repository.dart';

class WormChart extends StatelessWidget {
  final List<OverSummary> teamAData;
  final List<OverSummary> teamBData;
  final String teamAName;
  final String teamBName;

  const WormChart({
    super.key, 
    required this.teamAData, 
    required this.teamBData,
    this.teamAName = 'Team A',
    this.teamBName = 'Team B',
  });

  @override
  Widget build(BuildContext context) {
    final maxY = _calculateMaxY();

    return AspectRatio(
      aspectRatio: 1.5,
      child: LineChart(
        LineChartData(
          minX: 0,
          maxX: 20, // Standard T20, could be dynamic
          minY: 0,
          maxY: maxY,
          lineTouchData: LineTouchData(
             touchTooltipData: LineTouchTooltipData(
               getTooltipColor: (_) => Colors.blueGrey,
               getTooltipItems: (touchedSpots) {
                 return touchedSpots.map((spot) {
                   final isTeamA = spot.barIndex == 0;
                   return LineTooltipItem(
                     '${isTeamA ? teamAName : teamBName}: ${spot.y.toInt()}',
                     TextStyle(color: isTeamA ? AppColors.primary : AppColors.secondary, fontWeight: FontWeight.bold),
                   );
                 }).toList();
               },
             ),
          ),
          gridData: FlGridData(
            show: true,
            drawVerticalLine: true,
            horizontalInterval: 20,
            verticalInterval: 5,
            getDrawingHorizontalLine: (value) => FlLine(color: Colors.grey.shade200, strokeWidth: 1),
            getDrawingVerticalLine: (value) => FlLine(color: Colors.grey.shade200, strokeWidth: 1),
          ),
          titlesData: FlTitlesData(
            show: true,
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                getTitlesWidget: (value, meta) {
                   if (value % 5 == 0) {
                     return Padding(
                       padding: const EdgeInsets.only(top: 8.0),
                       child: Text(value.toInt().toString(), style: const TextStyle(fontSize: 10, color: Colors.grey)),
                     );
                   }
                   return const SizedBox();
                },
                interval: 1,
                reservedSize: 30,
              ),
            ),
            leftTitles: AxisTitles(sideTitles: SideTitles(showTitles: true, interval: 20, reservedSize: 30, getTitlesWidget: (v,m)=>Text(v.toInt().toString(), style: const TextStyle(fontSize: 10, color: Colors.grey)))),
            topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          ),
          borderData: FlBorderData(show: false),
          lineBarsData: [
            // Team A Line
            LineChartBarData(
              spots: _generateSpots(teamAData),
              isCurved: false, // Worm charts are usually straight lines
              color: AppColors.primary, // Blue
              barWidth: 3,
              isStrokeCapRound: true,
              dotData: const FlDotData(show: false),
              belowBarData: BarAreaData(show: false),
            ),
            // Team B Line
            LineChartBarData(
              spots: _generateSpots(teamBData),
              isCurved: false,
              color: AppColors.secondary, // Green/Teal
              barWidth: 3,
              isStrokeCapRound: true,
              dotData: const FlDotData(show: false),
              belowBarData: BarAreaData(show: false),
            ),
          ],
        ),
      ),
    );
  }

  List<FlSpot> _generateSpots(List<OverSummary> data) {
    List<FlSpot> spots = [const FlSpot(0, 0)]; // Start at 0,0
    for (var over in data) {
      spots.add(FlSpot(over.overNumber.toDouble(), over.cumulativeScore.toDouble()));
    }
    return spots;
  }

  double _calculateMaxY() {
    double maxA = teamAData.isNotEmpty ? teamAData.last.cumulativeScore.toDouble() : 0;
    double maxB = teamBData.isNotEmpty ? teamBData.last.cumulativeScore.toDouble() : 0;
    double max = maxA > maxB ? maxA : maxB;
    return (max + 20); // Add buffer
  }
}
