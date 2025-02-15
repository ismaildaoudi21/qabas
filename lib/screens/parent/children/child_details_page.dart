import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:qabas/utils/app_colors.dart';

class ChildDetailsPage extends StatelessWidget {
  final String studentId;
  final Map<String, dynamic> studentData;

  const ChildDetailsPage({
    Key? key,
    required this.studentId,
    required this.studentData,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(
          title: Text('${studentData['firstName']} ${studentData['lastName']}'),
          backgroundColor: AppColors.blue1,
        ),
        body: SingleChildScrollView(
          padding: EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildStudentInfo(),
              SizedBox(height: 24),
              _buildWirdProgress(),
              SizedBox(height: 24),
              _buildAssessments(),
              SizedBox(height: 24),
              _buildAttendance(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStudentInfo() {
    return Card(
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'معلومات الطالب',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 16),
            _buildInfoRow('الحلقة', studentData['halaqahName'] ?? 'غير محدد'),
            _buildInfoRow('المعلم', studentData['teacherName'] ?? 'غير محدد'),
            _buildInfoRow('المستوى', studentData['level'] ?? 'غير محدد'),
          ],
        ),
      ),
    );
  }

  Widget _buildWirdProgress() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('wird')
          .where('studentId', isEqualTo: studentId)
          .orderBy('assignedDate', descending: true)
          .limit(5)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Text('حدث خطأ في تحميل البيانات');
        }

        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(child: CircularProgressIndicator());
        }

        return Card(
          child: Padding(
            padding: EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'الأوراد الحالية',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 16),
                if (!snapshot.hasData || snapshot.data!.docs.isEmpty)
                  Text('لا يوجد أوراد حالية')
                else
                  ...snapshot.data!.docs.map((doc) {
                    final wird = doc.data() as Map<String, dynamic>;
                    return Padding(
                      padding: EdgeInsets.only(bottom: 8),
                      child: _buildWirdItem(wird),
                    );
                  }).toList(),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildAssessments() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('wird')
          .where('studentId', isEqualTo: studentId)
          .where('status', isEqualTo: 'completed')
          .orderBy('completionDate', descending: true)
          .limit(5)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Text('حدث خطأ في تحميل البيانات');
        }

        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(child: CircularProgressIndicator());
        }

        return Card(
          child: Padding(
            padding: EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'آخر التقييمات',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 16),
                if (!snapshot.hasData || snapshot.data!.docs.isEmpty)
                  Text('لا يوجد تقييمات')
                else
                  ...snapshot.data!.docs.map((doc) {
                    final assessment = doc.data() as Map<String, dynamic>;
                    return Padding(
                      padding: EdgeInsets.only(bottom: 8),
                      child: _buildAssessmentItem(assessment),
                    );
                  }).toList(),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildAttendance() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('attendance')
          .where('studentId', isEqualTo: studentId)
          .orderBy('date', descending: true)
          .limit(5)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Text('حدث خطأ في تحميل البيانات');
        }

        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(child: CircularProgressIndicator());
        }

        return Card(
          child: Padding(
            padding: EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'سجل الحضور',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 16),
                if (!snapshot.hasData || snapshot.data!.docs.isEmpty)
                  Text('لا يوجد سجل حضور')
                else
                  ...snapshot.data!.docs.map((doc) {
                    final attendance = doc.data() as Map<String, dynamic>;
                    return Padding(
                      padding: EdgeInsets.only(bottom: 8),
                      child: _buildAttendanceItem(attendance),
                    );
                  }).toList(),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Text(
            '$label: ',
            style: TextStyle(
              color: Colors.grey[600],
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(value),
        ],
      ),
    );
  }

  Widget _buildWirdItem(Map<String, dynamic> wird) {
    return Row(
      children: [
        Icon(
          wird['status'] == 'completed'
              ? Icons.check_circle
              : Icons.access_time,
          color: wird['status'] == 'completed'
              ? AppColors.green2
              : Colors.orange,
          size: 16,
        ),
        SizedBox(width: 8),
        Expanded(
          child: Text(
            '${wird['wirdType']} - ${wird['surahName']}',
            style: TextStyle(
              color: Colors.grey[800],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildAssessmentItem(Map<String, dynamic> assessment) {
    return Row(
      children: [
        Icon(
          Icons.star,
          color: AppColors.orange1,
          size: 16,
        ),
        SizedBox(width: 8),
        Expanded(
          child: Text(
            '${assessment['wirdType']} - ${assessment['surahName']} (${assessment['grade']})',
            style: TextStyle(
              color: Colors.grey[800],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildAttendanceItem(Map<String, dynamic> attendance) {
    final date = (attendance['date'] as Timestamp).toDate();
    final status = attendance['status'] == 'present' ? 'حاضر' : 'غائب';
    final color = attendance['status'] == 'present'
        ? AppColors.green2
        : Colors.red;

    return Row(
      children: [
        Icon(
          attendance['status'] == 'present'
              ? Icons.check_circle
              : Icons.cancel,
          color: color,
          size: 16,
        ),
        SizedBox(width: 8),
        Expanded(
          child: Text(
            '${date.day}/${date.month}/${date.year} - $status',
            style: TextStyle(
              color: Colors.grey[800],
            ),
          ),
        ),
      ],
    );
  }
} 