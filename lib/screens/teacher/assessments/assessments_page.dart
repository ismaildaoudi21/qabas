// lib/screens/teacher/assessments/assessments_page.dart

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:qabas/utils/app_colors.dart';
import 'add_assessment_page.dart';
import 'assessment_details_page.dart';
import 'package:intl/intl.dart' as intl;

class AssessmentsPage extends StatelessWidget {
  final String teacherId;
  final String halaqahId;
  final String halaqahName;

  const AssessmentsPage({
    Key? key,
    required this.teacherId,
    required this.halaqahId,
    required this.halaqahName,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(
          title: Text('التقييمات'),
          centerTitle: true,
          backgroundColor: AppColors.orange1,
        ),
        body: StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance
              .collection('users')
              .where('halaqahId', isEqualTo: halaqahId)
              .where('role', isEqualTo: 'student')
              .snapshots(),
          builder: (context, snapshot) {
            if (snapshot.hasError) {
              return Center(child: Text('حدث خطأ في تحميل البيانات'));
            }

            if (snapshot.connectionState == ConnectionState.waiting) {
              return Center(child: CircularProgressIndicator());
            }

            final students = snapshot.data?.docs ?? [];

            if (students.isEmpty) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.people_outline, size: 64, color: Colors.grey),
                    SizedBox(height: 16),
                    Text(
                      'لا يوجد طلاب في هذه الحلقة',
                      style: TextStyle(fontSize: 18, color: Colors.grey[600]),
                    ),
                  ],
                ),
              );
            }

            return ListView.builder(
              padding: EdgeInsets.all(16),
              itemCount: students.length,
              itemBuilder: (context, index) {
                final student = students[index].data() as Map<String, dynamic>;

                return Card(
                  margin: EdgeInsets.only(bottom: 8),
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: AppColors.orange1.withOpacity(0.2),
                      child: Icon(Icons.person, color: AppColors.orange1),
                    ),
                    title: Text(
                      '${student['firstName']} ${student['lastName']}',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    subtitle: StreamBuilder<QuerySnapshot>(
                      stream: FirebaseFirestore.instance
                          .collection('wird_assessments')
                          .where('studentId', isEqualTo: students[index].id)
                          .orderBy('date', descending: true)
                          .limit(1)
                          .snapshots(),
                      builder: (context, assessmentSnapshot) {
                        if (!assessmentSnapshot.hasData || assessmentSnapshot.data!.docs.isEmpty) {
                          return Text('لا يوجد تقييمات سابقة');
                        }

                        final latestAssessment = assessmentSnapshot.data!.docs.first.data() as Map<String, dynamic>;
                        return Text(
                          'آخر تقييم: ${latestAssessment['grade'] ?? 'غير محدد'}',
                          style: TextStyle(
                            color: _getGradeColor(latestAssessment['grade'] ?? ''),
                            fontWeight: FontWeight.bold,
                          ),
                        );
                      },
                    ),
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }

  Color _getGradeColor(String grade) {
    switch (grade) {
      case 'ممتاز':
        return AppColors.blue1;
      case 'جيد جداً':
        return AppColors.orange1;
      case 'جيد':
        return AppColors.blue3;
      case 'يكرر':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }
}

class _CurrentAssessmentsTab extends StatelessWidget {
  final String teacherId;

  const _CurrentAssessmentsTab({Key? key, required this.teacherId}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('wird_assessments')
          .where('teacherId', isEqualTo: teacherId)
          .where('isCompleted', isEqualTo: false)
          .orderBy('date', descending: true)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Center(child: Text('حدث خطأ'));
        }

        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(child: CircularProgressIndicator());
        }

        final assessments = snapshot.data?.docs ?? [];

        if (assessments.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.assessment_outlined, size: 64, color: Colors.grey),
                SizedBox(height: 16),
                Text(
                  'لا توجد تقييمات حالية',
                  style: TextStyle(
                    fontSize: 18,
                    color: Colors.grey[600],
                  ),
                ),
                SizedBox(height: 8),
                Text(
                  'اضغط على + لإضافة تقييم جديد',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[500],
                  ),
                ),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: EdgeInsets.all(16),
          itemCount: assessments.length,
          itemBuilder: (context, index) {
            final assessment = assessments[index];
            final data = assessment.data() as Map<String, dynamic>;

            return Card(
              elevation: 2,
              margin: EdgeInsets.only(bottom: 16),
              child: InkWell(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => AssessmentDetailsPage(
                        assessmentId: assessment.id,
                        assessmentData: data,
                      ),
                    ),
                  );
                },
                child: Padding(
                  padding: EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  data['studentName'] ?? '',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.blue1,
                                  ),
                                ),
                                if (data['grade'] != null) ...[
                                  SizedBox(height: 4),
                                  Text(
                                    'التقدير: ${data['grade']}',
                                    style: TextStyle(
                                      color: _getGradeColor(data['grade']),
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                                SizedBox(height: 4),
                                if (data['notes']?.isNotEmpty ?? false)
                                  Text(
                                    'الملاحظات: ${data['notes']}',
                                    style: TextStyle(
                                      color: Colors.grey[600],
                                    ),
                                  ),
                              ],
                            ),
                          ),
                          PopupMenuButton(
                            icon: Icon(Icons.more_vert, color: AppColors.blue1),
                            onSelected: (value) async {
                              if (value == 'delete') {
                                _showDeleteConfirmation(context, assessment.id);
                              }
                            },
                            itemBuilder: (context) => [
                              PopupMenuItem(
                                value: 'delete',
                                child: Row(
                                  children: [
                                    Icon(Icons.delete, color: Colors.red),
                                    SizedBox(width: 8),
                                    Text('حذف'),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                      if (data['date'] != null) ...[
                        SizedBox(height: 8),
                        Text(
                          'تاريخ التقييم: ${_formatDate(data['date'])}',
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  Color _getGradeColor(String grade) {
    switch (grade) {
      case 'ممتاز':
        return AppColors.blue1;
      case 'جيد جداً':
        return AppColors.orange1;
      case 'جيد':
        return AppColors.blue3;
      case 'يكرر':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  void _showDeleteConfirmation(BuildContext context, String assessmentId) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('تأكيد الحذف'),
        content: Text('هل أنت متأكد من حذف هذا التقييم؟'),
        actions: [
          TextButton(
            child: Text('إلغاء'),
            onPressed: () => Navigator.pop(context),
          ),
          ElevatedButton(
            child: Text('حذف'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
            ),
            onPressed: () async {
              await FirebaseFirestore.instance
                  .collection('wird_assessments')
                  .doc(assessmentId)
                  .delete();
              Navigator.pop(context);
            },
          ),
        ],
      ),
    );
  }
}

class _AssessmentHistoryTab extends StatelessWidget {
  final String teacherId;

  const _AssessmentHistoryTab({Key? key, required this.teacherId}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('wird_assessments')
          .where('teacherId', isEqualTo: teacherId)
          .where('isCompleted', isEqualTo: true)
          .orderBy('completionDate', descending: true)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Center(child: Text('حدث خطأ'));
        }

        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(child: CircularProgressIndicator());
        }

        final assessments = snapshot.data?.docs ?? [];

        if (assessments.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.history, size: 64, color: Colors.grey),
                SizedBox(height: 16),
                Text(
                  'لا يوجد سجل تقييمات سابقة',
                  style: TextStyle(
                    fontSize: 18,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: EdgeInsets.all(16),
          itemCount: assessments.length,
          itemBuilder: (context, index) {
            final assessment = assessments[index];
            final data = assessment.data() as Map<String, dynamic>;

            return Card(
              margin: EdgeInsets.only(bottom: 8),
              child: ListTile(
                title: Text(
                  data['studentName'] ?? '',
                  style: TextStyle(
                    color: AppColors.blue1,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('التقدير: ${data['grade'] ?? ''}'),
                    Text(
                      'تاريخ التقييم: ${_formatDate(data['completionDate'])}',
                      style: TextStyle(color: AppColors.orange1),
                    ),
                  ],
                ),
                isThreeLine: true,
                leading: CircleAvatar(
                  backgroundColor: _getGradeColor(data['grade'] ?? ''),
                  child: Icon(Icons.check, color: Colors.white),
                ),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => AssessmentDetailsPage(
                        assessmentId: assessment.id,
                        assessmentData: data,
                      ),
                    ),
                  );
                },
              ),
            );
          },
        );
      },
    );
  }

  Color _getGradeColor(String grade) {
    switch (grade) {
      case 'ممتاز':
        return AppColors.blue1;
      case 'جيد جداً':
        return AppColors.orange1;
      case 'جيد':
        return AppColors.blue3;
      case 'يكرر':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }
}

String _formatDate(Timestamp? timestamp) {
  if (timestamp == null) return '';
  return intl.DateFormat('yyyy-MM-dd').format(timestamp.toDate());
}