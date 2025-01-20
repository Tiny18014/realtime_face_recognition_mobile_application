import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../auth/login_screen.dart';
import 'attendance_page.dart';

class TeacherHomeScreen extends StatefulWidget {
  @override
  _TeacherDashboardState createState() => _TeacherDashboardState();
}

class _TeacherDashboardState extends State<TeacherHomeScreen> {
  final User? _user = FirebaseAuth.instance.currentUser;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  final TextEditingController _subjectNameController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Teacher Dashboard'),
        backgroundColor: Colors.orange[900],
        automaticallyImplyLeading: false,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              await FirebaseAuth.instance.signOut();
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (context) => const LoginScreen()),
              );
            },
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [

            _buildSubjectInputField(),
            _buildDescriptionInputField(),
            _buildAddSubjectButton(),
            SizedBox(height: 20),
            Divider(),

            _buildSubjectList(),
          ],
        ),
      ),
    );
  }

  Widget _buildSubjectInputField() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: TextField(
        controller: _subjectNameController,
        decoration: InputDecoration(
          labelText: 'Subject Name',
          border: OutlineInputBorder(),
          contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        ),
      ),
    );
  }

  Widget _buildDescriptionInputField() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: TextField(
        controller: _descriptionController,
        decoration: InputDecoration(
          labelText: 'Description (Optional)',
          border: OutlineInputBorder(),
          contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        ),
      ),
    );
  }

  Widget _buildAddSubjectButton() {
    return ElevatedButton(
      onPressed: () async {
        await _addSubject();
      },
      style: ElevatedButton.styleFrom(
        padding: EdgeInsets.symmetric(horizontal: 32, vertical: 12),
        backgroundColor: Colors.orange[900],
      ),
      child: Text('Add Subject'),
    );
  }

  Widget _buildSubjectList() {
    return Expanded(
      child: StreamBuilder<QuerySnapshot>(
        stream: _firestore
            .collection('subjects')
            .where('teacherId', isEqualTo: _user?.uid)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return Center(child: Text('No Subjects Found'));
          }

          final subjects = snapshot.data!.docs;

          return ListView.builder(
            itemCount: subjects.length,
            itemBuilder: (context, index) {
              final subject = subjects[index];
              final subjectId = subject.id;
              final subjectName = subject['name'];
              final isActive = subject['isActive'] ?? false;

              return Card(
                margin: EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                elevation: 3,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                child: ListTile(
                  contentPadding: EdgeInsets.all(16),
                  title: Text(
                    subjectName,
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                  ),
                  subtitle: Text(
                    'Attendance: ${isActive ? "Active" : "Inactive"}',
                    style: TextStyle(
                      color: isActive ? Colors.green : Colors.red,
                      fontSize: 14,
                    ),
                  ),
                  trailing: Switch(
                    value: isActive,
                    onChanged: (value) async {
                      await _toggleAttendance(subjectId, value);
                    },
                  ),
                  onTap: () {

                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => AttendancePage(subjectId: subjectId),
                      ),
                    );
                  },
                ),
              );
            },
          );
        },
      ),
    );
  }

  Future<void> _addSubject() async {
    final String subjectName = _subjectNameController.text.trim();
    final String description = _descriptionController.text.trim();

    if (subjectName.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Please provide a subject name')),
      );
      return;
    }

    try {
      await _firestore.collection('subjects').add({
        'name': subjectName,
        'teacherId': _user!.uid,
        'students': [],
        'createdAt': Timestamp.now(),
        'description': description,
        'isActive': false,
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Subject Added Successfully!')),
      );

      _subjectNameController.clear();
      _descriptionController.clear();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to add subject: $e')),
      );
    }
  }

  Future<void> _toggleAttendance(String subjectId, bool isActive) async {
    try {
      await _firestore.collection('subjects').doc(subjectId).update({
        'isActive': isActive,
      });

      if (!isActive) {
        await _markStudentsAbsent(subjectId);
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(isActive
              ? 'Attendance Activated!'
              : 'Attendance Deactivated!'),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to update attendance status: $e')),
      );
    }
  }

  Future<void> _markStudentsAbsent(String subjectId) async {
    try {
      DocumentSnapshot subjectDocSnapshot =
      await _firestore.collection('subjects').doc(subjectId).get();

      if (subjectDocSnapshot.exists) {
        List<dynamic> students = subjectDocSnapshot['students'];
        final currentDate = DateTime.now();
        final formattedDate =
            "${currentDate.year}-${currentDate.month.toString().padLeft(2, '0')}-${currentDate.day.toString().padLeft(2, '0')}";

        WriteBatch batch = _firestore.batch();

        for (var studentId in students) {
          DocumentReference dateDocRef = _firestore
              .collection('subjects')
              .doc(subjectId)
              .collection('attendance')
              .doc(studentId)
              .collection('dates')
              .doc(formattedDate);

          DocumentSnapshot dateDocSnapshot = await dateDocRef.get();

          if (!dateDocSnapshot.exists) {
            batch.set(dateDocRef, {
              'status': 'absent',
              'timestamp': Timestamp.fromDate(currentDate),
            });
          }
        }

        await batch.commit();

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Students marked as absent where necessary')),
        );
      }
    } catch (e) {
      print("Error marking students absent: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to mark students absent: $e')),
      );
    }
  }
}
