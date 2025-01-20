import 'package:cloud_firestore/cloud_firestore.dart';

class FirestoreService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  Future<void> createUserProfile(
      String userId, String name, String email, String role,
      {String? rollNumber, List<String>? subjectsTaught}) async {
    await _db.collection('users').doc(userId).set({
      'name': name,
      'email': email,
      'role': role,
      'rollNumber': rollNumber,
      'subjectsTaught': subjectsTaught ?? [],
    });
  }

  Future<DocumentSnapshot> getUserProfile(String userId) async {
    return await _db.collection('users').doc(userId).get();
  }

  Future<void> createAttendanceRecord(String studentId, String subject,
      DateTime dateTime, String status) async {
    await _db.collection('attendance').add({
      'studentId': studentId,
      'subject': subject,
      'date': Timestamp.fromDate(dateTime),
      'time': Timestamp.fromDate(dateTime),
      'attendanceStatus': status,
    });
  }

  Future<List<QueryDocumentSnapshot>> getAttendanceRecords(
      String studentId) async {
    QuerySnapshot snapshot = await _db
        .collection('attendance')
        .where('studentId', isEqualTo: studentId)
        .get();
    return snapshot.docs;
  }

  Future<void> createClass(
      String subject, String teacherId, List<String> studentIds) async {
    await _db.collection('classes').add({
      'subject': subject,
      'teacherId': teacherId,
      'students': studentIds,
    });
  }

  Future<List<QueryDocumentSnapshot>> getClassesForTeacher(
      String teacherId) async {
    QuerySnapshot snapshot = await _db
        .collection('classes')
        .where('teacherId', isEqualTo: teacherId)
        .get();
    return snapshot.docs;
  }
}
