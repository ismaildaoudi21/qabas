import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:qabas/utils/app_colors.dart';
import 'package:qabas/screens/teacher/wird/teacher_wird_management.dart';
import 'package:qabas/screens/teacher/attendance/attendance_page.dart';
import 'package:qabas/screens/teacher/assessments/assessments_page.dart';
import 'package:qabas/screens/teacher/wird/teacher_wird_page.dart';
import 'package:qabas/screens/teacher/students/students_page.dart';
import 'package:qabas/screens/teacher/notifications/notifications_page.dart';
import 'package:qabas/screens/teacher/halaqat/halaqat_page.dart';
import 'package:qabas/screens/shared/books_list_page.dart';

class TeacherDashboardPage extends StatelessWidget {
  final String teacherId;
  final Map<String, dynamic> teacherData;

  TeacherDashboardPage({
    required this.teacherId,
    required this.teacherData,
  });

  Future<DocumentSnapshot?> _getFirstHalaqah() async {
    QuerySnapshot halaqahsSnapshot = await FirebaseFirestore.instance
        .collection('halaqahs')
        .where('teacherId', isEqualTo: teacherId)
        .limit(1)
        .get();

    if (halaqahsSnapshot.docs.isNotEmpty) {
      return halaqahsSnapshot.docs.first;
    }
    return null;
  }

  Future<void> _navigateToAttendance(BuildContext context) async {
    DocumentSnapshot? halaqah = await _getFirstHalaqah();
    if (halaqah != null && context.mounted) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => AttendancePage(
            teacherId: teacherId,
            halaqahId: halaqah.id,
            halaqahName: (halaqah.data() as Map<String, dynamic>)['name'] ?? '',
          ),
        ),
      );
    } else if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('لا توجد حلقات مسندة إليك')),
      );
    }
  }

  Future<void> _navigateToAssessments(BuildContext context) async {
    DocumentSnapshot? halaqah = await _getFirstHalaqah();
    if (halaqah != null && context.mounted) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => AssessmentsPage(
            teacherId: teacherId,
            halaqahId: halaqah.id,
            halaqahName: (halaqah.data() as Map<String, dynamic>)['name'] ?? '',
          ),
        ),
      );
    } else if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('لا توجد حلقات مسندة إليك')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(
          title: _buildLogo(),
          centerTitle: true,
          backgroundColor: Colors.transparent,
          elevation: 0,
          actions: [
            IconButton(
              icon: Icon(Icons.logout, color: Colors.black),
              onPressed: () {
                Navigator.pushReplacementNamed(context, '/');
              },
            ),
          ],
        ),
        backgroundColor: const Color(0xFFFFFBF7),
        body: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'مرحباً، ${teacherData['firstName']} ${teacherData['lastName']}',
                    style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
              SizedBox(height: 20),
              Expanded(
                child: GridView.count(
                  crossAxisCount: 3,
                  crossAxisSpacing: 16,
                  mainAxisSpacing: 16,
                  children: [
                    _buildDashboardItem(
                      Icons.class_, 
                      'حلقاتي', 
                      Colors.blueGrey, 
                      () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => HalaqatPage(teacherId: teacherId),
                        ),
                      ),
                    ),
                    _buildDashboardItem(
                      Icons.person, 
                      'طلابي', 
                      Colors.blueAccent, 
                      () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => StudentsPage(teacherId: teacherId),
                        ),
                      ),
                    ),
                    _buildDashboardItem(
                      Icons.article, 
                      'الورد اليومي', 
                      AppColors.orange1, 
                      () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => TeacherWirdPage(teacherId: teacherId),
                          ),
                        );
                      }
                    ),
                    _buildDashboardItem(
                      Icons.calendar_today, 
                      'الحضور والغياب', 
                      Colors.green, 
                      () => _navigateToAttendance(context),
                    ),
                    _buildDashboardItem(
                      Icons.assessment, 
                      'التقييمات', 
                      Colors.orange, 
                      () => _navigateToAssessments(context),
                    ),
                    _buildDashboardItem(
                      Icons.notifications, 
                      'الإشعارات', 
                      Colors.purple, 
                      () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => TeacherNotificationsPage(teacherId: teacherId),
                        ),
                      ),
                    ),
                    _buildDashboardItem(
                      Icons.library_books,
                      'المكتبة',
                      AppColors.orange1,
                      () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => BooksListPage(),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLogo() {
    return Container(
      width: 50,
      height: 50,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0),
            spreadRadius: 1,
            blurRadius: 5,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Center(
        child: Image.asset('lib/assets/logo.jpg', width: 40, height: 40),
      ),
    );
  }

  Widget _buildDashboardItem(IconData icon, String label, Color color, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(10),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.3),
              spreadRadius: 1,
              blurRadius: 3,
              offset: Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 40, color: color),
            SizedBox(height: 8),
            Text(
              label,
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _navigateToWirdManagement(BuildContext context) async {
    try {
      // Get teacher's halaqahs
      QuerySnapshot halaqahsSnapshot = await FirebaseFirestore.instance
          .collection('halaqahs')
          .where('teacherId', isEqualTo: teacherId)
          .get();

      if (halaqahsSnapshot.docs.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('لا توجد حلقات مسندة إليك')),
        );
        return;
      }

      List<String> halaqahIds = halaqahsSnapshot.docs.map((doc) => doc.id).toList();

      // Get students from these halaqahs
      QuerySnapshot studentsSnapshot = await FirebaseFirestore.instance
          .collection('users')
          .where('halaqahId', whereIn: halaqahIds)
          .where('role', isEqualTo: 'student')
          .get();

      if (studentsSnapshot.docs.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('لا يوجد طلاب في حلقاتك')),
        );
        return;
      }

      // Navigate to DailyQuranPage
      if (context.mounted) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => TeacherWirdManagement(
              studentId: studentsSnapshot.docs.first.id,
              studentName: (studentsSnapshot.docs.first.data() as Map<String, dynamic>)['name'] ?? '',
            ),
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('حدث خطأ: $e')),
        );
      }
    }
  }
}