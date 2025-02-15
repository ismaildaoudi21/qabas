import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:qabas/utils/app_colors.dart';
import 'package:intl/intl.dart' as intl;

class StudentAssessmentsPage extends StatelessWidget {
  final String studentId;

  StudentAssessmentsPage({required this.studentId});

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(
          title: Text('تقييماتي'),
          backgroundColor: Colors.transparent,
          elevation: 0,
          foregroundColor: Colors.black,
        ),
        backgroundColor: const Color(0xFFFFFBF7),
        body: StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance
              .collection('wird')
              .where('studentId', isEqualTo: studentId)
              .where('status', isEqualTo: 'completed')
              .orderBy('assessmentDate', descending: true)
              .snapshots(),
          builder: (context, snapshot) {
            if (snapshot.hasError) {
              return Center(child: Text('حدث خطأ ما'));
            }

            if (snapshot.connectionState == ConnectionState.waiting) {
              return Center(child: CircularProgressIndicator());
            }

            final wirds = snapshot.data?.docs ?? [];
            
            if (wirds.isEmpty) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.assessment_outlined, size: 64, color: Colors.grey),
                    SizedBox(height: 16),
                    Text(
                      'لا يوجد تقييمات حالياً',
                      style: TextStyle(fontSize: 18, color: Colors.grey[600]),
                    ),
                  ],
                ),
              );
            }

            return ListView.builder(
              padding: EdgeInsets.all(16),
              itemCount: wirds.length,
              itemBuilder: (context, index) {
                final wird = wirds[index].data() as Map<String, dynamic>;
                return Card(
                  margin: EdgeInsets.only(bottom: 16),
                  child: Padding(
                    padding: EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              _formatDate(wird['assessmentDate']),
                              style: TextStyle(color: Colors.grey),
                            ),
                            Text(
                              wird['wirdType'] ?? '',
                              style: TextStyle(
                                color: AppColors.orange1,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: 12),
                        Text(
                          wird['wirdType'] == 'ورد المتن'
                          ? '${wird['surahName']}'
                          : 'سورة ${wird['surahName']}',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          wird['wirdType'] == 'ورد المتن'
                          ? 'من ${wird['startPoint']} إلى ${wird['endPoint']}'
                          : 'من آية ${wird['startAyah']} إلى آية ${wird['endAyah']}',
                          style: TextStyle(color: Colors.grey[700]),
                        ),
                        SizedBox(height: 12),
                        Container(
                          padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          decoration: BoxDecoration(
                            color: AppColors.orange1.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            'التقدير: ${wird['grade']}',
                            style: TextStyle(
                              color: AppColors.orange1,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        if (wird['assessmentNotes']?.isNotEmpty ?? false) ...[
                          SizedBox(height: 12),
                          Text(
                            'ملاحظات: ${wird['assessmentNotes']}',
                            style: TextStyle(color: Colors.grey[600]),
                          ),
                        ],
                      ],
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

  String _formatDate(Timestamp timestamp) {
    return intl.DateFormat('yyyy/MM/dd').format(timestamp.toDate());
  }
} 