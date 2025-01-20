import 'dart:developer';
import 'package:animate_do/animate_do.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:realtime_face_recognition/auth/signup_screen.dart';
import 'package:realtime_face_recognition/screens/landing_page.dart';
import 'package:realtime_face_recognition/screens/student_dashboard.dart';
import 'package:realtime_face_recognition/screens/teacher_home_screen.dart';
import 'package:realtime_face_recognition/screens/face_registration_screen.dart';
import '../widgets/button.dart';
import '../widgets/textfield.dart';
import 'auth_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_sign_in/google_sign_in.dart';


class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _auth = AuthService();
  final _email = TextEditingController();
  final _password = TextEditingController();
  final GoogleSignIn _googleSignIn = GoogleSignIn();
  // Used for showing and hiding the password
  late bool passwordVisibility;

  @override
  void initState() {
    super.initState();
    passwordVisibility = false;
  }

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _signInWithGoogle() async {
    try {
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();

      if (googleUser == null) {
        log("Google Sign-In canceled by the user.");
        return;
      }

      log("Google user signed in: ${googleUser.email}");

      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;
      final AuthCredential credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      final UserCredential userCredential = await FirebaseAuth.instance.signInWithCredential(credential);
      final User? user = userCredential.user;

      if (user == null) {
        log("Firebase sign-in failed.");
        return;
      }

      log("Firebase user signed in: ${user.email}");

      DocumentSnapshot userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();

      if (!userDoc.exists) {
        log("User does not exist in Firestore. Creating new user document...");

        await FirebaseFirestore.instance.collection('users').doc(user.uid).set({
          'role': 'Student',
          'hasFaceRegistered': false,
          'email': user.email,
          'name': user.displayName,
          'photoURL': user.photoURL,
        });

        userDoc = await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .get();
      }

      Map<String, dynamic>? userData = userDoc.data() as Map<String, dynamic>?;
      String role = userData?['role'] ?? 'Student';
      bool hasFaceRegistered = userData?['hasFaceRegistered'] ?? false;

      log("User role: $role, hasFaceRegistered: $hasFaceRegistered");

      if (role == 'Student' && !hasFaceRegistered) {
        goToFaceRegistration(context);
      } else {
        goToHome(context, role);
      }
    } catch (e) {
      log("Google Sign-In failed: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Google Sign-In failed: $e')),
      );
    }
  }



  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        decoration: BoxDecoration(
            gradient: LinearGradient(begin: Alignment.topCenter, colors: [
              Colors.orange.shade900,
              Colors.orange.shade800,
              Colors.orange.shade400
            ])),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            const SizedBox(height: 80),
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  FadeInUp(
                    duration: const Duration(milliseconds: 1000),
                    child: const Text(
                      "Login",
                      style: TextStyle(color: Colors.white, fontSize: 40),
                    ),
                  ),
                  const SizedBox(height: 10),
                  FadeInUp(
                    duration: const Duration(milliseconds: 1300),
                    child: const Text(
                      "Welcome Back",
                      style: TextStyle(color: Colors.white, fontSize: 18),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            Expanded(
              child: Container(
                decoration: const BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.only(
                        topLeft: Radius.circular(60),
                        topRight: Radius.circular(60))),
                child: SingleChildScrollView(
                  child: Padding(
                    padding: const EdgeInsets.all(30),
                    child: Column(
                      children: <Widget>[
                        const SizedBox(height: 60),

                        // Email TextField with animation
                        FadeInUp(
                          duration: const Duration(milliseconds: 1400),
                          child: Container(
                            decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(10),
                                boxShadow: const [
                                  BoxShadow(
                                      color: Color.fromRGBO(225, 95, 27, .3),
                                      blurRadius: 20,
                                      offset: Offset(0, 10))
                                ]),
                            child: Padding(
                              padding: const EdgeInsets.all(10),
                              child: TextField(
                                controller: _email,
                                decoration: const InputDecoration(
                                    hintText: "Email",
                                    hintStyle: TextStyle(color: Colors.grey),
                                    border: InputBorder.none),
                              ),
                            ),
                          ),
                        ),

                        const SizedBox(height: 20),

                        // Password TextField with animation
                        FadeInUp(
                          duration: const Duration(milliseconds: 1500),
                          child: Container(
                            decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(10),
                                boxShadow: const [
                                  BoxShadow(
                                      color: Color.fromRGBO(225, 95, 27, .3),
                                      blurRadius: 20,
                                      offset: Offset(0, 10))
                                ]),
                            child: Padding(
                              padding: const EdgeInsets.all(10),
                              child: TextField(
                                controller: _password,
                                obscureText: !passwordVisibility,
                                decoration: InputDecoration(
                                  hintText: "Password",
                                  hintStyle: const TextStyle(color: Colors.grey),
                                  border: InputBorder.none,
                                  suffixIcon: IconButton(
                                    icon: Icon(
                                      passwordVisibility
                                          ? Icons.visibility
                                          : Icons.visibility_off,
                                      color: Colors.grey,
                                    ),
                                    onPressed: () {
                                      setState(() {
                                        passwordVisibility = !passwordVisibility;
                                      });
                                    },
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),


                        const SizedBox(height: 40),

                        // Login Button with animation
                        FadeInUp(
                          duration: const Duration(milliseconds: 1600),
                          child: MaterialButton(
                            onPressed: _login,
                            height: 50,
                            color: Colors.orange[900],
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(50),
                            ),
                            child: const Center(
                              child: Text(
                                "Login",
                                style: TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold),
                              ),
                            ),
                          ),
                        ),

                        const SizedBox(height: 20),
                        // Google Sign-In Button with animation
                        FadeInUp(
                          duration: const Duration(milliseconds: 1600),
                          child: MaterialButton(
                            onPressed: _signInWithGoogle,
                            height: 50,
                            color: Colors.blue, // Google blue color
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(50),
                            ),
                            child: const Center(
                              child: Text(
                                "Sign in with Google",
                                style: TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold),
                              ),
                            ),
                          ),
                        ),

                        // Sign Up Text with animation
                        FadeInUp(
                          duration: const Duration(milliseconds: 1700),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Text("Don't have an account? "),
                              InkWell(
                                onTap: () => goToSignup(context),
                                child: const Text(
                                  "Sign Up",
                                  style: TextStyle(
                                      color: Colors.orange,
                                      fontWeight: FontWeight.bold),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            )
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => LandingScreen()), // Navigate to LandingPage
        ),
        backgroundColor: Colors.white,
        child: const Icon(Icons.home, color: Colors.orange), // White Home Button
      ),
    );
  }

  // Navigation to Signup screen
  goToSignup(BuildContext context) => Navigator.push(
    context,
    MaterialPageRoute(builder: (context) => const SignupScreen()),
  );

  // Navigation to Home screen based on the role
  goToHome(BuildContext context, String role) {
    if (role == 'Teacher') {
      Navigator.push(context,
          MaterialPageRoute(builder: (context) => TeacherHomeScreen()));
    } else {
      Navigator.push(context,
          MaterialPageRoute(builder: (context) => StudentHomeScreen()));
    }
  }

  // Login functionality
  _login() async {
    try {
      log("Attempting login with email: ${_email.text}");
      final userCredential = await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: _email.text,
        password: _password.text,
      );
      final User? user = userCredential.user;

      if (user != null) {
        log("User Logged In: ${user.email}");
        // Get user data from Firestore
        DocumentSnapshot userDoc = await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .get();

        String role = userDoc['role'];
        bool hasFaceRegistered = userDoc['hasFaceRegistered'] ?? false;

        if (role == 'Student' && !hasFaceRegistered) {
          goToFaceRegistration(context);
        } else {
          goToHome(context, role);
        }
      }
    } catch (e) {
      log("Login failed: $e");

      // Handle Firebase Auth specific errors and show appropriate messages
      if (e is FirebaseAuthException) {
        if (e.code == 'user-not-found') {
          _showErrorMessage(
            "No user found with this email. Please check and try again.",
          );
        } else if (e.code == 'wrong-password') {
          _showErrorMessage(
            "Incorrect password. Please try again.",
          );
        } else if (e.code == 'invalid-email') {
          _showErrorMessage(
            "The email address is invalid. Please check and try again.",
          );
        } else {
          _showErrorMessage(
            "An error occurred: ${e.message}. Please try again later.",
          );
        }
      } else {
        // For any unexpected error
        _showErrorMessage(
          "Something went wrong. Please try again later.",
        );
      }
    }
  }


// Function to display an aesthetic error message
  void _showErrorMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red.shade600,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  // Navigation to Face Registration screen
  void goToFaceRegistration(BuildContext context) {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => FaceRegistrationScreen()),
    );
  }
}