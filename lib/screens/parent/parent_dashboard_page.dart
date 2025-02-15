import 'package:flutter/material.dart';
import 'package:qabas/utils/app_colors.dart';
import 'package:qabas/screens/parent/parentNotificationsPage/notifications_page.dart';
import 'package:qabas/screens/parent/children/children_page.dart';
import 'package:qabas/screens/parent/payments/payments_page.dart';
import 'package:qabas/screens/parent/reports/reports_page.dart';
import 'package:qabas/screens/shared/books_list_page.dart';

class ParentDashboardPage extends StatelessWidget {
  final String parentId;
  final Map<String, dynamic> parentData;

  ParentDashboardPage({
    required this.parentId,
    required this.parentData,
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
              onPressed: () => Navigator.pushReplacementNamed(context, '/'),
            ),
          ],
        ),
        backgroundColor: const Color(0xFFFFFBF7),
        body: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'مرحباً، ${parentData['firstName']} ${parentData['lastName']}',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 20),
              Expanded(
                child: GridView.count(
                  crossAxisCount: 2,
                  crossAxisSpacing: 16,
                  mainAxisSpacing: 16,
                  children: [
                    _buildDashboardItem(
                      Icons.people,
                      'أبنائي',
                      AppColors.blue1,
                      () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => ChildrenPage(parentId: parentId),
                        ),
                      ),
                    ),
                    _buildDashboardItem(
                      Icons.assessment,
                      'التقارير',
                      AppColors.green2,
                      () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => ReportsPage(parentId: parentId),
                        ),
                      ),
                    ),
                    _buildDashboardItem(
                      Icons.payment,
                      'المدفوعات',
                      AppColors.orange1,
                      () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => PaymentsPage(parentId: parentId),
                        ),
                      ),
                    ),
                    _buildDashboardItem(
                      Icons.notifications,
                      'الإشعارات',
                      AppColors.purple,
                      () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => ParentNotificationsPage(),
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
