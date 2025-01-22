import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';
import 'main.dart';
import 'package:intl/intl.dart';
import 'dart:convert';
import 'dart:html' as html;
import 'package:csv/csv.dart';

class SessionDataPage extends StatefulWidget {
  final String sessionDocID;

  const SessionDataPage({
    Key? key,
    required this.sessionDocID,
  }) : super(key: key);

  @override
  _SessionDataPageState createState() => _SessionDataPageState();
}

class _SessionDataPageState extends State<SessionDataPage> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  List<FlSpot> _createGraphData(List<QueryDocumentSnapshot> minuteDocs) {
    final spots = <FlSpot>[];
    for (var doc in minuteDocs) {
      final logData = doc.data() as Map<String, dynamic>;
      final minute = (logData['minuteIndex'] as num?)?.toDouble() ?? 0;
      final activity = (logData['activity'] as num?)?.toDouble() ?? 0;
      spots.add(FlSpot(minute, activity));
    }
    spots.sort((a, b) => a.x.compareTo(b.x)); // Sort by minute
    return spots;
  }

  Widget _buildActivityGraph(List<QueryDocumentSnapshot> minuteDocs,
      ColorScheme colorScheme) {
    final spots = _createGraphData(minuteDocs);

    return Container(
      padding: const EdgeInsets.all(16),
      child: LineChart(
        LineChartData(
          gridData: FlGridData(
            show: true,
            drawVerticalLine: true,
            horizontalInterval: 20,
            verticalInterval: 1,
          ),
          titlesData: FlTitlesData(
            show: true,
            rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
            topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
            bottomTitles: AxisTitles(
              axisNameWidget: Text(
                'Time (minutes)',
                style: TextStyle(color: colorScheme.onSurface),
              ),
              sideTitles: SideTitles(
                showTitles: true,
                interval: 1,
                reservedSize: 30,
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
          maxX: spots.isEmpty ? 0.5 : spots.length - 0.5,
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

  void _exportToCsv(List<QueryDocumentSnapshot> minuteDocs, String sessionDocID) {
    try {
      // First get the session document to access the session date
      _firestore.collection('sessions').doc(sessionDocID).get().then((sessionDoc) {
        if (sessionDoc.exists) {
          final sessionData = sessionDoc.data() as Map<String, dynamic>;
          final Timestamp? dateTs = sessionData['date'] as Timestamp?;
          final dateString = dateTs != null
              ? DateFormat('yyyy-MM-dd HH:mm').format(dateTs.toDate())
              : 'N/A';

          // Prepare CSV headers and data
          List<List<dynamic>> rows = [
            ['Session Date: $dateString'],
            [], // Empty row for spacing
            ['Minute', 'Color', 'Activity', 'Relaxed']
          ];

          // Populate rows from Firestore documents
          for (var doc in minuteDocs) {
            final logData = doc.data() as Map<String, dynamic>;
            rows.add([
              logData['minuteIndex'] ?? '',
              logData['color'] ?? '',
              '${logData['activity'] ?? ''}%',
              (logData['relaxed'] == true) ? 'Yes' : 'No',
            ]);
          }

          // Convert to CSV
          String csvData = const ListToCsvConverter().convert(rows);

          // Create blob
          final bytes = utf8.encode(csvData);
          final blob = html.Blob([bytes]);
          final url = html.Url.createObjectUrlFromBlob(blob);

          // Create download link with session date in filename
          final safeFileName = dateString.replaceAll(':', '-').replaceAll(' ', '_');
          final anchor = html.AnchorElement(href: url)
            ..setAttribute("download", "session_data_$safeFileName.csv")
            ..click();

          // Clean up
          html.Url.revokeObjectUrl(url);

          // Show success message
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('CSV file downloaded successfully'),
              duration: Duration(seconds: 2),
            ),
          );
        } else {
          _showErrorDialog('Session data not found');
        }
      }).catchError((error) {
        _showErrorDialog('Failed to fetch session data: $error');
      });
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
  Widget _buildInfoCard(String label,
      String value,
      TextTheme textTheme,
      ColorScheme colorScheme,) {
    return Column(
      children: [
        Text(
          label,
          style: textTheme.bodyMedium?.copyWith(
            color: colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: textTheme.titleLarge?.copyWith(
            color: colorScheme.onSurfaceVariant,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final colorScheme = Theme
        .of(context)
        .colorScheme;
    final textTheme = Theme
        .of(context)
        .textTheme;

    return Scaffold(
      backgroundColor: colorScheme.background,
      appBar: AppBar(
        title: Text(
          'Session Details',
          style: Theme
              .of(context)
              .appBarTheme
              .titleTextStyle
              ?.copyWith(
            color: colorScheme.onBackground,
          ) ??
              textTheme.titleLarge?.copyWith(color: colorScheme.onBackground),
        ),
        backgroundColor: Theme
            .of(context)
            .appBarTheme
            .backgroundColor,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // Session Information Card at the top
            StreamBuilder<DocumentSnapshot>(
              stream: _firestore
                  .collection('sessions')
                  .doc(widget.sessionDocID)
                  .snapshots(),
              builder: (context, sessionSnapshot) {
                if (sessionSnapshot.hasError) {
                  return Text(
                    'Error loading session data',
                    style: textTheme.bodyMedium?.copyWith(
                        color: colorScheme.error),
                  );
                }
                if (!sessionSnapshot.hasData || !sessionSnapshot.data!.exists) {
                  return const SizedBox.shrink();
                }

                final sessionData =
                sessionSnapshot.data!.data() as Map<String, dynamic>?;
                final Timestamp? dateTs = sessionData?['date'];
                String dateTimeString = 'N/A';
                if (dateTs != null) {
                  dateTimeString =
                      DateFormat('yyyy-MM-dd HH:mm').format(dateTs.toDate());
                }

                return Card(
                  elevation: 2,
                  color: colorScheme.surfaceVariant,
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      children: [
                        Text(
                          'Session Information',
                          style: textTheme.titleMedium?.copyWith(
                            color: colorScheme.onSurfaceVariant,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          dateTimeString,
                          style: textTheme.headlineMedium?.copyWith(
                            color: colorScheme.onSurfaceVariant,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 16),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceAround,
                          children: [
                            _buildInfoCard(
                              'Duration',
                              '${sessionData?['duration'] ?? 0} min',
                              textTheme,
                              colorScheme,
                            ),
                            _buildInfoCard(
                              'Avg Activity',
                              '${sessionData?['avgActivity'] ?? 0}%',
                              textTheme,
                              colorScheme,
                            ),
                            _buildInfoCard(
                              'Status',
                              sessionData?['relaxed'] == true
                                  ? 'Relaxed'
                                  : 'Active',
                              textTheme,
                              colorScheme,
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),

            const SizedBox(height: 24),

            // Table and Graph side by side
            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream: _firestore
                    .collection('sessions')
                    .doc(widget.sessionDocID)
                    .collection('minuteLogs')
                    .orderBy('minuteIndex', descending: false)
                    .snapshots(),
                builder: (context, snapshot) {
                  if (snapshot.hasError) {
                    return Center(
                      child: Text(
                        'Error fetching data',
                        style: textTheme.bodyMedium?.copyWith(color: colorScheme
                            .error),
                      ),
                    );
                  }
                  if (!snapshot.hasData) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  final minuteDocs = snapshot.data!.docs;

                  return Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Left side - Data Table
                      Expanded(
                        flex: 1,
                        child: Card(
                          elevation: 1,
                          child: Column(
                            children: [
                              Expanded(
                                child: SingleChildScrollView(
                                  scrollDirection: Axis.horizontal,
                                  child: SingleChildScrollView(
                                    child: DataTable(
                                      headingRowColor: MaterialStateColor
                                          .resolveWith(
                                            (states) =>
                                            colorScheme.surfaceVariant
                                                .withOpacity(0.7),
                                      ),
                                      dataRowColor: MaterialStateColor
                                          .resolveWith(
                                            (states) => colorScheme.surface,
                                      ),
                                      columnSpacing: 16,
                                      headingTextStyle:
                                      textTheme.titleMedium?.copyWith(
                                        color: colorScheme.onSurfaceVariant,
                                        fontWeight: FontWeight.bold,
                                      ),
                                      dataTextStyle: textTheme.bodyMedium
                                          ?.copyWith(
                                        color: colorScheme.onSurface,
                                      ),
                                      columns: const [
                                        DataColumn(label: Text('Minute')),
                                        DataColumn(label: Text('Color')),
                                        DataColumn(label: Text('Activity')),
                                        DataColumn(label: Text('Relaxed')),
                                      ],
                                      rows: minuteDocs.map((doc) {
                                        final logData =
                                        doc.data() as Map<String, dynamic>;
                                        return DataRow(cells: [
                                          DataCell(Text(
                                              '${logData['minuteIndex'] ??
                                                  0}')),
                                          DataCell(
                                              Text('${logData['color'] ??
                                                  'N/A'}')),
                                          DataCell(
                                              Text('${logData['activity'] ??
                                                  0}%')),
                                          DataCell(
                                              Text(logData['relaxed'] == true
                                                  ? 'Yes'
                                                  : 'No')),
                                        ]);
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
                                    onPressed: () => _exportToCsv(minuteDocs, widget.sessionDocID),
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
                                  'Activity Over Time',
                                  style: textTheme.titleMedium?.copyWith(
                                    color: colorScheme.onBackground,
                                  ),
                                ),
                              ),
                              Expanded(
                                child: _buildActivityGraph(
                                    minuteDocs, colorScheme),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
