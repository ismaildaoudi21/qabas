import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:qabas/screens/admin/admin_dashboard_page.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:qabas/screens/teacher/teacher_dashboard_page.dart'; 
import 'package:qabas/screens/parent/parent_dashboard_page.dart'; 
import 'package:qabas/screens/student/student_dashboard_page.dart'; // You'll need to create this
class AuthService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<bool> login(BuildContext context, String userType, String username, String password) async {
  try {
    switch (userType) {
      case 'كإداري':
        if (username == 'admin' && password == 'admin') {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => AdminDashboardPage()),
          );
          return true;
        }
        break;
        
      case 'كمعلم':
        var teacherQuery = await _firestore
            .collection('users')
            .where('username', isEqualTo: username)
            .where('password', isEqualTo: password)
            .where('role', isEqualTo: 'teacher')
            .get();

        if (teacherQuery.docs.isNotEmpty) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) => TeacherDashboardPage(
                teacherId: teacherQuery.docs.first.id,
                teacherData: teacherQuery.docs.first.data(),
              ),
            ),
          );
          return true;
        }
        break;

      case 'كولي أمر':
        print('Attempting parent login with username: $username');
        var parentQuery = await _firestore
            .collection('users')
            .where('parentUsername', isEqualTo: username)
            .where('parentPassword', isEqualTo: password)
            .where('parentRole', isEqualTo: 'parent')
            .get();

        print('Parent query results: ${parentQuery.docs.length} documents found');
        if (parentQuery.docs.isNotEmpty) {
          final parentDoc = parentQuery.docs.first;
          final parentData = parentDoc.data();
          print('Parent document ID: ${parentDoc.id}');
          print('Parent data: $parentData');
          
          final cleanedParentData = {
            'id': parentDoc.id,
            'firstName': parentData['parentName']?.split(' ').first ?? '',
            'lastName': parentData['parentName']?.split(' ').last ?? '',
            'email': parentData['email'],
            'phoneNumber': parentData['phoneNumber'],
            'username': parentData['parentUsername'],
            'role': 'parent',
          };
          
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) => ParentDashboardPage(
                parentId: username,
                parentData: cleanedParentData,
              ),
            ),
          );
          return true;
        } else {
          print('No parent found with these credentials');
        }
        break;

      case 'كطالب':
        var studentQuery = await _firestore
            .collection('users')
            .where('username', isEqualTo: username)
            .where('password', isEqualTo: password)
            .where('role', isEqualTo: 'student')
            .get();

        if (studentQuery.docs.isNotEmpty) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) => StudentDashboardPage(
                studentId: studentQuery.docs.first.id,
                studentData: studentQuery.docs.first.data(),
              ),
            ),
          );
          return true;
        }
        break;
    }
    return false;
  } catch (e) {
    print("Error during login: $e");
    return false;
  }
  }

  Future<bool> testFirestoreConnection() async {
    try {
      var connectivityResult = await (Connectivity().checkConnectivity());
      if (connectivityResult == ConnectivityResult.none) {
        print("No internet connection");
        return false;
      }

      await _firestore.collection('users').limit(1).get()
          .timeout(Duration(seconds: 5));
      print("Successfully connected to Firestore");
      return true;
    } catch (e) {
      print("Error connecting to Firestore: $e");
      return false;
    }
  }
}