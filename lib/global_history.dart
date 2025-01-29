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
  final TextEditingController _searchController = TextEditingController();
  String _searchId = '';

  late DateTime _expandedStart;
  late DateTime _expandedEnd;
  bool get _isSingleDay => widget.startDate.year == widget.endDate.year
      && widget.startDate.month == widget.endDate.month
      && widget.startDate.day == widget.endDate.day;

  @override
  void initState() {
    super.initState();
    _expandedStart = DateTime(
        widget.startDate.year,
        widget.startDate.month,
        widget.startDate.day,
        0, 0, 0
    );

    _expandedEnd = DateTime(
        widget.endDate.year,
        widget.endDate.month,
        widget.endDate.day,
        23, 59, 59, 999
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _exportToCsv(List<QueryDocumentSnapshot> sessionDocs) {
    try {
      List<List<dynamic>> rows = [
        [_isSingleDay ? 'Date: ${_formatDate(_expandedStart)}' :
        'Date Range: ${_formatDate(_expandedStart)} - ${_formatDate(_expandedEnd)}'],
        [],
        ['Date and Time', 'Patient ID', 'Duration (min)', 'Activity (%)', 'Color', 'Relaxed']
      ];

      for (var doc in sessionDocs) {
        final data = doc.data() as Map<String, dynamic>;
        final Timestamp? dateTs = data['date'];
        final duration = num.tryParse('${data['duration'] ?? 0}') ?? 0;
        final activity = num.tryParse('${data['avgActivity'] ?? 0}') ?? 0;

        rows.add([
          _formatDateTime(dateTs),
          data['userID'] ?? 'N/A',
          duration.toString(),
          activity.toString(),
          data['color'] ?? 'N/A',
          activity > 60 ? 'No' : 'Yes',
        ]);
      }

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

      rows.add([]);
      rows.add(['Summary Statistics']);
      rows.add(['Total Sessions', sessionDocs.length.toString()]);
      rows.add(['Average Duration', '${avgDuration.toStringAsFixed(1)} min']);
      rows.add(['Average Activity', '${avgActivity.toStringAsFixed(1)}%']);

      String csvData = const ListToCsvConverter().convert(rows);
      final bytes = utf8.encode(csvData);
      final blob = html.Blob([bytes]);
      final url = html.Url.createObjectUrlFromBlob(blob);

      final fileName = _isSingleDay
          ? 'treatment_history_${_formatDate(_expandedStart)}.csv'
          : 'treatment_history_${_formatDate(_expandedStart)}_to_${_formatDate(_expandedEnd)}.csv';

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
            Row(
              children: [
                Expanded(
                  child: Card(
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
                ),
                const SizedBox(width: 16),
                Card(
                  elevation: 2,
                  color: colorScheme.surfaceVariant,
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Search Patient',
                          style: textTheme.titleMedium?.copyWith(
                            color: colorScheme.onSurfaceVariant,
                          ),
                        ),
                        const SizedBox(height: 8),
                        SizedBox(
                          width: 300,
                          child: TextField(
                            controller: _searchController,
                            decoration: InputDecoration(
                              hintText: 'Enter Patient ID',
                              hintStyle: TextStyle(
                                color: colorScheme.onSurfaceVariant.withOpacity(0.7),
                              ),
                              prefixIcon: Icon(
                                Icons.search,
                                color: colorScheme.onSurfaceVariant,
                              ),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide(
                                  color: colorScheme.outline,
                                ),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide(
                                  color: colorScheme.outline.withOpacity(0.5),
                                ),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide(
                                  color: AppTheme.accentColor,
                                  width: 2,
                                ),
                              ),
                              filled: true,
                              fillColor: colorScheme.surface,
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 12,
                              ),
                              suffixIcon: _searchId.isNotEmpty
                                  ? IconButton(
                                icon: Icon(
                                  Icons.clear,
                                  color: colorScheme.onSurfaceVariant,
                                ),
                                onPressed: () {
                                  setState(() {
                                    _searchController.clear();
                                    _searchId = '';
                                  });
                                },
                              )
                                  : null,
                            ),
                            style: textTheme.bodyLarge?.copyWith(
                              color: colorScheme.onSurface,
                            ),
                            onChanged: (value) {
                              setState(() {
                                _searchId = value.trim();
                              });
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
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
                    final filteredDocs = _searchId.isEmpty
                        ? sessionDocs
                        : sessionDocs.where((doc) {
                      final data = doc.data() as Map<String, dynamic>;
                      return data['userID']?.toString().toLowerCase()
                          .contains(_searchId.toLowerCase()) ?? false;
                    }).toList();

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
                                  DataColumn(label: Text('Date and Time')),
                                  DataColumn(label: Text('ID')),
                                  DataColumn(label: Text('Duration')),
                                  DataColumn(label: Text('Activity')),
                                  DataColumn(label: Text('Color')),
                                  DataColumn(label: Text('Relaxed')),
                                  DataColumn(label: Text('View')),
                                ],
                                rows: filteredDocs.map((doc) {
                                  final data = doc.data() as Map<String, dynamic>;
                                  final Timestamp? dateTs = data['date'];

                                  return DataRow(
                                    cells: [
                                      DataCell(Text(_formatDateTime(dateTs))),
                                      DataCell(Text('${data['userID'] ?? 'N/A'}')),
                                      DataCell(Text('${data['duration'] ?? 0} min')),
                                      DataCell(Text('${data['avgActivity'] ?? 0}%')),
                                      DataCell(Text('${data['color'] ?? 'N/A'}')),
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
                        const SizedBox(height: 16),
                        SizedBox(
                          width: 180,
                          child: ElevatedButton.icon(
                            onPressed: () => _exportToCsv(filteredDocs),
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

  String _formatDateTime(Timestamp? ts) {
    if (ts == null) return 'N/A';
    return DateFormat('yyyy-MM-dd HH:mm').format(ts.toDate());
  }

  String _formatDate(DateTime date) {
    return DateFormat('yyyy-MM-dd').format(date);
  }
}
