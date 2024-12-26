import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class SessionDataPage extends StatefulWidget {
  final String userID;
  final String date; // add these if you need them
  final String time;
  const SessionDataPage({
    Key? key,
    required this.userID,
    required this.date,
    required this.time,
  }) : super(key: key);

  @override
  _SessionDataPageState createState() => _SessionDataPageState();
}

class _SessionDataPageState extends State<SessionDataPage> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black, // Dark background
      appBar: AppBar(
        title: const Text('Session Data'),
        backgroundColor: Colors.grey[900],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // -- 1) StreamBuilder to load user doc for date/time fields --
            StreamBuilder<DocumentSnapshot>(
              stream: _firestore
                  .collection('users')
                  .doc(widget.userID)
                  .snapshots(),
              builder: (context, userSnapshot) {
                if (userSnapshot.hasError) {
                  return const Text(
                    'Error loading user data',
                    style: TextStyle(color: Colors.red),
                  );
                }
                if (!userSnapshot.hasData || !userSnapshot.data!.exists) {
                  // Either loading or user doc doesn't exist
                  return const SizedBox.shrink();
                }

                final userData =
                userSnapshot.data!.data() as Map<String, dynamic>?;

                final userDate = userData?['date'] ;
                final userTime = userData?['time'] ;

                return Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'ID: ${widget.userID}',
                      style: const TextStyle(color: Colors.white, fontSize: 16),
                    ),
                    Text(
                      'Date: $userDate',
                      style: const TextStyle(color: Colors.white, fontSize: 16),
                    ),
                    Text(
                      'Time: $userTime',
                      style: const TextStyle(color: Colors.white, fontSize: 16),
                    ),
                  ],
                );
              },
            ),
            const SizedBox(height: 16),

            // -- 2) StreamBuilder to load session docs in a DataTable --
            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream: _firestore
                    .collection('users')
                    .doc(widget.userID)
                    .collection('sessions')
                // Example sorting by 'time' ascending
                //.orderBy('time', descending: false)
                    .snapshots(),
                builder: (context, snapshot) {
                  if (snapshot.hasError) {
                    return const Text(
                      'Error fetching session data',
                      style: TextStyle(color: Colors.red),
                    );
                  }
                  if (!snapshot.hasData) {
                    return const Center(
                      child: CircularProgressIndicator(),
                    );
                  }

                  final sessionDocs = snapshot.data!.docs;

                  // Build the DataTable
                  return DataTable(
                    headingRowColor: MaterialStateColor.resolveWith(
                          (states) => Colors.grey[900]!,
                    ),
                    dataRowColor: MaterialStateColor.resolveWith(
                          (states) => Colors.grey[850]!,
                    ),
                    columnSpacing: 24,
                    columns: const [
                      DataColumn(
                        label: Text(
                          'Time',
                          style: TextStyle(color: Colors.white),
                        ),
                      ),
                      DataColumn(
                        label: Text(
                          'Activity (%)',
                          style: TextStyle(color: Colors.white),
                        ),
                      ),
                      DataColumn(
                        label: Text(
                          'Color',
                          style: TextStyle(color: Colors.white),
                        ),
                      ),
                      DataColumn(
                        label: Text(
                          'Intensity',
                          style: TextStyle(color: Colors.white),
                        ),
                      ),
                      DataColumn(
                        label: Text(
                          'Relaxed (y/n)',
                          style: TextStyle(color: Colors.white),
                        ),
                      ),
                    ],
                    rows: sessionDocs.map((doc) {
                      final data = doc.data() as Map<String, dynamic>;

                      final time = data['time'] ?? 'N/A';
                      final activity = data['activity'] ?? 0; // int or double
                      final color = data['color'] ?? 'N/A';
                      final intensity = data['intensity'] ?? 'N/A';
                      final bool isRelaxed = data['relaxed'] ?? false;

                      final relaxedStr = isRelaxed ? 'Y' : 'N';

                      return DataRow(
                        cells: [
                          DataCell(Text(
                            time.toString(),
                            style: const TextStyle(color: Colors.white),
                          )),
                          DataCell(Text(
                            activity.toString(),
                            style: const TextStyle(color: Colors.white),
                          )),
                          DataCell(Text(
                            color.toString(),
                            style: const TextStyle(color: Colors.white),
                          )),
                          DataCell(Text(
                            intensity.toString(),
                            style: const TextStyle(color: Colors.white),
                          )),
                          DataCell(Text(
                            relaxedStr,
                            style: const TextStyle(color: Colors.white),
                          )),
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
