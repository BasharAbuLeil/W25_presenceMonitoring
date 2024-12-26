import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'session_data.dart';
class AllTreatmentSessions extends StatefulWidget { // Rename the class
  final String userID;

  const AllTreatmentSessions({Key? key, required this.userID}) : super(key: key);

  @override
  _AllTreatmentSessionsState createState() => _AllTreatmentSessionsState(); // Also rename the State class accordingly
}

class _AllTreatmentSessionsState extends State<AllTreatmentSessions> { // Rename the State class
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black, // Dark background for the page
      appBar: AppBar(
        backgroundColor: Colors.grey[900],
        title: const Text('All Treatment Sessions'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // -- 1) Header showing ID --
            Row(
              children: [
                Text(
                  'ID: ${widget.userID}',
                  style: const TextStyle(color: Colors.white, fontSize: 16),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // -- 2) Sessions Table via StreamBuilder --
            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream: _firestore
                    .collection('users')
                    .doc(widget.userID)
                    .collection('sessions')
                // You can add .orderBy('date') or .orderBy('time') if desired
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
                        label: Text('Date', style: TextStyle(color: Colors.white)),
                      ),
                      DataColumn(
                        label: Text('Duration (min)', style: TextStyle(color: Colors.white)),
                      ),
                      DataColumn(
                        label: Text('Avg Activity (%)', style: TextStyle(color: Colors.white)),
                      ),
                      DataColumn(
                        label: Text('Color', style: TextStyle(color: Colors.white)),
                      ),
                      DataColumn(
                        label: Text('Intensity', style: TextStyle(color: Colors.white)),
                      ),
                      DataColumn(
                        label: Text('Relaxed (y/n)', style: TextStyle(color: Colors.white)),
                      ),
                      DataColumn(
                        label: Text('View', style: TextStyle(color: Colors.white)),
                      ),
                    ],
                    rows: sessionDocs.map((doc) {
                      final data = doc.data() as Map<String, dynamic>;

                      // Adjust these field names to match your Firestore structure
                      final date = data['date'] ?? 'N/A';
                      final duration = data['duration'] ?? 0;        // e.g. integer
                      final avgActivity = data['avgActivity'] ?? 0;  // e.g. integer or double
                      final color = data['color'] ?? 'N/A';
                      final intensity = data['intensity'] ?? 'N/A';
                      final bool relaxed = data['relaxed'] ?? false;
                      final relaxedStr = relaxed ? 'Y' : 'N';

                      // We might also store a 'time' field that we can pass to SessionDataPage
                      final time = data['time'] ?? 'N/A';

                      return DataRow(
                        cells: [
                          DataCell(Text('$date', style: const TextStyle(color: Colors.white))),
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
                                // Navigate to SessionDataPage with userID, date, time, etc.
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => SessionDataPage(
                                      userID: widget.userID,
                                      date: date,
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