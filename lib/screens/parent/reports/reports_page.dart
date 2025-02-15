import 'package:flutter/material.dart' hide TextDirection;
import 'package:flutter/material.dart' show TextDirection;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:qabas/utils/app_colors.dart';
import 'package:intl/intl.dart' as intl; 

class ReportsPage extends StatelessWidget {
  final String parentId;

  const ReportsPage({Key? key, required this.parentId}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(
          title: Text('التقارير'),
          backgroundColor: AppColors.blue1,
        ),
        body: StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance
              .collection('users')
              .where('role', isEqualTo: 'student')
              .where('parentId', isEqualTo: parentId)
              .snapshots(),
          builder: (context, snapshot) {
            if (snapshot.hasError) {
              return Center(child: Text('حدث خطأ في تحميل البيانات'));
            }

            if (snapshot.connectionState == ConnectionState.waiting) {
              return Center(child: CircularProgressIndicator());
            }

            if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
              return Center(child: Text('لا يوجد تقارير متاحة'));
            }

            return ListView.builder(
              padding: EdgeInsets.all(16),
              itemCount: snapshot.data!.docs.length,
              itemBuilder: (context, index) {
                final doc = snapshot.data!.docs[index];
                final data = doc.data() as Map<String, dynamic>;
                
                return Card(
                  elevation: 2,
                  margin: EdgeInsets.only(bottom: 16),
                  child: Padding(
                    padding: EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${data['firstName']} ${data['lastName']}',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        if (data['halaqahId'] != null)
                          FutureBuilder<DocumentSnapshot>(
                            future: FirebaseFirestore.instance
                                .collection('halaqahs')
                                .doc(data['halaqahId'])
                                .get(),
                            builder: (context, halaqahSnapshot) {
                              if (halaqahSnapshot.hasData && halaqahSnapshot.data!.exists) {
                                final halaqahData = halaqahSnapshot.data!.data() as Map<String, dynamic>;
                                return Text(
                                  'الحلقة: ${halaqahData['name'] ?? 'غير محدد'}',
                                  style: TextStyle(color: Colors.grey[600]),
                                );
                              }
                              return Text(
                                'الحلقة: غير محدد',
                                style: TextStyle(color: Colors.grey[600]),
                              );
                            },
                          ),
                        SizedBox(height: 16),
                        _buildProgressSection(doc.id),
                        SizedBox(height: 16),
                        _buildAttendanceSection(doc.id),
                        SizedBox(height: 16),
                        _buildAssessmentsSection(doc.id),
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

  Widget _buildProgressSection(String studentId) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('wird')
          .where('studentId', isEqualTo: studentId)
          .where('status', isEqualTo: 'completed')
          .orderBy('completionDate', descending: true)
          .limit(5)
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return SizedBox.shrink();
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'تقدم الورد',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 8),
            if (snapshot.data!.docs.isEmpty)
              Text('لم يتم إكمال أي ورد بعد')
            else
              Column(
                children: snapshot.data!.docs.map((doc) {
                  final wird = doc.data() as Map<String, dynamic>;
                  return ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: Icon(Icons.check_circle, color: AppColors.green2),
                    title: Text('${wird['wirdType']} - ${wird['surahName']}'),
                    subtitle: Text(
                      intl.DateFormat('yyyy/MM/dd').format(wird['completionDate'].toDate()),
                    ),
                  );
                }).toList(),
              ),
          ],
        );
      },
    );
  }

  Widget _buildAttendanceSection(String studentId) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('attendance')
          .where('studentId', isEqualTo: studentId)
          .orderBy('date', descending: true)
          .limit(5)
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return SizedBox.shrink();
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'سجل الحضور',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 8),
            if (snapshot.data!.docs.isEmpty)
              Text('لا يوجد سجل حضور')
            else
              Column(
                children: snapshot.data!.docs.map((doc) {
                  final attendance = doc.data() as Map<String, dynamic>;
                  return ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: Icon(
                      attendance['status'] == 'present' 
                          ? Icons.check_circle 
                          : Icons.cancel,
                      color: attendance['status'] == 'present' 
                          ? AppColors.green2 
                          : Colors.red,
                    ),
                    title: Text(
                      attendance['status'] == 'present' ? 'حاضر' : 'غائب'
                    ),
                    subtitle: Text(
                      intl.DateFormat('yyyy/MM/dd').format(attendance['date'].toDate()),
                    ),
                  );
                }).toList(),
              ),
          ],
        );
      },
    );
  }

  Widget _buildAssessmentsSection(String studentId) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('assessments')
          .where('studentId', isEqualTo: studentId)
          .orderBy('date', descending: true)
          .limit(5)
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return SizedBox.shrink();
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'التقييمات',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 8),
            if (snapshot.data!.docs.isEmpty)
              Text('لا يوجد تقييمات')
            else
              Column(
                children: snapshot.data!.docs.map((doc) {
                  final assessment = doc.data() as Map<String, dynamic>;
                  return ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: Icon(Icons.star, color: AppColors.orange1),
                    title: Text('${assessment['wirdType']} - ${assessment['surahName']}'),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'التقدير: ${assessment['grade']}',
                        ),
                        Text(
                          intl.DateFormat('yyyy/MM/dd').format(assessment['date'].toDate()),
                        ),
                      ],
                    ),
                  );
                }).toList(),
              ),
          ],
        );
      },
    );
  }
} 