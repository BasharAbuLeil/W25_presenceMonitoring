import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import 'main.dart';
import 'session_data.dart';
import 'package:intl/intl.dart';
import 'dart:convert';
import 'dart:html' as html;
import 'package:csv/csv.dart';

class GlobalHistoryPage extends StatefulWidget {
  final DateTime startDate;
  final DateTime endDate;

  const GlobalHistoryPage({
    Key? key,
    required this.startDate,
    required this.endDate,
  }) : super(key: key);

  @override
  _GlobalHistoryPageState createState() => _GlobalHistoryPageState();
}

class _GlobalHistoryPageState extends State<GlobalHistoryPage> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  late DateTime _expandedStart;
  late DateTime _expandedEnd;
  bool get _isSingleDay => widget.startDate.year == widget.endDate.year
      && widget.startDate.month == widget.endDate.month
      && widget.startDate.day == widget.endDate.day;

  @override
  void initState() {
    super.initState();
    if (_isSingleDay) {
      _expandedStart = DateTime(widget.startDate.year, widget.startDate.month, widget.startDate.day, 0, 0, 0);
      _expandedEnd = DateTime(widget.startDate.year, widget.startDate.month, widget.startDate.day, 23, 59, 59);
    } else {
      _expandedStart = widget.startDate;
      _expandedEnd = widget.endDate;
    }
  }

  void _exportToCsv(List<QueryDocumentSnapshot> sessionDocs) {
    try {
      // Prepare CSV headers and data
      List<List<dynamic>> rows = [
        [_isSingleDay ? 'Date: ${_formatDate(_expandedStart)}' :
        'Date Range: ${_formatDate(_expandedStart)} - ${_formatDate(_expandedEnd)}'],
        [], // Empty row for spacing
        ['Date', 'Time', 'Patient ID', 'Duration (min)', 'Activity (%)', 'Color', 'Relaxed'] // Removed 'Intensity'
      ];

      // Populate rows from Firestore documents
      for (var doc in sessionDocs) {
        final data = doc.data() as Map<String, dynamic>;
        final Timestamp? dateTs = data['date'];

        // Convert duration and activity to numbers before adding to rows
        final duration = num.tryParse('${data['duration'] ?? 0}') ?? 0;
        final activity = num.tryParse('${data['avgActivity'] ?? 0}') ?? 0;

        rows.add([
          _formatTimestamp(dateTs),
          data['time'] ?? 'N/A',
          data['userID'] ?? 'N/A',
          duration.toString(),  // Convert to string after calculation
          activity.toString(), // Convert to string after calculation
          data['color'] ?? 'N/A',
          // data['intensity'] ?? 'N/A', // Removed 'Intensity'
          data['relaxed'] == true ? 'Yes' : 'No',
        ]);
      }

      // Calculate averages with proper number conversion
      double avgDuration = 0;
      double avgActivity = 0;

      if (sessionDocs.isNotEmpty) {
        double totalDuration = 0;
        double totalActivity = 0;

        for (var doc in sessionDocs) {
          final data = doc.data() as Map<String, dynamic>;
          totalDuration += num.tryParse('${data['duration'] ?? 0}')?.toDouble() ?? 0;
          totalActivity += num.tryParse('${data['avgActivity'] ?? 0}')?.toDouble() ?? 0;
        }

        avgDuration = totalDuration / sessionDocs.length;
        avgActivity = totalActivity / sessionDocs.length;
      }

      // Add summary statistics
      rows.add([]);  // Empty row for spacing
      rows.add(['Summary Statistics']);
      rows.add(['Total Sessions', sessionDocs.length.toString()]);
      rows.add(['Average Duration', '${avgDuration.toStringAsFixed(1)} min']);
      rows.add(['Average Activity', '${avgActivity.toStringAsFixed(1)}%']);

      // Convert to CSV
      String csvData = const ListToCsvConverter().convert(rows);

      // Create blob
      final bytes = utf8.encode(csvData);
      final blob = html.Blob([bytes]);
      final url = html.Url.createObjectUrlFromBlob(blob);

      // Create download link with date range in filename
      final fileName = _isSingleDay
          ? 'treatment_history_${_formatDate(_expandedStart)}.csv'
          : 'treatment_history_${_formatDate(_expandedStart)}_to_${_formatDate(_expandedEnd)}.csv';

      final anchor = html.AnchorElement(href: url)
        ..setAttribute("download", fileName)
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

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    final startTs = Timestamp.fromDate(_expandedStart);
    final endTs = Timestamp.fromDate(_expandedEnd);

    return Scaffold(
      backgroundColor: colorScheme.background,
      appBar: AppBar(
        title: Text(
          'Treatment History',
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
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Card(
              elevation: 2,
              color: colorScheme.surfaceVariant,
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 24.0, horizontal: 16.0),
                child: Column(
                  children: [
                    Text(
                      _isSingleDay ? 'Selected Date' : 'Date Range',
                      style: textTheme.titleMedium?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _isSingleDay
                          ? _formatDate(widget.startDate)
                          : '${_formatDate(widget.startDate)} - ${_formatDate(widget.endDate)}',
                      style: textTheme.headlineMedium?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            Expanded(
              child: Card(
                elevation: 1,
                child: StreamBuilder<QuerySnapshot>(
                  stream: _firestore
                      .collection('sessions')
                      .where('date', isGreaterThanOrEqualTo: startTs)
                      .where('date', isLessThanOrEqualTo: endTs)
                      .snapshots(),
                  builder: (context, snapshot) {
                    if (snapshot.hasError) {
                      return Center(
                        child: Text(
                          'Error loading sessions',
                          style: textTheme.bodyMedium?.copyWith(color: colorScheme.error),
                        ),
                      );
                    }
                    if (!snapshot.hasData) {
                      return const Center(child: CircularProgressIndicator());
                    }

                    final sessionDocs = snapshot.data!.docs;

                    return Column(
                      children: [
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
                                  DataColumn(label: Text('Time')),
                                  DataColumn(label: Text('ID')),
                                  DataColumn(label: Text('Duration')),
                                  DataColumn(label: Text('Activity')),
                                  DataColumn(label: Text('Color')),
                                  // DataColumn(label: Text('Intensity')), // Removed 'Intensity' column
                                  DataColumn(label: Text('Relaxed')),
                                  DataColumn(label: Text('View')),
                                ],
                                rows: sessionDocs.map((doc) {
                                  final data = doc.data() as Map<String, dynamic>;
                                  final Timestamp? dateTs = data['date'];

                                  return DataRow(
                                    cells: [
                                      DataCell(Text(_formatTimestamp(dateTs))),
                                      DataCell(Text('${data['time'] ?? 'N/A'}')),
                                      DataCell(Text('${data['userID'] ?? 'N/A'}')),
                                      DataCell(Text('${data['duration'] ?? 0} min')),
                                      DataCell(Text('${data['avgActivity'] ?? 0}%')),
                                      DataCell(Text('${data['color'] ?? 'N/A'}')),
                                      // DataCell(Text('${data['intensity'] ?? 'N/A'}')), // Removed 'Intensity' cell
                                      DataCell(Text(data['relaxed'] == true ? 'Yes' : 'No')),
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
                        const SizedBox(height: 16),
                        SizedBox(
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
                        const SizedBox(height: 16),
                      ],
                    );
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatTimestamp(Timestamp? ts) {
    if (ts == null) return 'N/A';
    final date = ts.toDate();
    return DateFormat('yyyy-MM-dd').format(date);
  }

  String _formatDate(DateTime date) {
    return DateFormat('yyyy-MM-dd').format(date);
  }
}
