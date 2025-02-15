import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:qabas/utils/app_colors.dart';
import 'package:qabas/screens/teacher/wird/teacher_wird_management.dart';

class StudentsPage extends StatelessWidget {
  final String teacherId;

  StudentsPage({required this.teacherId});

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(
          title: Text('طلابي'),
          backgroundColor: Colors.transparent,
          elevation: 0,
          foregroundColor: Colors.black,
        ),
        backgroundColor: const Color(0xFFFFFBF7),
        body: StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance
              .collection('halaqahs')
              .where('teacherId', isEqualTo: teacherId)
              .snapshots(),
          builder: (context, halaqahSnapshot) {
            if (halaqahSnapshot.hasError) {
              return Center(child: Text('حدث خطأ ما'));
            }

            if (halaqahSnapshot.connectionState == ConnectionState.waiting) {
              return Center(child: CircularProgressIndicator());
            }

            if (!halaqahSnapshot.hasData || halaqahSnapshot.data!.docs.isEmpty) {
              return Center(child: Text('لا توجد حلقات مسندة إليك'));
            }

            List<String> halaqahIds = halaqahSnapshot.data!.docs
                .map((doc) => doc.id)
                .toList();

            return StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('users')
                  .where('halaqahId', whereIn: halaqahIds)
                  .where('role', isEqualTo: 'student')
                  .snapshots(),
              builder: (context, studentSnapshot) {
                if (studentSnapshot.hasError) {
                  return Center(child: Text('حدث خطأ ما'));
                }

                if (studentSnapshot.connectionState == ConnectionState.waiting) {
                  return Center(child: CircularProgressIndicator());
                }

                if (!studentSnapshot.hasData || studentSnapshot.data!.docs.isEmpty) {
                  return Center(child: Text('لا يوجد طلاب في حلقاتك'));
                }

                return ListView.builder(
                  padding: EdgeInsets.all(16),
                  itemCount: studentSnapshot.data!.docs.length,
                  itemBuilder: (context, index) {
                    final student = studentSnapshot.data!.docs[index].data() 
                        as Map<String, dynamic>;
                    final studentId = studentSnapshot.data!.docs[index].id;

                    return Card(
                      elevation: 2,
                      margin: EdgeInsets.only(bottom: 12),
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: AppColors.orange1,
                          child: Text(
                            student['name']?[0] ?? '?',
                            style: TextStyle(color: Colors.white),
                          ),
                        ),
                        title: Text(student['name'] ?? 'بدون اسم'),
                        subtitle: FutureBuilder<DocumentSnapshot>(
                          future: FirebaseFirestore.instance
                              .collection('halaqahs')
                              .doc(student['halaqahId'])
                              .get(),
                          builder: (context, halaqahDoc) {
                            if (halaqahDoc.hasData && halaqahDoc.data != null) {
                              final halaqahData = halaqahDoc.data!.data() 
                                  as Map<String, dynamic>?;
                              return Text(
                                'الحلقة: ${halaqahData?['name'] ?? 'غير معروفة'}',
                              );
                            }
                            return Text('جاري تحميل معلومات الحلقة...');
                          },
                        ),
                        trailing: IconButton(
                          icon: Icon(Icons.menu_book, color: AppColors.orange1),
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => TeacherWirdManagement(
                                  studentId: studentId,
                                  studentName: student['name'] ?? 'بدون اسم',
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    );
                  },
                );
              },
            );
          },
        ),
      ),
    );
  }
} 