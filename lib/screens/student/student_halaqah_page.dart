import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:qabas/utils/app_colors.dart';

class StudentHalaqahPage extends StatelessWidget {
  final String studentId;

  const StudentHalaqahPage({Key? key, required this.studentId}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(
          title: Text('حلقتي'),
          centerTitle: true,
          backgroundColor: AppColors.blue1,
        ),
        body: StreamBuilder<DocumentSnapshot>(
          stream: FirebaseFirestore.instance
              .collection('users')
              .doc(studentId)
              .snapshots(),
          builder: (context, snapshot) {
            if (snapshot.hasError) {
              return Center(child: Text('حدث خطأ في تحميل البيانات'));
            }

            if (snapshot.connectionState == ConnectionState.waiting) {
              return Center(child: CircularProgressIndicator());
            }

            if (!snapshot.hasData || !snapshot.data!.exists) {
              return Center(child: Text('لا يوجد بيانات للطالب'));
            }

            final studentData = snapshot.data!.data() as Map<String, dynamic>;
            final halaqahId = studentData['halaqahId'];

            if (halaqahId == null) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.class_outlined, size: 64, color: Colors.grey),
                    SizedBox(height: 16),
                    Text(
                      'لم يتم تعيينك في حلقة بعد',
                      style: TextStyle(fontSize: 18, color: Colors.grey[600]),
                    ),
                  ],
                ),
              );
            }

            return StreamBuilder<DocumentSnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('halaqahs')
                  .doc(halaqahId)
                  .snapshots(),
              builder: (context, halaqahSnapshot) {
                if (halaqahSnapshot.hasError) {
                  return Center(child: Text('حدث خطأ في تحميل بيانات الحلقة'));
                }

                if (halaqahSnapshot.connectionState == ConnectionState.waiting) {
                  return Center(child: CircularProgressIndicator());
                }

                if (!halaqahSnapshot.hasData || !halaqahSnapshot.data!.exists) {
                  return Center(child: Text('لا يوجد بيانات للحلقة'));
                }

                final halaqahData = halaqahSnapshot.data!.data() as Map<String, dynamic>;

                return SingleChildScrollView(
                  padding: EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildHalaqahHeader(halaqahData),
                      SizedBox(height: 24),
                      _buildInfoCard('معلومات الحلقة', [
                        _buildInfoRow('اسم الحلقة:', halaqahData['name'] ?? ''),
                        _buildInfoRow('الجدول:', halaqahData['schedule'] ?? ''),
                        _buildInfoRow('الموقع:', halaqahData['location'] ?? ''),
                      ]),
                      SizedBox(height: 24),
                      _buildTeacherInfo(halaqahData['teacherId']),
                      SizedBox(height: 24),
                      _buildClassmatesList(halaqahId),
                    ],
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }

  Widget _buildHalaqahHeader(Map<String, dynamic> halaqahData) {
    return Card(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      elevation: 2,
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Row(
          children: [
            CircleAvatar(
              radius: 32,
              backgroundColor: AppColors.blue1.withOpacity(0.2),
              child: Icon(
                Icons.class_,
                size: 32,
                color: AppColors.blue1,
              ),
            ),
            SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    halaqahData['name'] ?? '',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoCard(String title, List<Widget> children) {
    return Card(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      elevation: 2,
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppColors.blue1,
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
      padding: EdgeInsets.only(bottom: 8),
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
              value.isEmpty ? 'غير متوفر' : value,
              style: TextStyle(
                color: value.isEmpty ? Colors.grey : Colors.black,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTeacherInfo(String? teacherId) {
    if (teacherId == null) return SizedBox.shrink();

    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance
          .collection('users')
          .doc(teacherId)
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData || !snapshot.data!.exists) {
          return SizedBox.shrink();
        }

        final teacherData = snapshot.data!.data() as Map<String, dynamic>;

        return Card(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          elevation: 2,
          child: Padding(
            padding: EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'معلم الحلقة',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppColors.blue1,
                  ),
                ),
                SizedBox(height: 16),
                Row(
                  children: [
                    CircleAvatar(
                      backgroundColor: AppColors.blue1.withOpacity(0.2),
                      child: Icon(Icons.person, color: AppColors.blue1),
                    ),
                    SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '${teacherData['firstName']} ${teacherData['lastName']}',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          if (teacherData['phoneNumber'] != null)
                            Text(
                              teacherData['phoneNumber'],
                              style: TextStyle(color: Colors.grey[600]),
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildClassmatesList(String halaqahId) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('users')
          .where('halaqahId', isEqualTo: halaqahId)
          .where('role', isEqualTo: 'student')
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return SizedBox.shrink();
        }

        final students = snapshot.data!.docs;

        return Card(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          elevation: 2,
          child: Padding(
            padding: EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'زملائي في الحلقة',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppColors.blue1,
                  ),
                ),
                SizedBox(height: 16),
                ListView.builder(
                  shrinkWrap: true,
                  physics: NeverScrollableScrollPhysics(),
                  itemCount: students.length,
                  itemBuilder: (context, index) {
                    final student = students[index].data() as Map<String, dynamic>;
                    // Don't show the current student in the list
                    if (students[index].id == studentId) return SizedBox.shrink();

                    return ListTile(
                      leading: CircleAvatar(
                        backgroundColor: AppColors.orange1.withOpacity(0.2),
                        child: Icon(Icons.person, color: AppColors.orange1),
                      ),
                      title: Text(
                        '${student['firstName']} ${student['lastName']}',
                        style: TextStyle(fontWeight: FontWeight.bold),
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
} 