import 'package:flutter/material.dart';
import 'package:qabas/utils/app_colors.dart';
import 'package:qabas/screens/admin/students/students_list_page.dart';
import 'halaqat/halaqah_list_page.dart';
import 'teachers/teacher_list_page.dart';
import 'admins/admin_list_page.dart';
import 'package:qabas/screens/admin/books/books_management_page.dart';

class AdminDashboardPage extends StatelessWidget {
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
        ),
        backgroundColor: const Color(0xFFFFFBF7),
        body: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'الرئيسية',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 20),
              Expanded(
                child: GridView.count(
                  crossAxisCount: 3,
                  crossAxisSpacing: 16,
                  mainAxisSpacing: 16,
                  children: [
                    _buildDashboardItem(Icons.admin_panel_settings, 'المشرفون', Colors.red, () {
                      Navigator.push(
                        context, 
                        MaterialPageRoute(builder: (context) => AdminListPage()),
                      );
                    }),
                    _buildDashboardItem(Icons.book, 'الكتب', AppColors.green2, () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => BooksManagementPage()),
                      );
                    }),
                    _buildDashboardItem(Icons.people, 'الحلقات', Colors.blueGrey, () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => HalaqahListPage()),
                      );
                    }),
              
                    _buildDashboardItem(Icons.person, 'الطلاب', Colors.blueAccent, () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => StudentsListPage()),
                      );
                    }),
                    _buildDashboardItem(Icons.school, 'المعلمون', Colors.purple, () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => TeacherListPage()),
                      );
                    }),
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