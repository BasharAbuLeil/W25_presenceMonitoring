import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import 'main.dart';
import 'package:intl/intl.dart';

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

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      backgroundColor: colorScheme.background,
      appBar: AppBar(
        title: Text(
          'Session Details',
          style: Theme.of(context).appBarTheme.titleTextStyle?.copyWith(color: colorScheme.onBackground),
        ),
        backgroundColor: Theme.of(context).appBarTheme.backgroundColor,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            StreamBuilder<DocumentSnapshot>(
              stream: _firestore
                  .collection('sessions')
                  .doc(widget.sessionDocID)
                  .snapshots(),
              builder: (context, sessionSnapshot) {
                if (sessionSnapshot.hasError) {
                  return Text(
                    'Error loading session data',
                    style: textTheme.bodyMedium?.copyWith(color: colorScheme.error),
                  );
                }
                if (!sessionSnapshot.hasData || !sessionSnapshot.data!.exists) {
                  return const SizedBox.shrink();
                }

                final sessionData = sessionSnapshot.data!.data() as Map<String, dynamic>?;
                final Timestamp? dateTs = sessionData?['date'];
                String dateTimeString = 'N/A';
                if (dateTs != null) {
                  dateTimeString = DateFormat('yyyy-MM-dd HH:mm').format(dateTs.toDate());
                }

                return Card(
                  elevation: 2,
                  color: colorScheme.surfaceVariant,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 24.0, horizontal: 16.0),
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
                              sessionData?['relaxed'] == true ? 'Relaxed' : 'Active',
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
            Expanded(
              child: Card(
                elevation: 1,
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
                          'Error fetching minute logs',
                          style: textTheme.bodyMedium?.copyWith(color: colorScheme.error),
                        ),
                      );
                    }
                    if (!snapshot.hasData) {
                      return const Center(child: CircularProgressIndicator());
                    }

                    final minuteDocs = snapshot.data!.docs;

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
                            DataColumn(label: Text('Minute')),
                            DataColumn(label: Text('Color')),
                            DataColumn(label: Text('Intensity')),
                            DataColumn(label: Text('Activity')),
                            DataColumn(label: Text('Relaxed')),
                          ],
                          rows: minuteDocs.map((doc) {
                            final logData = doc.data() as Map<String, dynamic>;

                            return DataRow(cells: [
                              DataCell(Text('${logData['minuteIndex'] ?? 0}')),
                              DataCell(Text('${logData['color'] ?? 'N/A'}')),
                              DataCell(Text('${logData['intensity'] ?? 'N/A'}')),
                              DataCell(Text('${logData['activity'] ?? 0}%')),
                              DataCell(Text(logData['relaxed'] == true ? 'Yes' : 'No')),
                            ]);
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

  Widget _buildInfoCard(String label, String value, TextTheme textTheme, ColorScheme colorScheme) {
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
}
