// lib/screens/teacher/teacher_wird_page.dart

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:qabas/utils/app_colors.dart';
import 'teacher_wird_management.dart';

class TeacherWirdPage extends StatelessWidget {
  final String teacherId;
  
  TeacherWirdPage({required this.teacherId});
  
  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('halaqahs')
          .where('teacherId', isEqualTo: teacherId)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError) return Center(child: Text('حدث خطأ'));
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(child: CircularProgressIndicator());
        }

        final halaqahs = snapshot.data?.docs ?? [];
        final halaqahIds = halaqahs.map((doc) => doc.id).toList();

        return Directionality(
          textDirection: TextDirection.rtl,
          child: Scaffold(
            appBar: AppBar(
              title: Text('إدارة الورد اليومي'),
              centerTitle: true,
              backgroundColor: AppColors.orange1,
            ),
            body: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('users')
                  .where('halaqahId', whereIn: halaqahIds)
                  .where('role', isEqualTo: 'student')
                  .snapshots(),
              builder: (context, studentsSnapshot) {
                if (studentsSnapshot.hasError) return Center(child: Text('حدث خطأ'));
                if (studentsSnapshot.connectionState == ConnectionState.waiting) {
                  return Center(child: CircularProgressIndicator());
                }

                final students = studentsSnapshot.data?.docs ?? [];
                if (students.isEmpty) {
                  return Center(child: Text('لا يوجد طلاب'));
                }

                // Group students by halaqah
                Map<String, List<QueryDocumentSnapshot>> studentsByHalaqah = {};
                for (var student in students) {
                  final data = student.data() as Map<String, dynamic>;
                  final halaqahId = data['halaqahId'] as String;
                  if (!studentsByHalaqah.containsKey(halaqahId)) {
                    studentsByHalaqah[halaqahId] = [];
                  }
                  studentsByHalaqah[halaqahId]!.add(student);
                }
                
                return ListView.builder(
                  padding: EdgeInsets.all(16),
                  itemCount: halaqahs.length,
                  itemBuilder: (context, index) {
                    final halaqah = halaqahs[index];
                    final halaqahData = halaqah.data() as Map<String, dynamic>;
                    final halaqahStudents = studentsByHalaqah[halaqah.id] ?? [];

                    if (halaqahStudents.isEmpty) return SizedBox.shrink();

                    return Card(
                      margin: EdgeInsets.only(bottom: 16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            padding: EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: AppColors.orange1.withOpacity(0.1),
                              borderRadius: BorderRadius.vertical(
                                top: Radius.circular(4),
                              ),
                            ),
                            child: Row(
                              children: [
                                Icon(Icons.class_, color: AppColors.orange1),
                                SizedBox(width: 8),
                                Text(
                                  halaqahData['name'] ?? '',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.blue1,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          ListView.builder(
                            shrinkWrap: true,
                            physics: NeverScrollableScrollPhysics(),
                            itemCount: halaqahStudents.length,
                            itemBuilder: (context, studentIndex) {
                              final student = halaqahStudents[studentIndex];
                              final studentData = student.data() as Map<String, dynamic>;
                              
                              return StreamBuilder<QuerySnapshot>(
                                stream: FirebaseFirestore.instance
                                    .collection('wird')
                                    .where('studentId', isEqualTo: student.id)
                                    .where('status', whereIn: ['assigned', 'in_progress'])
                                    .snapshots(),
                                builder: (context, wirdSnapshot) {
                                  final hasActiveWird = (wirdSnapshot.data?.docs.length ?? 0) > 0;
                                  
                                  return ListTile(
                                    title: Text(
                                      '${studentData['firstName']} ${studentData['lastName']}',
                                      style: TextStyle(fontWeight: FontWeight.bold),
                                    ),
                                    subtitle: Text(
                                      hasActiveWird ? 'لديه ورد حالي' : 'لا يوجد ورد حالي',
                                      style: TextStyle(
                                        color: hasActiveWird ? Colors.green : Colors.red,
                                      ),
                                    ),
                                    leading: CircleAvatar(
                                      backgroundColor: hasActiveWird ? AppColors.blue1 : Colors.grey,
                                      child: Icon(
                                        Icons.person,
                                        color: Colors.white,
                                      ),
                                    ),
                                    trailing: Icon(Icons.arrow_forward_ios),
                                    onTap: () {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (context) => TeacherWirdManagement(
                                            studentId: student.id,
                                            studentName: '${studentData['firstName']} ${studentData['lastName']}',
                                          ),
                                        ),
                                      );
                                    },
                                  );
                                },
                              );
                            },
                          ),
                        ],
                      ),
                    );
                  },
                );
              },
            ),
          ),
        );
      },
    );
  }
}