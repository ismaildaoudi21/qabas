import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:qabas/utils/app_colors.dart';
import 'students/students_page.dart';

class TeacherDashboardPage extends StatelessWidget {
  final String teacherId;
  final Map<String, dynamic> teacherData;

  TeacherDashboardPage({
    required this.teacherId,
    required this.teacherData,
  });

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
                // Add logout functionality
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
                      () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => TeacherHalaqahListPage(teacherId: teacherId),
                          ),
                        );
                      }
                    ),
                    _buildDashboardItem(
                      Icons.person, 
                      'طلابي', 
                      Colors.blueAccent, 
                      () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => TeacherStudentsListPage(teacherId: teacherId),
                          ),
                        );
                      }
                    ),
                    _buildDashboardItem(
                      Icons.article, 
                      'الورد اليومي', 
                      AppColors.orange1, 
                      () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => DailyQuranPage(teacherId: teacherId),
                          ),
                        );
                      }
                    ),
                    _buildDashboardItem(
                      Icons.calendar_today, 
                      'الحضور والغياب', 
                      Colors.green, 
                      () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => AttendancePage(teacherId: teacherId),
                          ),
                        );
                      }
                    ),
                    _buildDashboardItem(
                      Icons.assessment, 
                      'التقييمات', 
                      Colors.orange, 
                      () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => AssessmentsPage(teacherId: teacherId),
                          ),
                        );
                      }
                    ),
                    _buildDashboardItem(
                      Icons.notifications, 
                      'الإشعارات', 
                      Colors.purple, 
                      () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => NotificationsPage(teacherId: teacherId),
                          ),
                        );
                      }
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
}

// Placeholder pages - you'll need to implement these
class TeacherHalaqahListPage extends StatelessWidget {
  final String teacherId;
  TeacherHalaqahListPage({required this.teacherId});
  @override
  Widget build(BuildContext context) => Scaffold(body: Center(child: Text('صفحة الحلقات')));
}

class TeacherStudentsListPage extends StatelessWidget {
  final String teacherId;
  TeacherStudentsListPage({required this.teacherId});
  @override
  Widget build(BuildContext context) => Scaffold(body: Center(child: Text('صفحة الطلاب')));
}

class DailyQuranPage extends StatelessWidget {
  final String teacherId;
  DailyQuranPage({required this.teacherId});
  @override
  Widget build(BuildContext context) => Scaffold(body: Center(child: Text('صفحة الورد اليومي')));
}

class AttendancePage extends StatelessWidget {
  final String teacherId;
  AttendancePage({required this.teacherId});
  @override
  Widget build(BuildContext context) => Scaffold(body: Center(child: Text('صفحة الحضور والغياب')));
}

class AssessmentsPage extends StatelessWidget {
  final String teacherId;
  AssessmentsPage({required this.teacherId});
  @override
  Widget build(BuildContext context) => Scaffold(body: Center(child: Text('صفحة التقييمات')));
}

class NotificationsPage extends StatelessWidget {
  final String teacherId;
  NotificationsPage({required this.teacherId});
  @override
  Widget build(BuildContext context) => Scaffold(body: Center(child: Text('صفحة الإشعارات')));
}