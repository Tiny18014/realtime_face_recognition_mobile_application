import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AttendancePage extends StatefulWidget {
  final String subjectId;

  AttendancePage({required this.subjectId});

  @override
  _AttendancePageState createState() => _AttendancePageState();
}

class _AttendancePageState extends State<AttendancePage> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<Map<String, dynamic>> _fetchStudentData(String studentId) async {
    final userDoc = await _firestore.collection('users').doc(studentId).get();
    if (userDoc.exists) {
      return userDoc.data()!;
    }
    return {'name': 'Unknown'};
  }

  Future<Map<String, dynamic>> _getAttendanceStats(String studentId) async {
    final attendanceSnapshot = await _firestore
        .collection('subjects')
        .doc(widget.subjectId)
        .collection('attendance')
        .doc(studentId)
        .collection('dates')
        .get();

    final totalClasses = attendanceSnapshot.docs.length;
    final attendedClasses = attendanceSnapshot.docs
        .where((doc) => doc['status'] == 'present')
        .length;

    return {
      'totalClasses': totalClasses,
      'attendedClasses': attendedClasses,
    };
  }

  Future<List<Map<String, dynamic>>> _getStudentsWithAttendance() async {
    final subjectSnapshot =
    await _firestore.collection('subjects').doc(widget.subjectId).get();

    if (!subjectSnapshot.exists || subjectSnapshot['students'] == null) {
      return [];
    }

    final students = List<String>.from(subjectSnapshot['students']);
    List<Map<String, dynamic>> studentDetails = [];

    for (final studentId in students) {
      final studentData = await _fetchStudentData(studentId);
      final attendanceStats = await _getAttendanceStats(studentId);

      studentDetails.add({
        'id': studentId,
        'name': studentData['name'] ?? 'Unknown',
        'totalClasses': attendanceStats['totalClasses'],
        'attendedClasses': attendanceStats['attendedClasses'],
      });
    }

    return studentDetails;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Mark Attendance'),
        backgroundColor: Colors.orange[900],
      ),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: _getStudentsWithAttendance(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(child: Text('Error loading student data'));
          }

          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return Center(child: Text('No students found'));
          }

          final students = snapshot.data!;

          return ListView.builder(
            itemCount: students.length,
            itemBuilder: (context, index) {
              final student = students[index];

              return ListTile(
                title: Text(student['name']),
                subtitle: Text(
                    'Attendance: ${student['attendedClasses']}/${student['totalClasses']}'),
                trailing: IconButton(
                  icon: Icon(Icons.check_circle),
                  onPressed: () {
                    _markAttendance(student['id']);
                  },
                ),
              );
            },
          );
        },
      ),
    );
  }

  Future<void> _markAttendance(String studentId) async {
    final DateTime currentDate = DateTime.now();
    final formattedDate =
        "${currentDate.year}-${currentDate.month.toString().padLeft(2, '0')}-${currentDate.day.toString().padLeft(2, '0')}";

    try {
      await _firestore
          .collection('subjects')
          .doc(widget.subjectId)
          .collection('attendance')
          .doc(studentId)
          .collection('dates')
          .doc(formattedDate)
          .set({
        'status': 'present',
        'timestamp': Timestamp.fromDate(currentDate),
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Attendance marked as present')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to mark attendance: $e')),
      );
    }
  }
}
