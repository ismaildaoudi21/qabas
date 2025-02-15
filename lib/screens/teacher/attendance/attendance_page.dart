import 'package:flutter/material.dart';
import 'mark_attendance_page.dart';
import 'attendance_report_page.dart';

class AttendancePage extends StatelessWidget {
  final String teacherId;
  final String halaqahId;
  final String halaqahName;

  const AttendancePage({
    Key? key,
    required this.teacherId,
    required this.halaqahId,
    required this.halaqahName,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: DefaultTabController(
        length: 2,
        child: Scaffold(
          appBar: AppBar(
            title: Text('الحضور والغياب'),
            centerTitle: true,
            bottom: TabBar(
              tabs: [
                Tab(text: 'تسجيل الحضور'),
                Tab(text: 'التقارير'),
              ],
            ),
          ),
          body: TabBarView(
            children: [
              MarkAttendancePage(
                teacherId: teacherId,
                halaqahId: halaqahId,
                halaqahName: halaqahName,
              ),
              AttendanceReportPage(
                teacherId: teacherId,
                halaqahId: halaqahId,
                halaqahName: halaqahName,
              ),
            ],
          ),
        ),
      ),
    );
  }
}