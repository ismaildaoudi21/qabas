import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'add_halaqah_page.dart';

class HalaqahDetailsPage extends StatelessWidget {
  final String halaqahId;
  final Map<String, dynamic> halaqahData;

  HalaqahDetailsPage({
    required this.halaqahId,
    required this.halaqahData,
  });

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(
          title: Text('تفاصيل الحلقة'),
          actions: [
            IconButton(
              icon: Icon(Icons.edit),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => AddHalaqahPage(
                      halaqahId: halaqahId,
                      halaqahData: halaqahData,
                    ),
                  ),
                );
              },
            ),
            IconButton(
              icon: Icon(Icons.delete),
              onPressed: () {
                _showDeleteConfirmation(context);
              },
            ),
          ],
        ),
        body: SingleChildScrollView(
          padding: EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildInfoCard(
                title: 'معلومات الحلقة',
                children: [
                  _buildInfoRow('اسم الحلقة', halaqahData['name'] ?? ''),
                  _buildInfoRow('المعلم', halaqahData['teacherName'] ?? ''),
                  _buildInfoRow('الموقع', halaqahData['location'] ?? ''),
                  _buildInfoRow('الجدول', halaqahData['schedule'] ?? ''),
                ],
              ),
              SizedBox(height: 20),
              _buildStudentsList(),
            ],
          ),
        ),
        floatingActionButton: FloatingActionButton(
          onPressed: () => _showAddStudentDialog(context),
          child: Icon(Icons.person_add),
          tooltip: 'إضافة طالب للحلقة',
        ),
      ),
    );
  }

  Widget _buildInfoCard({required String title, required List<Widget> children}) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 16),
            ...children,
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '$label: ',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(fontSize: 16),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStudentsList() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('users')
          .where('halaqahId', isEqualTo: halaqahId)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Center(child: Text('حدث خطأ: ${snapshot.error}'));
        }

        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(child: CircularProgressIndicator());
        }

        final students = snapshot.data?.docs ?? [];

        return Card(
          elevation: 2,
          child: Padding(
            padding: EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'الطلاب المسجلين',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      '${students.length} طالب',
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 16),
                if (students.isEmpty)
                  Center(
                    child: Text(
                      'لا يوجد طلاب مسجلين في هذه الحلقة',
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.grey[600],
                      ),
                    ),
                  )
                else
                  ListView.builder(
                    shrinkWrap: true,
                    physics: NeverScrollableScrollPhysics(),
                    itemCount: students.length,
                    itemBuilder: (context, index) {
                      final studentData = students[index].data() as Map<String, dynamic>;
                      final String studentName = studentData['name'] ?? 'بدون اسم';
                      return ListTile(
                        leading: CircleAvatar(
                          child: Text(studentName.isNotEmpty ? studentName[0] : ''),
                        ),
                        title: Text(studentName),
                        subtitle: Text(studentData['parentName'] ?? ''),
                        trailing: IconButton(
                          icon: Icon(Icons.remove_circle_outline),
                          color: Colors.red,
                          onPressed: () {
                            _showRemoveStudentConfirmation(context, students[index].id);
                          },
                        ),
                      );
                    },
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showDeleteConfirmation(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('تأكيد الحذف'),
        content: Text('هل أنت متأكد من حذف هذه الحلقة؟'),
        actions: [
          TextButton(
            child: Text('إلغاء'),
            onPressed: () => Navigator.pop(context),
          ),
          TextButton(
            child: Text('حذف'),
            onPressed: () async {
              try {
                await FirebaseFirestore.instance
                    .collection('halaqahs')
                    .doc(halaqahId)
                    .delete();
                Navigator.pop(context); // Close dialog
                Navigator.pop(context); // Go back to list
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('حدث خطأ أثناء حذف الحلقة')),
                );
              }
            },
          ),
        ],
      ),
    );
  }

  void _showRemoveStudentConfirmation(BuildContext context, String studentId) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('تأكيد إزالة الطالب'),
        content: Text('هل أنت متأكد من إزالة هذا الطالب من الحلقة؟'),
        actions: [
          TextButton(
            child: Text('إلغاء'),
            onPressed: () => Navigator.pop(context),
          ),
          TextButton(
            child: Text('إزالة'),
            onPressed: () async {
              try {
                await FirebaseFirestore.instance
                    .collection('users')
                    .doc(studentId)
                    .update({'halaqahId': null});
                Navigator.pop(context);
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('حدث خطأ أثناء إزالة الطالب')),
                );
              }
            },
          ),
        ],
      ),
    );
  }

  void _showAddStudentDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('إضافة طالب للحلقة'),
        content: StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance
              .collection('users')
              .where('role', isEqualTo: 'student')
              .where('halaqahId', isNull: true)
              .snapshots(),
          builder: (context, snapshot) {
            if (snapshot.hasError) {
              return Text('حدث خطأ: ${snapshot.error}');
            }

            if (snapshot.connectionState == ConnectionState.waiting) {
              return Center(child: CircularProgressIndicator());
            }

            if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
              return Text('لا يوجد طلاب متاحين للإضافة');
            }

            return Container(
              width: double.maxFinite,
              child: ListView.builder(
                shrinkWrap: true,
                itemCount: snapshot.data!.docs.length,
                itemBuilder: (context, index) {
                  final student = snapshot.data!.docs[index];
                  final studentData = student.data() as Map<String, dynamic>;
                  final studentName = '${studentData['firstName']} ${studentData['lastName']}';

                  return ListTile(
                    title: Text(studentName),
                    onTap: () async {
                      try {
                        await FirebaseFirestore.instance
                            .collection('users')
                            .doc(student.id)
                            .update({
                          'halaqahId': halaqahId,
                          'halaqahName': halaqahData['name'],
                        });

                        Navigator.pop(context);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('تم إضافة الطالب بنجاح')),
                        );
                      } catch (e) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('حدث خطأ أثناء إضافة الطالب: $e')),
                        );
                      }
                    },
                  );
                },
              ),
            );
          },
        ),
        actions: [
          TextButton(
            child: Text('إلغاء'),
            onPressed: () => Navigator.pop(context),
          ),
        ],
      ),
    );
  }

}