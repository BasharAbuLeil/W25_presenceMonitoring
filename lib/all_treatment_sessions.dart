import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import 'main.dart';
import 'session_data.dart';
import 'package:intl/intl.dart';

class AllTreatmentSessionsPage extends StatefulWidget {
  final String userID;

  const AllTreatmentSessionsPage({Key? key, required this.userID}) : super(key: key);

  @override
  _AllTreatmentSessionsPageState createState() => _AllTreatmentSessionsPageState();
}

class _AllTreatmentSessionsPageState extends State<AllTreatmentSessionsPage> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context, listen: false);
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      backgroundColor: colorScheme.background,
      appBar: AppBar(
        backgroundColor: Theme.of(context).appBarTheme.backgroundColor,
        title: Text(
          'Treatment Sessions',
          style: Theme.of(context).appBarTheme.titleTextStyle
              ?? textTheme.titleLarge?.copyWith(color: colorScheme.onBackground),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Card(
              elevation: 2,
              color: colorScheme.surfaceVariant,
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 24.0, horizontal: 16.0),
                child: Column(
                  children: [
                    Text(
                      'Patient ID',
                      style: textTheme.titleMedium?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      widget.userID,
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
                      .where('userID', isEqualTo: widget.userID)
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
                            DataColumn(label: Text('Duration (min)')),
                            DataColumn(label: Text('Avg Activity (%)')),
                            DataColumn(label: Text('Color')),
                            DataColumn(label: Text('Intensity')),
                            DataColumn(label: Text('Relaxed')),
                            DataColumn(label: Text('View')),
                          ],
                          rows: sessionDocs.map((doc) {
                            final data = doc.data() as Map<String, dynamic>;
                            final Timestamp? dateTs = data['date'] as Timestamp?;
                            final dateString = dateTs != null
                                ? DateFormat('yyyy-MM-dd HH:mm').format(dateTs.toDate())
                                : 'N/A';

                            return DataRow(
                              cells: [
                                DataCell(Text(dateString)),
                                DataCell(Text('${data['duration'] ?? 0}')),
                                DataCell(Text('${data['avgActivity'] ?? 0}')),
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
}
