import 'package:cloud_firestore/cloud_firestore.dart';

class FirebaseService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Fetch the enrolled subjects for a user
  Future<List<String>> getEnrolledSubjects(String userId) async {
    try {
      DocumentSnapshot userDoc =
          await _firestore.collection('users').doc(userId).get();
      if (userDoc.exists) {
        List<String> subjects = List<String>.from(userDoc['subjects'] ?? []);
        return subjects;
      }
    } catch (e) {
      print('Error fetching enrolled subjects: $e');
    }
    return [];
  }

  // Fetch attendance records for a user in a given subject
  Future<List<Map<String, dynamic>>> getAttendanceRecords(
      String userId, String subjectName) async {
    try {
      QuerySnapshot attendanceSnapshot = await _firestore
          .collection('subjects')
          .where('name', isEqualTo: subjectName)
          .get();

      if (attendanceSnapshot.docs.isNotEmpty) {
        String subjectDocId = attendanceSnapshot.docs.first.id;
        QuerySnapshot attendanceRecords = await _firestore
            .collection('subjects')
            .doc(subjectDocId)
            .collection('attendance')
            .doc(userId)
            .collection('records')
            .get();

        List<Map<String, dynamic>> attendanceList = attendanceRecords.docs
            .map((doc) => {
                  'date': doc['attendanceDate'],
                  'status': doc['status'],
                })
            .toList();
        return attendanceList;
      }
    } catch (e) {
      print('Error fetching attendance records: $e');
    }
    return [];
  }
}
