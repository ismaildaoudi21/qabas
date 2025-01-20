import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'add_teacher_page.dart';
import 'teacher_details_page.dart';

class TeacherListPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(
          title: Text('المعلمون'),
        ),
        floatingActionButton: FloatingActionButton(
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => AddTeacherPage()),
            );
          },
          child: Icon(Icons.add),
          tooltip: 'إضافة معلم جديد',
        ),
        body: StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance
              .collection('users')
              .where('role', isEqualTo: 'teacher')
              .snapshots(),
          builder: (context, snapshot) {
            if (snapshot.hasError) {
              return Center(child: Text('حدث خطأ: ${snapshot.error}'));
            }

            if (snapshot.connectionState == ConnectionState.waiting) {
              return Center(child: CircularProgressIndicator());
            }

            if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text('لا يوجد معلمين'),
                    SizedBox(height: 16),
                    ElevatedButton.icon(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => AddTeacherPage()),
                        );
                      },
                      icon: Icon(Icons.add),
                      label: Text('إضافة معلم جديد'),
                    ),
                  ],
                ),
              );
            }

            return ListView.builder(
              itemCount: snapshot.data!.docs.length,
              padding: EdgeInsets.all(8),
              itemBuilder: (context, index) {
                var teacher = snapshot.data!.docs[index];
                var teacherData = teacher.data() as Map<String, dynamic>;
                final String teacherName = 
                    '${teacherData['firstName']} ${teacherData['lastName']}';

                return Card(
                  elevation: 2,
                  margin: EdgeInsets.symmetric(vertical: 4, horizontal: 8),
                  child: ListTile(
                    leading: CircleAvatar(
                      child: Text(teacherName.isNotEmpty ? teacherName[0] : ''),
                    ),
                    title: Text(teacherName),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(teacherData['email'] ?? ''),
                        Text(teacherData['phoneNumber'] ?? ''),
                      ],
                    ),
                    isThreeLine: true,
                    onTap: () async {
                      final teacherDoc = await FirebaseFirestore.instance
                          .collection('users')
                          .doc(teacher.id)
                          .get();
                      
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => TeacherDetailsPage(
                            teacherId: teacher.id,
                            teacherData: teacherDoc.data() ?? {},
                          ),
                        ),
                      );
                    },
                    trailing: PopupMenuButton(
                      onSelected: (value) async {
                        if (value == 'delete') {
                          showDialog(
                            context: context,
                            builder: (context) => AlertDialog(
                              title: Text('تأكيد الحذف'),
                              content: Text('هل أنت متأكد من حذف هذا المعلم؟'),
                              actions: [
                                TextButton(
                                  child: Text('إلغاء'),
                                  onPressed: () => Navigator.pop(context),
                                ),
                                TextButton(
                                  child: Text('حذف'),
                                  onPressed: () async {
                                    await FirebaseFirestore.instance
                                        .collection('users')
                                        .doc(teacher.id)
                                        .delete();
                                    Navigator.pop(context);
                                  },
                                ),
                              ],
                            ),
                          );
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
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }
}