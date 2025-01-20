import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'add_student_page.dart';
import 'student_details_page.dart';

class StudentsListPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(
          title: Text('الطلاب'),
        ),
        floatingActionButton: FloatingActionButton(
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => AddStudentPage()),
            );
          },
          child: Icon(Icons.add),
          tooltip: 'إضافة طالب جديد',
        ),
        body: StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance
              .collection('users')
              .where('role', isEqualTo: 'student')
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
                    Text('لا يوجد طلاب'),
                    SizedBox(height: 16),
                    ElevatedButton.icon(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => AddStudentPage()),
                        );
                      },
                      icon: Icon(Icons.add),
                      label: Text('إضافة طالب جديد'),
                    ),
                  ],
                ),
              );
            }
      
            return ListView.builder(
              itemCount: snapshot.data!.docs.length,
              padding: EdgeInsets.all(8),
              itemBuilder: (context, index) {
                var student = snapshot.data!.docs[index];
                var studentData = student.data() as Map<String, dynamic>;
                final String studentName = 
                    '${studentData['firstName'] ?? ''} ${studentData['lastName'] ?? ''}';
                
                return Card(
                  elevation: 2,
                  margin: EdgeInsets.symmetric(vertical: 4, horizontal: 8),
                  child: ListTile(
                    leading: CircleAvatar(
                      child: Text(studentName.isNotEmpty ? studentName[0] : ''),
                    ),
                    title: Text(studentName),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(studentData['email'] ?? ''),
                        Text(studentData['halaqahName'] ?? 'لا توجد حلقة'),
                      ],
                    ),
                    isThreeLine: true,
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => StudentDetailsPage(studentId: student.id, studentData: studentData),
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
                              content: Text('هل أنت متأكد من حذف هذا الطالب؟'),
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
                                        .doc(student.id)
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