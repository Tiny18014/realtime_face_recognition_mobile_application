import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../auth/login_screen.dart';
import 'FaceVerificationPage.dart';
import '../screens/AttendancePage.dart';

class StudentHomeScreen extends StatefulWidget {
  @override
  _StudentDashboardState createState() => _StudentDashboardState();
}

class _StudentDashboardState extends State<StudentHomeScreen> {
  final User? _user = FirebaseAuth.instance.currentUser;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final TextEditingController _subjectNameController = TextEditingController();
  final TextEditingController _teacherNameController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Student Dashboard', style: TextStyle(fontWeight: FontWeight.bold)),
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
      body: FutureBuilder<DocumentSnapshot>(
        future: _firestore.collection('users').doc(_user?.uid).get(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || snapshot.data == null) {
            return const Center(child: Text('No Data Found'));
          }

          final userData = snapshot.data!.data() as Map<String, dynamic>;
          final subjects = List<Map<String, dynamic>>.from(userData['subjects'] ?? []);

          return SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Add a New Subject',
                    style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 20),
                  _buildInputField(controller: _subjectNameController, label: 'Subject Name'),
                  const SizedBox(height: 10),
                  _buildInputField(controller: _teacherNameController, label: 'Teacher Name'),
                  const SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: _addSubjectToUser,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.orange[900],
                      padding: const EdgeInsets.symmetric(vertical: 15, horizontal: 40),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(50)),
                    ),
                    child: const Text('Add Subject', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  ),
                  const SizedBox(height: 30),
                  const Text(
                    'Your Enrolled Subjects',
                    style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 10),
                  ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: subjects.length,
                    itemBuilder: (context, index) {
                      final subject = subjects[index];
                      final subjectName = subject['subjectName'] ?? 'Unknown Subject';

                      return StreamBuilder<QuerySnapshot>(
                        stream: _firestore.collection('subjects').where('name', isEqualTo: subjectName).snapshots(),
                        builder: (context, subjectSnapshot) {
                          if (subjectSnapshot.connectionState == ConnectionState.waiting) {
                            return const ListTile(
                              title: Text('Loading...'),
                              subtitle: Text('Please wait'),
                            );
                          }

                          if (!subjectSnapshot.hasData || subjectSnapshot.data!.docs.isEmpty) {
                            return ListTile(
                              title: Text(subjectName),
                              trailing: const Icon(Icons.error, color: Colors.red),
                            );
                          }

                          final subjectData = subjectSnapshot.data!.docs.first.data() as Map<String, dynamic>;
                          final isActive = subjectData['isActive'] ?? false;
                          final attendanceStream = _firestore
                              .collection('subjects')
                              .doc(subjectSnapshot.data!.docs.first.id)
                              .collection('attendance')
                              .doc(_user!.uid)
                              .collection('dates')
                              .snapshots();

                          return StreamBuilder<QuerySnapshot>(
                            stream: attendanceStream,
                            builder: (context, attendanceSnapshot) {
                              if (attendanceSnapshot.connectionState == ConnectionState.waiting) {
                                return const ListTile(
                                  title: Text('Loading Attendance...'),
                                  subtitle: Text('Please wait'),
                                );
                              }

                              final attendanceDocs = attendanceSnapshot.data?.docs ?? [];
                              final totalDays = attendanceDocs.length;
                              final presentDays = attendanceDocs
                                  .where((doc) => (doc.data() as Map<String, dynamic>)['status'] == 'present')
                                  .length;
                              final attendancePercentage =
                              totalDays > 0 ? (presentDays / totalDays * 100).toStringAsFixed(1) : '0';

                              return Card(
                                margin: const EdgeInsets.symmetric(vertical: 10),
                                child: ListTile(
                                  contentPadding: const EdgeInsets.all(16),
                                  title: Text(subjectName, style: const TextStyle(fontWeight: FontWeight.bold)),
                                  subtitle: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text('Attendance: $attendancePercentage%'),
                                      const SizedBox(height: 8),
                                      LinearProgressIndicator(
                                        value: totalDays > 0 ? presentDays / totalDays : 0,
                                        backgroundColor: Colors.grey[300],
                                        color: Colors.green,
                                      ),
                                      const SizedBox(height: 8),
                                      Row(
                                        children: [
                                          IconButton(
                                            icon: const Icon(Icons.calendar_today, color: Colors.orange),
                                            onPressed: () async {
                                              Navigator.push(
                                                context,
                                                MaterialPageRoute(
                                                  builder: (context) => AttendancePage(
                                                    userId: _user!.uid,
                                                    subjectName: subjectName,
                                                  ),
                                                ),
                                              );
                                            },
                                          ),
                                          IconButton(
                                            icon: const Icon(Icons.delete, color: Colors.red),
                                            onPressed: () async {
                                              await _deleteSubject(subjectName);
                                            },
                                          ),
                                        ],
                                      ),


                                    ],
                                  ),
                                  trailing: IconButton(
                                    icon: Icon(
                                      isActive ? Icons.check_circle : Icons.check_circle_outline,
                                      color: isActive ? Colors.green : Colors.grey,
                                    ),
                                    onPressed: isActive
                                        ? () => _navigateToFaceVerificationPage(subjectName)
                                        : null,
                                  ),
                                ),
                              );
                            },
                          );
                        },
                      );
                    },
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildInputField({required TextEditingController controller, required String label}) {
    return TextField(
      controller: controller,
      decoration: InputDecoration(
        labelText: label,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  Future<void> _addSubjectToUser() async {
    final subjectName = _subjectNameController.text.trim();
    final teacherName = _teacherNameController.text.trim();

    if (subjectName.isEmpty || teacherName.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please provide both subject and teacher names')),
      );
      return;
    }

    try {
      await _firestore.collection('users').doc(_user!.uid).update({
        'subjects': FieldValue.arrayUnion([{'subjectName': subjectName, 'teacherName': teacherName}]),
      });

      final subjectQuery = await _firestore.collection('subjects').where('name', isEqualTo: subjectName).get();
      if (subjectQuery.docs.isNotEmpty) {
        await _firestore.collection('subjects').doc(subjectQuery.docs.first.id).update({
          'students': FieldValue.arrayUnion([_user!.uid]),
        });
      }

      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Subject Added Successfully!')));
      _subjectNameController.clear();
      _teacherNameController.clear();
      setState(() {});
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to add subject: $e')));
    }
  }

  Future<void> _navigateToFaceVerificationPage(String subjectName) async {
    bool isFaceVerified = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => FaceVerificationPage(
          subjectName: subjectName,
          userId: _user!.uid,
        ),
      ),
    );

    if (isFaceVerified) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Attendance Marked Successfully!')));
      await _markAttendance(subjectName);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Face verification failed')));
    }
  }

  Future<void> _markAttendance(String subjectName) async {
    final now = DateTime.now();
    final date = '${now.year}-${now.month}-${now.day}';

    try {
      final subjectQuery = await _firestore.collection('subjects').where('name', isEqualTo: subjectName).get();
      if (subjectQuery.docs.isNotEmpty) {
        await _firestore
            .collection('subjects')
            .doc(subjectQuery.docs.first.id)
            .collection('attendance')
            .doc(_user!.uid)
            .collection('dates')
            .doc(date)
            .set({
          'status': 'present',
          'timestamp': FieldValue.serverTimestamp(),
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to mark attendance: $e')));
    }
  }
  Future<void> _deleteSubject(String subjectName) async {
    try {

      final userRef = _firestore.collection('users').doc(_user!.uid);


      final userSnapshot = await userRef.get();
      final userData = userSnapshot.data() as Map<String, dynamic>;


      final subjectToRemove = userData['subjects']?.firstWhere(
            (subject) => subject['subjectName'] == subjectName,
        orElse: () => null,
      );

      if (subjectToRemove != null) {

        await userRef.update({
          'subjects': FieldValue.arrayRemove([subjectToRemove]),
        });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Subject Deleted Successfully!')),
        );
        setState(() {});
      } else {

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Subject not found for deletion')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to delete subject: $e')),
      );
    }
  }

}
