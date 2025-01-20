import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AttendancePage extends StatefulWidget {
  final String userId;
  final String subjectName;

  AttendancePage({required this.userId, required this.subjectName});

  @override
  _AttendancePageState createState() => _AttendancePageState();
}

class _AttendancePageState extends State<AttendancePage> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Stream<List<Map<String, dynamic>>> _getAttendanceRecords() {
    return _firestore
        .collection('subjects')
        .where('name', isEqualTo: widget.subjectName)
        .snapshots()
        .asyncMap((subjectSnapshot) async {
      print('Fetching subjects with name: ${widget.subjectName}');

      if (subjectSnapshot.docs.isNotEmpty) {
        print('Subject found: ${subjectSnapshot.docs.first.id}');
        String subjectId = subjectSnapshot.docs.first.id;

        try {
          print('Fetching attendance for user: ${widget.userId}');
          QuerySnapshot attendanceSnapshot = await _firestore
              .collection('subjects')
              .doc(subjectId)
              .collection('attendance')
              .doc(widget.userId)
              .collection('dates')
              .get();

          print('Attendance records found: ${attendanceSnapshot.docs.length}');
          return attendanceSnapshot.docs.map((doc) {
            print(
                'Date: ${doc.id}, Status: ${doc['status']}, Timestamp: ${doc['timestamp']}');
            return {
              'date': doc.id,
              'status': doc['status'],
              'timestamp': doc['timestamp'],
            };
          }).toList();
        } catch (e) {
          print('Error fetching attendance: $e');
          return [];
        }
      } else {
        print('No subjects found with the name: ${widget.subjectName}');
        return [];
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Attendance for ${widget.subjectName}'),
        backgroundColor: Colors.orange[900], // Custom color for app bar
      ),
      body: StreamBuilder<List<Map<String, dynamic>>>(
        stream: _getAttendanceRecords(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            print('Stream error: ${snapshot.error}');
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.error, size: 50, color: Colors.red),
                  SizedBox(height: 10),
                  Text(
                    'Error loading attendance records.',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                  ),
                ],
              ),
            );
          }

          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            print('No attendance records found.');
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.history, size: 50, color: Colors.grey),
                  SizedBox(height: 10),
                  Text(
                    'No attendance records found.',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                  ),
                ],
              ),
            );
          }

          final attendanceRecords = snapshot.data!;

          print('Displaying ${attendanceRecords.length} attendance records.');
          return ListView.builder(
            itemCount: attendanceRecords.length,
            itemBuilder: (context, index) {
              final record = attendanceRecords[index];
              return Card(
                margin: EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                elevation: 3,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                child: ListTile(
                  contentPadding: EdgeInsets.all(16),
                  title: Text(
                    'Date: ${record['date']}',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                  ),
                  subtitle: Row(
                    children: [
                      Icon(
                        record['status'] == 'present'
                            ? Icons.check_circle
                            : Icons.cancel,
                        color: record['status'] == 'present'
                            ? Colors.green
                            : Colors.red,
                      ),
                      SizedBox(width: 8),
                      Text(
                        'Status: ${record['status']}',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: record['status'] == 'present'
                              ? Colors.green
                              : Colors.red,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
