// lib/screens/teacher/assessments/assessment_details_page.dart

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart' as intl;
import 'package:qabas/utils/app_colors.dart';

class AssessmentDetailsPage extends StatelessWidget {
  final String assessmentId;
  final Map<String, dynamic> assessmentData;

  const AssessmentDetailsPage({
    Key? key,
    required this.assessmentId,
    required this.assessmentData,
  }) : super(key: key);

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

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(
          title: Text('تفاصيل التقييم'),
          centerTitle: true,
          backgroundColor: AppColors.orange1,
        ),
        body: StreamBuilder<DocumentSnapshot>(
          stream: FirebaseFirestore.instance
              .collection('wird')
              .doc(assessmentData['wirdId'])
              .snapshots(),
          builder: (context, snapshot) {
            if (snapshot.hasError) {
              return Center(child: Text('حدث خطأ'));
            }

            if (snapshot.connectionState == ConnectionState.waiting) {
              return Center(child: CircularProgressIndicator());
            }

            final wirdData = snapshot.data?.data() as Map<String, dynamic>?;

            return SingleChildScrollView(
              padding: EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Card(
                    elevation: 2,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
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
                              color: AppColors.blue1,
                            ),
                          ),
                          SizedBox(height: 12),
                          _buildInfoRow('اسم الطالب:', assessmentData['studentName'] ?? ''),
                          if (wirdData != null) ...[
                            SizedBox(height: 8),
                            _buildInfoRow(
                              'الورد:',
                              'سورة ${wirdData['surahName']} - من آية ${wirdData['startAyah']} إلى ${wirdData['endAyah']}',
                            ),
                          ],
                          SizedBox(height: 8),
                          _buildInfoRow(
                            'تاريخ التقييم:',
                            _formatDate(assessmentData['date']),
                          ),
                        ],
                      ),
                    ),
                  ),
                  SizedBox(height: 16),
                  Card(
                    elevation: 2,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Padding(
                      padding: EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'نتيجة التقييم',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: AppColors.blue1,
                            ),
                          ),
                          SizedBox(height: 12),
                          Container(
                            width: double.infinity,
                            padding: EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                            decoration: BoxDecoration(
                              color: _getGradeColor(assessmentData['grade'] ?? '').withOpacity(0.1),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: _getGradeColor(assessmentData['grade'] ?? ''),
                                width: 2,
                              ),
                            ),
                            child: Column(
                              children: [
                                Text(
                                  'التقدير',
                                  style: TextStyle(
                                    fontSize: 16,
                                    color: _getGradeColor(assessmentData['grade'] ?? ''),
                                  ),
                                ),
                                SizedBox(height: 4),
                                Text(
                                  assessmentData['grade'] ?? '',
                                  style: TextStyle(
                                    fontSize: 24,
                                    fontWeight: FontWeight.bold,
                                    color: _getGradeColor(assessmentData['grade'] ?? ''),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          if (assessmentData['notes']?.isNotEmpty ?? false) ...[
                            SizedBox(height: 16),
                            Text(
                              'ملاحظات المعلم',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: AppColors.blue1,
                              ),
                            ),
                            SizedBox(height: 8),
                            Container(
                              width: double.infinity,
                              padding: EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: Colors.grey[50],
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: Colors.grey[300]!),
                              ),
                              child: Text(
                                assessmentData['notes'],
                                style: TextStyle(
                                  fontSize: 16,
                                  color: Colors.grey[800],
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: Colors.grey[700],
            ),
          ),
          SizedBox(width: 8),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey[800],
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(Timestamp? timestamp) {
    if (timestamp == null) return '';
    return intl.DateFormat('yyyy-MM-dd').format(timestamp.toDate());
  }
}