import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:qabas/utils/app_colors.dart';
import 'package:intl/intl.dart' as intl;

class StudentAssessmentsPage extends StatelessWidget {
  final String teacherId;

  const StudentAssessmentsPage({
    Key? key,
    required this.teacherId,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(
          title: Text(
            'التقييمات',
            style: TextStyle(fontFamily: 'Tajwal'),
          ),
          backgroundColor: AppColors.orange1,
        ),
        body: StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance
              .collection('halaqahs')
              .where('teacherId', isEqualTo: teacherId)
              .snapshots(),
          builder: (context, halaqahSnapshot) {
            if (halaqahSnapshot.hasError) {
              return Center(child: Text(
                'حدث خطأ في تحميل البيانات',
                style: TextStyle(fontFamily: 'Tajwal'),
              ));
            }

            if (halaqahSnapshot.connectionState == ConnectionState.waiting) {
              return Center(child: CircularProgressIndicator());
            }

            final halaqahs = halaqahSnapshot.data?.docs ?? [];
            if (halaqahs.isEmpty) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.group_off, size: 64, color: Colors.grey),
                    SizedBox(height: 16),
                    Text(
                      'لا توجد حلقات مسندة إليك',
                      style: TextStyle(
                        fontSize: 18,
                        color: Colors.grey,
                        fontFamily: 'Tajwal',
                      ),
                    ),
                  ],
                ),
              );
            }

            final halaqahIds = halaqahs.map((doc) => doc.id).toList();

            return StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('users')
                  .where('halaqahId', whereIn: halaqahIds)
                  .where('role', isEqualTo: 'student')
                  .snapshots(),
              builder: (context, studentSnapshot) {
                if (studentSnapshot.hasError) {
                  return Center(child: Text(
                    'حدث خطأ في تحميل بيانات الطلاب',
                    style: TextStyle(fontFamily: 'Tajwal'),
                  ));
                }

                if (studentSnapshot.connectionState == ConnectionState.waiting) {
                  return Center(child: CircularProgressIndicator());
                }

                final students = studentSnapshot.data?.docs ?? [];
                if (students.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.person_off, size: 64, color: Colors.grey),
                        SizedBox(height: 16),
                        Text(
                          'لا يوجد طلاب في حلقاتك',
                          style: TextStyle(
                            fontSize: 18,
                            color: Colors.grey,
                            fontFamily: 'Tajwal',
                          ),
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
                    final studentId = students[index].id;
                    final halaqahId = student['halaqahId'] as String?;

                    return Card(
                      margin: EdgeInsets.only(bottom: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(15),
                      ),
                      child: InkWell(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => StudentRecordPage(
                                studentId: studentId,
                                studentName: '${student['firstName']} ${student['lastName']}',
                              ),
                            ),
                          );
                        },
                        child: Padding(
                          padding: EdgeInsets.all(16),
                          child: Row(
                            children: [
                              CircleAvatar(
                                radius: 25,
                                backgroundColor: Colors.grey[200],
                                child: Icon(
                                  Icons.person,
                                  color: Colors.grey,
                                ),
                              ),
                              SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      '${student['firstName']} ${student['lastName']}',
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                        fontFamily: 'Tajwal',
                                      ),
                                    ),
                                    if (halaqahId != null)
                                      FutureBuilder<DocumentSnapshot>(
                                        future: FirebaseFirestore.instance
                                            .collection('halaqahs')
                                            .doc(halaqahId)
                                            .get(),
                                        builder: (context, halaqahDoc) {
                                          if (halaqahDoc.hasData && halaqahDoc.data != null) {
                                            final halaqahData = halaqahDoc.data!.data() 
                                                as Map<String, dynamic>?;
                                            return Text(
                                              'الحلقة: ${halaqahData?['name'] ?? 'غير معروفة'}',
                                              style: TextStyle(
                                                color: Colors.grey[600],
                                                fontFamily: 'Tajwal',
                                              ),
                                            );
                                          }
                                          return Text(
                                            'جاري تحميل معلومات الحلقة...',
                                            style: TextStyle(
                                              fontFamily: 'Tajwal',
                                            ),
                                          );
                                        },
                                      ),
                                  ],
                                ),
                              ),
                            ],
                          ),
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

class StudentRecordPage extends StatelessWidget {
  final String studentId;
  final String studentName;

  const StudentRecordPage({
    Key? key,
    required this.studentId,
    required this.studentName,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(
          title: Text(
            'سجل $studentName',
            style: TextStyle(fontFamily: 'Tajwal'),
          ),
          backgroundColor: AppColors.orange1,
        ),
        body: StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance
              .collection('wird')
              .where('studentId', isEqualTo: studentId)
              .where('grade', isNull: false)
              .orderBy('completionDate', descending: true)
              .snapshots(),
          builder: (context, snapshot) {
            if (snapshot.hasError) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.error_outline, size: 48, color: Colors.red),
                    SizedBox(height: 16),
                    Text(
                      'حدث خطأ في تحميل السجل',
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.red,
                        fontFamily: 'Tajwal',
                      ),
                    ),
                  ],
                ),
              );
            }

            if (snapshot.connectionState == ConnectionState.waiting) {
              return Center(
                child: CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(AppColors.orange1),
                ),
              );
            }

            final records = snapshot.data?.docs ?? [];

            if (records.isEmpty) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CircleAvatar(
                      radius: 30,
                      backgroundColor: Colors.grey[200],
                      child: Icon(
                        Icons.assignment,
                        size: 35,
                        color: Colors.grey,
                      ),
                    ),
                    SizedBox(height: 16),
                    Text(
                      'لا يوجد سجلات سابقة',
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.grey,
                        fontFamily: 'Tajwal',
                      ),
                    ),
                  ],
                ),
              );
            }

            return ListView.builder(
              padding: EdgeInsets.all(16),
              itemCount: records.length,
              itemBuilder: (context, index) {
                final record = records[index].data() as Map<String, dynamic>;
                final wirdType = record['wirdType'] as String? ?? 'ورد';
                
                IconData typeIcon;
                Color typeColor;
                switch (wirdType) {
                  case 'ورد الحفظ':
                    typeIcon = Icons.menu_book;
                    typeColor = AppColors.orange1;
                    break;
                  case 'ورد التلاوة':
                    typeIcon = Icons.record_voice_over;
                    typeColor = AppColors.blue1;
                    break;
                  case 'ورد المراجعة':
                    typeIcon = Icons.repeat;
                    typeColor = AppColors.green2;
                    break;
                  default:
                    typeIcon = Icons.assignment;
                    typeColor = AppColors.orange1;
                }

                return Card(
                  margin: EdgeInsets.only(bottom: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(15),
                  ),
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: typeColor.withOpacity(0.1),
                      child: Icon(
                        typeIcon,
                        color: typeColor,
                      ),
                    ),
                    title: Row(
                      children: [
                        Expanded(
                          child: Text(
                            record['surahName'] ?? '',
                            style: TextStyle(
                              fontFamily: 'Tajwal',
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        Text(
                          wirdType,
                          style: TextStyle(
                            color: typeColor,
                            fontWeight: FontWeight.bold,
                            fontFamily: 'Tajwal',
                          ),
                        ),
                      ],
                    ),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'من آية ${record['startAyah']} إلى آية ${record['endAyah']}',
                          style: TextStyle(fontFamily: 'Tajwal'),
                        ),
                        if (record['grade'] != null)
                          Text(
                            'التقدير: ${record['grade']}',
                            style: TextStyle(
                              color: typeColor,
                              fontWeight: FontWeight.bold,
                              fontFamily: 'Tajwal',
                            ),
                          ),
                        if (record['completionDate'] != null)
                          Text(
                            'تاريخ التقييم: ${_formatDate(record['completionDate'])}',
                            style: TextStyle(
                              color: Colors.grey,
                              fontSize: 12,
                              fontFamily: 'Tajwal',
                            ),
                          ),
                        if (record['assessmentNotes'] != null)
                          Text(
                            'ملاحظات: ${record['assessmentNotes']}',
                            style: TextStyle(
                              color: Colors.grey[600],
                              fontStyle: FontStyle.italic,
                              fontFamily: 'Tajwal',
                            ),
                          ),
                      ],
                    ),
                    isThreeLine: true,
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
    final date = timestamp.toDate();
    return intl.DateFormat('yyyy/MM/dd').format(date);
  }
} 