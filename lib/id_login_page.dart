import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'session_data.dart'; // Import the session data page
import 'all_treatment_sessions.dart'; // Import the all_treatment_sessions page
import 'global_history.dart'; // Import the global_history page

class IDLoginPage extends StatefulWidget {
  const IDLoginPage({Key? key}) : super(key: key);

  @override
  _IDLoginPageState createState() => _IDLoginPageState();
}

class _IDLoginPageState extends State<IDLoginPage> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Controllers for ID search
  final TextEditingController _idController = TextEditingController();

  // Separate controllers for year, month, day
  final TextEditingController _yearController = TextEditingController();
  final TextEditingController _monthController = TextEditingController();
  final TextEditingController _dayController = TextEditingController();

  late final int _currentYear;

  @override
  void initState() {
    super.initState();
    _currentYear = DateTime.now().year;
  }

  @override
  void dispose() {
    _idController.dispose();
    _yearController.dispose();
    _monthController.dispose();
    _dayController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    const Color kOrangeColor = Color(0xFFFF6E40);

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.grey[900],
        elevation: 0,
        title: const Text(
          'ID & Date Lookup',
          style: TextStyle(color: Colors.white),
        ),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // ------------------- ID Search Section -------------------
              TextField(
                controller: _idController,
                style: const TextStyle(color: Colors.white),
                keyboardType: TextInputType.text,
                decoration: InputDecoration(
                  labelText: 'Enter ID',
                  labelStyle: const TextStyle(color: Colors.white70),
                  filled: true,
                  fillColor: Colors.grey[850],
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: kOrangeColor),
                  ),
                  prefixIcon: const Icon(Icons.perm_identity, color: Colors.white70),
                ),
              ),
              const SizedBox(height: 16.0),

              ElevatedButton(
                onPressed: _handleIDSearch,
                style: ElevatedButton.styleFrom(
                  backgroundColor: kOrangeColor,
                  foregroundColor: Colors.black,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 16.0),
                ),
                child: const Text('Search ID'),
              ),

              const SizedBox(height: 30.0),

              // ------------------- Date History Section -------------------
              Row(
                children: [
                  Expanded(
                    child: _buildDateField(
                      controller: _yearController,
                      hintText: 'YYYY',
                      icon: Icons.calendar_month,
                      kOrangeColor: kOrangeColor,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _buildDateField(
                      controller: _monthController,
                      hintText: 'MM',
                      icon: Icons.calendar_today,
                      kOrangeColor: kOrangeColor,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _buildDateField(
                      controller: _dayController,
                      hintText: 'DD',
                      icon: Icons.today,
                      kOrangeColor: kOrangeColor,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 16.0),

              ElevatedButton(
                onPressed: _handleDateHistory,
                style: ElevatedButton.styleFrom(
                  backgroundColor: kOrangeColor,
                  foregroundColor: Colors.black,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 16.0),
                ),
                child: const Text('Show History'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDateField({
    required TextEditingController controller,
    required String hintText,
    required IconData icon,
    required Color kOrangeColor,
  }) {
    return TextField(
      controller: controller,
      style: const TextStyle(color: Colors.white),
      keyboardType: TextInputType.number,
      decoration: InputDecoration(
        hintText: hintText,
        hintStyle: const TextStyle(color: Colors.white54),
        filled: true,
        fillColor: Colors.grey[850],
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: kOrangeColor),
        ),
        prefixIcon: Icon(icon, color: Colors.white70),
      ),
    );
  }

  Future<void> _handleIDSearch() async {
    final enteredID = _idController.text.trim();
    if (enteredID.isEmpty) {
      _showErrorDialog('Please enter an ID.');
      return;
    }

    try {
      final DocumentSnapshot userDoc =
      await _firestore.collection('users').doc(enteredID).get();

      if (userDoc.exists) {
        // Navigate to AllTreatmentSessions page
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => AllTreatmentSessions(userID: enteredID), // Pass the userID
          ),
        );
      } else {
        _showErrorDialog('ID "$enteredID" not found in Firestore.');
      }
    } catch (e) {
      _showErrorDialog('Error searching ID: $e');
    }
  }

  Future<void> _handleDateHistory() async {
    final yearStr = _yearController.text.trim();
    final monthStr = _monthController.text.trim();
    final dayStr = _dayController.text.trim();

    if (yearStr.isEmpty || monthStr.isEmpty || dayStr.isEmpty) {
      _showErrorDialog('Please enter year, month, and day.');
      return;
    }

    int? year = int.tryParse(yearStr);
    int? month = int.tryParse(monthStr);
    int? day = int.tryParse(dayStr);

    if (year == null || month == null || day == null) {
      _showErrorDialog('Year, month, and day must be numbers.');
      return;
    }

    DateTime? dateObj;
    try {
      dateObj = DateTime(year, month, day);
      if (dateObj.isAfter(DateTime.now())) {
        _showErrorDialog('Date cannot be in the future.');
        return;
      }
    } catch (_) {
      _showErrorDialog('Invalid date.');
      return;
    }

    final dateString = '${year.toString().padLeft(4, '0')}-'
        '${month.toString().padLeft(2, '0')}-'
        '${day.toString().padLeft(2, '0')}';

    try {
      final DocumentSnapshot dateDoc =
      await _firestore.collection('dates').doc(dateString).get();

      if (dateDoc.exists) { // Crucial check for successful date search
        // Navigate to GlobalHistoryPage, passing the dateString
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => GlobalHistoryPage(dateString: dateString),
          ),
        );
      } else {
        _showErrorDialog('No records found for $dateString.');
      }
    } catch (e) {
      _showErrorDialog('Error retrieving date history: $e');
    }
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: Colors.grey[800],
        title: const Text('Error', style: TextStyle(color: Colors.white)),
        content: Text(message, style: const TextStyle(color: Colors.white)),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('OK', style: TextStyle(color: Colors.orangeAccent)),
          ),
        ],
      ),
    );
  }

  void _showDateDataDialog(String date, Map<String, dynamic> data) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: Colors.grey[800],
        title: Text(
          'History for $date',
          style: const TextStyle(color: Colors.white),
        ),
        content: SingleChildScrollView(
          child: Text(
            data.toString(),
            style: const TextStyle(color: Colors.white),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('OK', style: TextStyle(color: Colors.orangeAccent)),
          ),
        ],
      ),
    );
  }
}