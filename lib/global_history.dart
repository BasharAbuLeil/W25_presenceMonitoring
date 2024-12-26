import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'session_data.dart'; // The page to show individual session details

class GlobalHistoryPage extends StatefulWidget {
  final String dateString; // e.g., "2025-07-15"

  const GlobalHistoryPage({Key? key, required this.dateString}) : super(key: key);

  @override
  _GlobalHistoryPageState createState() => _GlobalHistoryPageState();
}

class _GlobalHistoryPageState extends State<GlobalHistoryPage> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black, // Dark background
      appBar: AppBar(
        title: const Text('Global History'),
        backgroundColor: Colors.grey[900],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // -- 1) Header with the date --
            Row(
              children: [
                Text(
                  'Date: ${widget.dateString}',
                  style: const TextStyle(color: Colors.white, fontSize: 16),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // -- 2) Table of sessions for this date --
            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream: _firestore
                    .collection('dates')
                    .doc(widget.dateString)
                    .collection('sessions')
                // If you store all sessions under "dates/{dateString}/sessions"
                // you can also .orderBy('time') if needed:
                //.orderBy('time')
                    .snapshots(),
                builder: (context, snapshot) {
                  if (snapshot.hasError) {
                    return const Text(
                      'Error loading sessions',
                      style: TextStyle(color: Colors.red),
                    );
                  }
                  if (!snapshot.hasData) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  final sessionDocs = snapshot.data!.docs;

                  // Build DataTable
                  return DataTable(
                    headingRowColor: MaterialStateColor.resolveWith(
                          (states) => Colors.grey[900]!,
                    ),
                    dataRowColor: MaterialStateColor.resolveWith(
                          (states) => Colors.grey[850]!,
                    ),
                    columnSpacing: 16,
                    columns: const [
                      DataColumn(
                        label: Text('Time', style: TextStyle(color: Colors.white)),
                      ),
                      DataColumn(
                        label: Text('ID', style: TextStyle(color: Colors.white)),
                      ),
                      DataColumn(
                        label: Text('Duration(min)', style: TextStyle(color: Colors.white)),
                      ),
                      DataColumn(
                        label: Text('Avg Activity(%)', style: TextStyle(color: Colors.white)),
                      ),
                      DataColumn(
                        label: Text('Color', style: TextStyle(color: Colors.white)),
                      ),
                      DataColumn(
                        label: Text('Intensity', style: TextStyle(color: Colors.white)),
                      ),
                      DataColumn(
                        label: Text('Relaxed(y/n)', style: TextStyle(color: Colors.white)),
                      ),
                      DataColumn(
                        label: Text('View', style: TextStyle(color: Colors.white)),
                      ),
                    ],
                    rows: sessionDocs.map((doc) {
                      final data = doc.data() as Map<String, dynamic>;

                      // Firestore fields
                      final time = data['time'] ?? 'N/A';
                      final userID = data['userID'] ?? 'N/A';
                      final duration = data['duration'] ?? 0;
                      final avgActivity = data['avgActivity'] ?? 0;
                      final color = data['color'] ?? 'N/A';
                      final intensity = data['intensity'] ?? 'N/A';
                      final bool relaxed = data['relaxed'] ?? false;
                      final relaxedStr = relaxed ? 'Y' : 'N';

                      return DataRow(
                        cells: [
                          DataCell(Text('$time', style: const TextStyle(color: Colors.white))),
                          DataCell(Text('$userID', style: const TextStyle(color: Colors.white))),
                          DataCell(Text('$duration', style: const TextStyle(color: Colors.white))),
                          DataCell(Text('$avgActivity', style: const TextStyle(color: Colors.white))),
                          DataCell(Text('$color', style: const TextStyle(color: Colors.white))),
                          DataCell(Text('$intensity', style: const TextStyle(color: Colors.white))),
                          DataCell(Text(relaxedStr, style: const TextStyle(color: Colors.white))),
                          DataCell(
                            ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.orangeAccent,
                              ),
                              onPressed: () {
                                // Navigate to SessionDataPage with date/time/id
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => SessionDataPage(
                                      userID: userID,
                                      date: widget.dateString,
                                      time: time,
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
