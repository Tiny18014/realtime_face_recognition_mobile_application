# AI-Powered Attendance System 📸


This is an AI-powered attendance system built using Flutter and Firebase. The project leverages face recognition technology to streamline the attendance process for students and teachers.

# 🌟 Features

Face Recognition for Attendance: Students can register and mark attendance using face recognition.
Role-Based Dashboard: Separate dashboards for teachers and students for managing attendance and subjects.
Subject Management: Teachers can activate subjects for attendance, while students can view and enroll in subjects.
Live Attendance Records: Real-time attendance updates for both teachers and students.
Firebase Integration: Authentication, Firestore for database storage, and Firebase Cloud Messaging for notifications.
Responsive UI: A user-friendly interface with smooth animations and clear navigation.

#🛠️ Technology Stack
Frontend
Flutter: For building cross-platform mobile applications.
Google ML Kit: For face recognition and verification.
Backend
Firebase Authentication: For secure login and user management.
Cloud Firestore: For storing user, attendance, and subject data.
Firebase Cloud Messaging: For push notifications.
Other Tools
Dart: Programming language for Flutter.
GitHub: Version control and project hosting.

#🧩 System Architecture
The system consists of the following components:

Authentication:

Supports email/password login and role-based authentication.
Secure storage of face embeddings for verification.
Attendance Flow:

Students mark attendance by face verification.
Teachers activate the subject for attendance sessions.
Data Storage:

Teachers Collection: Stores teacher details and associated subjects.
Subjects Collection: Maintains subject details, students, and attendance records.
Users Collection: Stores student and teacher profiles, face embeddings, and roles.

#🚀 How to Run the Project
Clone the Repository:
git clone https://github.com/your-username/your-repo-name.git
cd your-repo-name
Set Up Firebase:
Add your google-services.json file for Android and GoogleService-Info.plist for iOS in their respective directories.
Install Dependencies:
flutter pub get
Run the App:
flutter run

#📊 Future Enhancements
Offline Mode: Enable attendance marking without internet connectivity.
Expanded Analytics: Provide detailed insights into attendance patterns.
Multilingual Support: Add support for multiple languages for broader accessibility.
Advanced AI Models: Upgrade the face recognition model for improved accuracy.











