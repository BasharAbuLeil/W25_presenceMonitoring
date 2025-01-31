import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';
import 'main.dart';
import 'session_data.dart';
import 'package:intl/intl.dart';
import 'dart:convert';
import 'dart:html' as html;
import 'package:csv/csv.dart';

class AllTreatmentSessionsPage extends StatefulWidget {
  final String userID;

  const AllTreatmentSessionsPage({Key? key, required this.userID})
      : super(key: key);

  @override
  _AllTreatmentSessionsPageState createState() =>
      _AllTreatmentSessionsPageState();
}

class _AllTreatmentSessionsPageState extends State<AllTreatmentSessionsPage> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  List<FlSpot> _createGraphData(List<QueryDocumentSnapshot> sessionDocs) {
    print('Creating graph data from ${sessionDocs.length} documents');

    // Sort sessions by date
    final sortedDocs = List<QueryDocumentSnapshot>.from(sessionDocs)
      ..sort((a, b) {
        final aData = a.data() as Map<String, dynamic>;
        final bData = b.data() as Map<String, dynamic>;
        final aDate = aData['date'] as Timestamp?;
        final bDate = bData['date'] as Timestamp?;
        if (aDate == null || bDate == null) return 0;
        return aDate.compareTo(bDate);
      });

    // Create spots for the graph
    final spots = <FlSpot>[];
    for (int i = 0; i < sortedDocs.length; i++) {
      final data = sortedDocs[i].data() as Map<String, dynamic>;
      // Make sure to properly parse the avgActivity value
      final activityVal = double.tryParse(data['avgActivity']?.toString() ?? '0') ?? 0.0;
      spots.add(FlSpot(i.toDouble(), activityVal));
    }

    print('Created ${spots.length} spots for the graph');
    return spots;
  }

  Widget _buildActivityGraph(
      List<QueryDocumentSnapshot> sessionDocs, ColorScheme colorScheme) {
    final spots = _createGraphData(sessionDocs);

    if (spots.isEmpty) {
      return const Center(child: Text('No activity data available'));
    }

    return Container(
      height: 200,
      padding: const EdgeInsets.all(16),
      child: LineChart(
        LineChartData(
          gridData: FlGridData(
            show: true,
            drawVerticalLine: true,
            horizontalInterval: 20,
          ),
          titlesData: FlTitlesData(
            show: true,
            rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
            topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
            bottomTitles: AxisTitles(
              axisNameWidget: Text(
                'Session Number',
                style: TextStyle(color: colorScheme.onSurface),
              ),
              sideTitles: SideTitles(
                showTitles: true,
                interval: 1,
                reservedSize: 30,
                getTitlesWidget: (value, meta) {
                  if (value < 0 || value >= spots.length) return const Text('');
                  return Text(
                    (value + 1).toInt().toString(),
                    style: TextStyle(
                      color: colorScheme.onSurface,
                      fontSize: 12,
                    ),
                  );
                },
              ),
            ),
            leftTitles: AxisTitles(
              axisNameWidget: Text(
                'Activity (%)',
                style: TextStyle(color: colorScheme.onSurface),
              ),
              sideTitles: SideTitles(
                showTitles: true,
                interval: 20,
                reservedSize: 40,
                getTitlesWidget: (value, meta) {
                  return Text(
                    value.toInt().toString(),
                    style: TextStyle(
                      color: colorScheme.onSurface,
                      fontSize: 12,
                    ),
                  );
                },
              ),
            ),
          ),
          borderData: FlBorderData(
            show: true,
            border: Border.all(color: colorScheme.outline, width: 1),
          ),
          minX: -0.5,
          maxX: spots.length - 0.5,
          minY: 0,
          maxY: 100,
          lineBarsData: [
            LineChartBarData(
              spots: spots,
              isCurved: false,
              color: AppTheme.accentColor,
              dotData: FlDotData(show: true),
              belowBarData: BarAreaData(show: false),
            ),
          ],
        ),
      ),
    );
  }

  void _exportToCsv(List<QueryDocumentSnapshot> sessionDocs) {
    try {
      List<List<dynamic>> rows = [
        ['Patient ID: ${widget.userID}'],
        [],
        ['Date', 'Duration (min)', 'Avg Activity (%)', 'Color', 'Relaxed'] // Removed 'Intensity'
      ];

      double totalDuration = 0;
      double totalActivity = 0;
      for (var doc in sessionDocs) {
        final data = doc.data() as Map<String, dynamic>;
        final Timestamp? dateTs = data['date'] as Timestamp?;
        final dateString = dateTs != null
            ? DateFormat('yyyy-MM-dd HH:mm').format(dateTs.toDate())
            : 'N/A';

        final duration = num.tryParse('${data['duration'] ?? 0}')?.toDouble() ?? 0;
        final activity = num.tryParse('${data['avgActivity'] ?? 0}')?.toDouble() ?? 0;

        totalDuration += duration;
        totalActivity += activity;

        rows.add([
          dateString,
          duration.toString(),
          activity.toString(),
          data['color'] ?? 'N/A',
          // data['intensity'] ?? 'N/A', // Removed 'Intensity'
          activity > 60 ? 'No' : 'Yes',
        ]);
      }

      final avgDuration = sessionDocs.isEmpty ? 0 : totalDuration / sessionDocs.length;
      final avgActivity = sessionDocs.isEmpty ? 0 : totalActivity / sessionDocs.length;

      rows.addAll([
        [],
        ['Summary Statistics'],
        ['Total Sessions:', sessionDocs.length.toString()],
        ['Average Duration:', '${avgDuration.toStringAsFixed(1)} min'],
        ['Average Activity:', '${avgActivity.toStringAsFixed(1)}%'],
        [],
        ['Report Generated:', DateFormat('yyyy-MM-dd HH:mm').format(DateTime.now())],
      ]);

      String csvData = const ListToCsvConverter().convert(rows);
      final bytes = utf8.encode(csvData);
      final blob = html.Blob([bytes]);
      final url = html.Url.createObjectUrlFromBlob(blob);

      final now = DateFormat('yyyy-MM-dd_HHmm').format(DateTime.now());
      final fileName = 'treatment_sessions_${widget.userID}_$now.csv';

      final anchor = html.AnchorElement(href: url)
        ..setAttribute("download", fileName)
        ..click();

      html.Url.revokeObjectUrl(url);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('CSV file downloaded successfully'),
          duration: Duration(seconds: 2),
        ),
      );
    } catch (e) {
      _showErrorDialog('Failed to export CSV: $e');
    }
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Theme.of(context).colorScheme.surface,
        title: Text(
          'Error',
          style: TextStyle(
            color: Theme.of(context).colorScheme.onErrorContainer,
          ),
        ),
        content: Text(
          message,
          style: TextStyle(
            color: Theme.of(context).colorScheme.onSurface,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(
              'OK',
              style: TextStyle(color: AppTheme.accentColor),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEnhancedInfoCard(
      String label,
      String value,
      String unit,
      IconData icon,
      TextTheme textTheme,
      ColorScheme colorScheme,
      ) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: colorScheme.outlineVariant,
          width: 1,
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            color: AppTheme.accentColor,
            size: 24,
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: textTheme.bodyMedium?.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 4),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                value,
                style: textTheme.titleLarge?.copyWith(
                  color: AppTheme.accentColor,
                  fontWeight: FontWeight.bold,
                ),
              ),
              if (unit.isNotEmpty) ...[
                const SizedBox(width: 2),
                Text(
                  unit,
                  style: textTheme.bodySmall?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context, listen: false);
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      backgroundColor: colorScheme.background,
      appBar: AppBar(
        title: Text(
          'Treatment Sessions',
          style: Theme.of(context).appBarTheme.titleTextStyle?.copyWith(
            color: colorScheme.onBackground,
          ) ?? textTheme.titleLarge?.copyWith(
            color: colorScheme.onBackground,
          ),
        ),
        backgroundColor: Theme.of(context).appBarTheme.backgroundColor,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // Summary Card with improved design
            Card(
              elevation: 3,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              color: colorScheme.surfaceVariant,
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: StreamBuilder<QuerySnapshot>(
                  stream: _firestore
                      .collection('sessions')
                      .where('userID', isEqualTo: widget.userID)
                      .snapshots(),
                  builder: (context, snapshot) {
                    if (!snapshot.hasData) {
                      return const Center(child: CircularProgressIndicator());
                    }

                    final sessionDocs = snapshot.data!.docs;
                    final totalSessions = sessionDocs.length;

                    // Calculate averages
                    double totalDuration = 0;
                    double totalActivity = 0;
                    int relaxedSessions = 0;

                    for (var doc in sessionDocs) {
                      final data = doc.data() as Map<String, dynamic>;
                      totalDuration += (data['duration'] ?? 0);
                      final activity = (data['avgActivity'] ?? 0);
                      totalActivity += activity;
                      if (activity <= 60) relaxedSessions++;
                    }

                    final avgDuration = totalSessions > 0 ? totalDuration / totalSessions : 0;
                    final avgActivity = totalSessions > 0 ? totalActivity / totalSessions : 0;
                    final relaxedPercentage = totalSessions > 0
                        ? (relaxedSessions / totalSessions * 100)
                        : 0;

                    return Column(
                      children: [
                        Row(
                          children: [
                            Icon(
                              Icons.analytics_outlined,
                              color: AppTheme.accentColor,
                              size: 24,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'Treatment Summary',
                              style: textTheme.titleMedium?.copyWith(
                                color: AppTheme.accentColor,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 20),
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: colorScheme.surface,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: colorScheme.outlineVariant,
                              width: 1,
                            ),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceAround,
                            children: [
                              _buildEnhancedInfoCard(
                                'Total Sessions',
                                totalSessions.toString(),
                                '',
                                Icons.calendar_today,
                                textTheme,
                                colorScheme,
                              ),
                              _buildEnhancedInfoCard(
                                'Avg Duration',
                                avgDuration.toStringAsFixed(1),
                                'min',
                                Icons.timer_outlined,
                                textTheme,
                                colorScheme,
                              ),
                              _buildEnhancedInfoCard(
                                'Avg Activity',
                                avgActivity.toStringAsFixed(1),
                                '%',
                                Icons.trending_up,
                                textTheme,
                                colorScheme,
                              ),
                              _buildEnhancedInfoCard(
                                'Relaxed Sessions',
                                relaxedPercentage.toStringAsFixed(1),
                                '%',
                                Icons.brightness_low,
                                textTheme,
                                colorScheme,
                              ),
                            ],
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ),
            ),

            const SizedBox(height: 24),

            // Graph and Table Section
            Expanded(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Left side - Data Table
                  Expanded(
                    flex: 1,
                    child: Card(
                      elevation: 1,
                      child: StreamBuilder<QuerySnapshot>(
                        stream: _firestore
                            .collection('sessions')
                            .where('userID', isEqualTo: widget.userID)
                            .snapshots(),
                        builder: (context, snapshot) {
                          if (!snapshot.hasData) {
                            return const Center(child: CircularProgressIndicator());
                          }

                          final sessionDocs = snapshot.data!.docs;

                          return Column(
                            children: [
                              Padding(
                                padding: const EdgeInsets.all(16.0),
                                child: Text(
                                  'Session History',
                                  style: textTheme.titleMedium?.copyWith(
                                    color: colorScheme.onBackground,
                                  ),
                                ),
                              ),
                              Expanded(
                                child: SingleChildScrollView(
                                  scrollDirection: Axis.horizontal,
                                  child: SingleChildScrollView(
                                    child: DataTable(
                                      headingRowColor: MaterialStateColor.resolveWith(
                                            (states) => colorScheme.surfaceVariant.withOpacity(0.7),
                                      ),
                                      dataRowColor: MaterialStateColor.resolveWith(
                                            (states) => colorScheme.surface,
                                      ),
                                      columnSpacing: 16,
                                      headingTextStyle: textTheme.titleMedium?.copyWith(
                                        color: colorScheme.onSurfaceVariant,
                                        fontWeight: FontWeight.bold,
                                      ),
                                      dataTextStyle: textTheme.bodyMedium?.copyWith(
                                        color: colorScheme.onSurface,
                                      ),
                                      columns: const [
                                        DataColumn(label: Text('Date')),
                                        DataColumn(label: Text('Duration (min)')),
                                        DataColumn(label: Text('Avg Activity (%)')),
                                        DataColumn(label: Text('Color')),
                                        // DataColumn(label: Text('Intensity')), // Removed 'Intensity'
                                        DataColumn(label: Text('Relaxed')),
                                        DataColumn(label: Text('View')),
                                      ],
                                      rows: sessionDocs.map((doc) {
                                        final data = doc.data() as Map<String, dynamic>;
                                        final Timestamp? dateTs = data['date'] as Timestamp?;
                                        final dateString = (dateTs != null)
                                            ? DateFormat('yyyy-MM-dd HH:mm').format(dateTs.toDate())
                                            : 'N/A';

                                        return DataRow(
                                          cells: [
                                            DataCell(Text(dateString)),
                                            DataCell(Text('${data['duration'] ?? 0}')),
                                            DataCell(Text('${data['avgActivity'] ?? 0}')),
                                            DataCell(Text('${data['color'] ?? 'N/A'}')),
                                            // DataCell(Text('${data['intensity'] ?? 'N/A'}')), // Removed 'Intensity'
                                            DataCell(Text((data['avgActivity'] ?? 0) > 60 ? 'No' : 'Yes')),
                                            DataCell(
                                              FilledButton.tonal(
                                                onPressed: () {
                                                  Navigator.push(
                                                    context,
                                                    MaterialPageRoute(
                                                      builder: (_) => SessionDataPage(
                                                        sessionDocID: doc.id,
                                                      ),
                                                    ),
                                                  );
                                                },
                                                child: const Text('View'),
                                              ),
                                            ),
                                          ],
                                        );
                                      }).toList(),
                                    ),
                                  ),
                                ),
                              ),
                              Padding(
                                padding: const EdgeInsets.all(16.0),
                                child: SizedBox(
                                  width: 180,
                                  child: ElevatedButton.icon(
                                    onPressed: () => _exportToCsv(sessionDocs),
                                    icon: const Icon(Icons.download),
                                    label: const Text('Export to CSV'),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: AppTheme.accentColor,
                                      foregroundColor: Colors.white,
                                      padding: const EdgeInsets.symmetric(vertical: 12),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          );
                        },
                      ),
                    ),
                  ),

                  const SizedBox(width: 16),

                  // Right side - Graph
                  Expanded(
                    flex: 1,
                    child: Card(
                      elevation: 1,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Text(
                              'Activity Progress',
                              style: textTheme.titleMedium?.copyWith(
                                color: colorScheme.onBackground,
                              ),
                            ),
                          ),
                          Expanded(
                            child: StreamBuilder<QuerySnapshot>(
                              stream: _firestore
                                  .collection('sessions')
                                  .where('userID', isEqualTo: widget.userID)
                                  .snapshots(),
                              builder: (context, snapshot) {
                                if (!snapshot.hasData) {
                                  return const Center(child: CircularProgressIndicator());
                                }
                                return _buildActivityGraph(
                                  snapshot.data!.docs,
                                  colorScheme,
                                );
                              },
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
