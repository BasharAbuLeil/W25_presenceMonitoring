import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import 'main.dart';
import 'all_treatment_sessions.dart';
import 'global_history.dart';

class IDLoginPage extends StatefulWidget {
  const IDLoginPage({Key? key}) : super(key: key);

  @override
  _IDLoginPageState createState() => _IDLoginPageState();
}

class _IDLoginPageState extends State<IDLoginPage> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final TextEditingController _idController = TextEditingController();
  final TextEditingController _yearController = TextEditingController();
  final TextEditingController _monthController = TextEditingController();
  final TextEditingController _dayController = TextEditingController();
  final TextEditingController _startYearController = TextEditingController();
  final TextEditingController _startMonthController = TextEditingController();
  final TextEditingController _startDayController = TextEditingController();
  final TextEditingController _endYearController = TextEditingController();
  final TextEditingController _endMonthController = TextEditingController();
  final TextEditingController _endDayController = TextEditingController();
  bool _useRange = false;

  @override
  void dispose() {
    _idController.dispose();
    _yearController.dispose();
    _monthController.dispose();
    _dayController.dispose();
    _startYearController.dispose();
    _startMonthController.dispose();
    _startDayController.dispose();
    _endYearController.dispose();
    _endMonthController.dispose();
    _endDayController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      backgroundColor: colorScheme.background,
      appBar: AppBar(
        backgroundColor: colorScheme.surface,
        elevation: 0,
        title: Text(
          'ID & Date Lookup',
          style: textTheme.headlineSmall?.copyWith(color: colorScheme.onSurface),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 400),
            child: Column(
              children: [
                // ID Search Section
                Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    TextField(
                      controller: _idController,
                      style: TextStyle(color: colorScheme.onSurface, fontSize: 14),
                      decoration: InputDecoration(
                        labelText: 'Enter ID (6 digits)',
                        labelStyle: TextStyle(
                          color: colorScheme.onSurface.withOpacity(0.7),
                          fontSize: 14,
                        ),
                        filled: true,
                        fillColor: colorScheme.surfaceVariant,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                        prefixIcon: Icon(
                          Icons.perm_identity,
                          size: 20,
                          color: colorScheme.onSurface.withOpacity(0.7),
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    ElevatedButton(
                      onPressed: _handleIDSearch,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.accentColor,
                        foregroundColor: colorScheme.onSecondary,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text(
                        'Search ID',
                        style: TextStyle(fontSize: 14),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 24),

                // Date Toggle
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  decoration: BoxDecoration(
                    color: colorScheme.surfaceVariant,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Switch(
                        value: _useRange,
                        onChanged: (val) => setState(() => _useRange = val),
                        activeColor: AppTheme.accentColor,
                      ),
                      Text(
                        _useRange ? 'Searching by Date Range' : 'Searching by Single Date',
                        style: TextStyle(
                          color: colorScheme.onSurface.withOpacity(0.7),
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 16),

                // Date Fields
                if (!_useRange)
                  _buildSingleDateFields(colorScheme)
                else
                  _buildRangeDateFields(colorScheme),

                const SizedBox(height: 16),

                // Show History Button
                ElevatedButton(
                  onPressed: _handleDateHistory,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.accentColor,
                    foregroundColor: colorScheme.onSecondary,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    minimumSize: const Size.fromHeight(40),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Text(
                    _useRange ? 'Show Range History' : 'Show History',
                    style: const TextStyle(fontSize: 14),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDateField({
    required TextEditingController controller,
    required String hintText,
    required IconData icon,
    required ColorScheme colorScheme,
  }) {
    return TextField(
      controller: controller,
      style: TextStyle(color: colorScheme.onSurface, fontSize: 14),
      keyboardType: TextInputType.number,
      decoration: InputDecoration(
        hintText: hintText,
        hintStyle: TextStyle(
          color: colorScheme.onSurface.withOpacity(0.5),
          fontSize: 14,
        ),
        filled: true,
        fillColor: colorScheme.surfaceVariant,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 12,
          vertical: 12,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        prefixIcon: Icon(
          icon,
          color: colorScheme.onSurface.withOpacity(0.7),
          size: 20,
        ),
      ),
    );
  }

  Widget _buildSingleDateFields(ColorScheme colorScheme) {
    return Row(
      children: [
        Expanded(
          child: _buildDateField(
            controller: _yearController,
            hintText: 'YYYY',
            icon: Icons.calendar_month,
            colorScheme: colorScheme,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _buildDateField(
            controller: _monthController,
            hintText: 'MM',
            icon: Icons.calendar_today,
            colorScheme: colorScheme,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _buildDateField(
            controller: _dayController,
            hintText: 'DD',
            icon: Icons.today,
            colorScheme: colorScheme,
          ),
        ),
      ],
    );
  }

  Widget _buildRangeDateFields(ColorScheme colorScheme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Start Date',
          style: TextStyle(
            color: colorScheme.onSurface.withOpacity(0.7),
            fontSize: 14,
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: _buildDateField(
                controller: _startYearController,
                hintText: 'YYYY',
                icon: Icons.calendar_month,
                colorScheme: colorScheme,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _buildDateField(
                controller: _startMonthController,
                hintText: 'MM',
                icon: Icons.calendar_today,
                colorScheme: colorScheme,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _buildDateField(
                controller: _startDayController,
                hintText: 'DD',
                icon: Icons.today,
                colorScheme: colorScheme,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Text(
          'End Date',
          style: TextStyle(
            color: colorScheme.onSurface.withOpacity(0.7),
            fontSize: 14,
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: _buildDateField(
                controller: _endYearController,
                hintText: 'YYYY',
                icon: Icons.calendar_month,
                colorScheme: colorScheme,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _buildDateField(
                controller: _endMonthController,
                hintText: 'MM',
                icon: Icons.calendar_today,
                colorScheme: colorScheme,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _buildDateField(
                controller: _endDayController,
                hintText: 'DD',
                icon: Icons.today,
                colorScheme: colorScheme,
              ),
            ),
          ],
        ),
      ],
    );
  }
  // --------------------------------------------------------------------------
  //  Handlers
  // --------------------------------------------------------------------------

  Future<void> _handleIDSearch() async {
    final enteredID = _idController.text.trim();
    if (enteredID.isEmpty) {
      _showErrorDialog('Please enter an ID.');
      return;
    }

    try {
      final docSnap = await _firestore.collection('users').doc(enteredID).get();
      if (!docSnap.exists) {
        _showErrorDialog('No user found with ID: $enteredID');
        return;
      }

      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => AllTreatmentSessionsPage(userID: enteredID),
        ),
      );
    } catch (e) {
      _showErrorDialog('Error searching ID: $e');
    }
  }

  Future<void> _handleDateHistory() async {
    if (!_useRange) {
      // SINGLE DATE
      final dt = _validateSingleDate();
      if (dt == null) return;

      // Expand single dt -> dtStart..dtEnd
      final dtStart = DateTime(dt.year, dt.month, dt.day, 0, 0, 0);
      final dtEnd   = DateTime(dt.year, dt.month, dt.day, 23, 59, 59);

      try {
        // Query to see if any docs exist for that date
        final querySnap = await _firestore
            .collection('sessions')
            .where('date', isGreaterThanOrEqualTo: Timestamp.fromDate(dtStart))
            .where('date', isLessThanOrEqualTo: Timestamp.fromDate(dtEnd))
            .get();

        if (querySnap.docs.isEmpty) {
          _showErrorDialog('No data found for ${_formatDate(dt)}');
        } else {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => GlobalHistoryPage(
                startDate: dtStart,
                endDate: dtEnd,
              ),
            ),
          );
        }
      } catch (e) {
        _showErrorDialog('Error searching date: $e');
      }
    } else {
      // RANGE
      final startDt = _validateRangeDate(
        _startYearController.text.trim(),
        _startMonthController.text.trim(),
        _startDayController.text.trim(),
        isStart: true,
      );
      if (startDt == null) return;

      final endDt = _validateRangeDate(
        _endYearController.text.trim(),
        _endMonthController.text.trim(),
        _endDayController.text.trim(),
        isStart: false,
      );
      if (endDt == null) return;

      if (endDt.isBefore(startDt)) {
        _showErrorDialog('End date cannot be before the start date.');
        return;
      }

      try {
        final querySnap = await _firestore
            .collection('sessions')
            .where('date', isGreaterThanOrEqualTo: Timestamp.fromDate(startDt))
            .where('date', isLessThanOrEqualTo: Timestamp.fromDate(endDt))
            .get();

        if (querySnap.docs.isEmpty) {
          _showErrorDialog(
            'No data found for the range '
                '${_formatDate(startDt)} - ${_formatDate(endDt)}',
          );
        } else {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => GlobalHistoryPage(
                startDate: startDt,
                endDate: endDt,
              ),
            ),
          );
        }
      } catch (e) {
        _showErrorDialog('Error searching date range: $e');
      }
    }
  }

  DateTime? _validateSingleDate() {
    final y = _yearController.text.trim();
    final m = _monthController.text.trim();
    final d = _dayController.text.trim();
    if (y.isEmpty || m.isEmpty || d.isEmpty) {
      _showErrorDialog('Please enter year, month, and day.');
      return null;
    }
    final year = int.tryParse(y);
    final month = int.tryParse(m);
    final day = int.tryParse(d);
    if (year == null || month == null || day == null) {
      _showErrorDialog('Year, month, and day must be valid integers.');
      return null;
    }
    try {
      final dt = DateTime(year, month, day);
      if (dt.isAfter(DateTime.now())) {
        _showErrorDialog('Date cannot be in the future.');
        return null;
      }
      return dt;
    } catch (_) {
      _showErrorDialog('Invalid date. Please check values again.');
      return null;
    }
  }

  DateTime? _validateRangeDate(String y, String m, String d, {required bool isStart}) {
    if (y.isEmpty || m.isEmpty || d.isEmpty) {
      _showErrorDialog(
        isStart ? 'Please enter a valid start date.' : 'Please enter a valid end date.',
      );
      return null;
    }
    final year = int.tryParse(y);
    final month = int.tryParse(m);
    final day = int.tryParse(d);
    if (year == null || month == null || day == null) {
      _showErrorDialog(
        isStart
            ? 'Start date must be valid integers.'
            : 'End date must be valid integers.',
      );
      return null;
    }
    try {
      final dt = DateTime(year, month, day);
      if (dt.isAfter(DateTime.now())) {
        _showErrorDialog('Date cannot be in the future.');
        return null;
      }
      return dt;
    } catch (_) {
      _showErrorDialog(isStart ? 'Invalid start date.' : 'Invalid end date.');
      return null;
    }
  }

  // --------------------------------------------------------------------------
  //  Dialog Helpers
  // --------------------------------------------------------------------------
  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: Theme.of(context).colorScheme.surface,
        title: Text(
          'Error',
          style: TextStyle(color: Theme.of(context).colorScheme.onErrorContainer),
        ),
        content: Text(
          message,
          style: TextStyle(color: Theme.of(context).colorScheme.onSurface),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text('OK', style: TextStyle(color: AppTheme.accentColor)),
          ),
        ],
      ),
    );
  }

  // Formats a DateTime as YYYY-MM-DD
  String _formatDate(DateTime dt) {
    final y = dt.year.toString().padLeft(4, '0');
    final m = dt.month.toString().padLeft(2, '0');
    final d = dt.day.toString().padLeft(2, '0');
    return '$y-$m-$d';
  }
}
