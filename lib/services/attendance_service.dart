// lib/services/attendance_service.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class AttendanceService {
  Future<void> addAttendanceRecord(
      String userId, String subject, String date, String status) async {
    try {
      // Get the current user
      User? user = FirebaseAuth.instance.currentUser;

      if (user != null) {
        // Reference to the user's document
        DocumentReference userDoc =
            FirebaseFirestore.instance.collection('users').doc(userId);

        // Reference to the sub-collection 'attendance'
        CollectionReference attendanceCollection =
            userDoc.collection('attendance');

        // Add a new attendance record
        await attendanceCollection.add({
          'subject': subject,
          'date': date,
          'status': status, // e.g., 'present' or 'absent'
        });

        print("Attendance record added successfully!");
      } else {
        print("No user is currently logged in.");
      }
    } catch (e) {
      print("Error adding attendance record: $e");
    }
  }
}
