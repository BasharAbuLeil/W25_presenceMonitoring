import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import 'main.dart';
import 'session_data.dart';
import 'package:intl/intl.dart';

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
          style: Theme.of(context).appBarTheme.titleTextStyle
              ?? textTheme.titleLarge?.copyWith(color: colorScheme.onBackground),
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

                    return SingleChildScrollView(
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
                          columns: [
                            DataColumn(label: Text('Date')),
                            DataColumn(label: Text('Time')),
                            DataColumn(label: Text('ID')),
                            DataColumn(label: Text('Duration')),
                            DataColumn(label: Text('Activity')),
                            DataColumn(label: Text('Color')),
                            DataColumn(label: Text('Intensity')),
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
                                DataCell(Text('${data['intensity'] ?? 'N/A'}')),
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
