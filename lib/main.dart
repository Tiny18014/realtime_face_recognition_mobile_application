import 'package:camera/camera.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:realtime_face_recognition/screens/face_registration_screen.dart';
import 'package:realtime_face_recognition/screens/student_dashboard.dart';
import 'package:realtime_face_recognition/screens/teacher_home_screen.dart';
import 'package:realtime_face_recognition/widgets/home_screen.dart';
import 'auth/login_screen.dart';
import 'auth/signup_screen.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'screens/landing_page.dart';

Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {

  print('Background message: ${message.notification?.title}');
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  cameras = await availableCameras();


  FirebaseMessaging messaging = FirebaseMessaging.instance;


  NotificationSettings settings = await messaging.requestPermission(
    alert: true,
    badge: true,
    sound: true,
  );

  if (settings.authorizationStatus == AuthorizationStatus.authorized) {
    print('User granted notification permissions.');
  } else {
    print('User denied notification permissions.');
  }


  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);


  String? token = await messaging.getToken();
  print('FCM Token: $token');

  final user = FirebaseAuth.instance.currentUser;
  Widget initialScreen = LandingScreen();

  if (user != null) {
    final doc = await FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .get();

    if (doc.exists &&
        doc.data()?['hasFaceRegistered'] == true &&
        doc.data()?['faceEmbeddings'] != null) {
      initialScreen = const HomeScreen();
    } else {
      initialScreen = FaceRegistrationScreen();
    }
  } else {
    await logout();
  }

  runApp(MaterialApp(
    home: initialScreen,
    debugShowCheckedModeBanner: false,
  ));
}

Future<void> logout() async {
  await FirebaseAuth.instance.signOut();

}

class AttendanceApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Attendance System',
      theme: ThemeData(
        primarySwatch: Colors.orange,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      home: LandingScreen(),
      routes: {
        '/login': (context) => LoginScreen(),
        '/signup': (context) => SignupScreen(),
        '/teacher_dashboard': (context) => TeacherHomeScreen(),
        '/student_dashboard': (context) => StudentHomeScreen(),
      },
      debugShowCheckedModeBanner: false,
    );
  }
}
