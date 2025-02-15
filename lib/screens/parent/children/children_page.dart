import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:qabas/utils/app_colors.dart';
import 'package:qabas/screens/parent/children/child_details_page.dart';

class ChildrenPage extends StatelessWidget {
  final String parentId;

  const ChildrenPage({Key? key, required this.parentId}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    print('Building ChildrenPage with parentId: $parentId');
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(
          title: Text('أبنائي'),
          backgroundColor: AppColors.blue1,
        ),
        body: StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance
              .collection('users')
              .where('role', isEqualTo: 'student')
              .where('parentUsername', isEqualTo: parentId)
              .snapshots(),
          builder: (context, snapshot) {
            print('StreamBuilder state: ${snapshot.connectionState}');
            print('Parent ID being used: $parentId');
            if (snapshot.hasError) {
              print('Error in StreamBuilder: ${snapshot.error}');
              return Center(child: Text('حدث خطأ في تحميل البيانات'));
            }

            if (snapshot.connectionState == ConnectionState.waiting) {
              return Center(child: CircularProgressIndicator());
            }

            print('Number of documents: ${snapshot.data?.docs.length ?? 0}');
            if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
              return Center(child: Text('لا يوجد أبناء مسجلين'));
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
                  child: InkWell(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => ChildDetailsPage(
                            studentId: doc.id,
                            studentData: data,
                          ),
                        ),
                      );
                    },
                    child: Padding(
                      padding: EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              CircleAvatar(
                                backgroundColor: AppColors.blue1.withOpacity(0.2),
                                child: Icon(Icons.person, color: AppColors.blue1),
                              ),
                              SizedBox(width: 16),
                              Expanded(
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
                                              style: TextStyle(
                                                color: Colors.grey[600],
                                              ),
                                            );
                                          }
                                          return Text(
                                            'الحلقة: غير محدد',
                                            style: TextStyle(
                                              color: Colors.grey[600],
                                            ),
                                          );
                                        },
                                      ),
                                  ],
                                ),
                              ),
                              Icon(Icons.arrow_forward_ios, size: 16),
                            ],
                          ),
                          SizedBox(height: 16),
                          _buildProgressSection(doc.id),
                        ],
                      ),
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
          .limit(1)
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return Text(
            'لم يتم إكمال أي ورد بعد',
            style: TextStyle(color: Colors.grey[600]),
          );
        }

        final lastWird = snapshot.data!.docs.first.data() as Map<String, dynamic>;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'آخر ورد مكتمل:',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.grey[700],
              ),
            ),
            SizedBox(height: 8),
            Row(
              children: [
                Icon(Icons.check_circle, color: AppColors.green2, size: 16),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    '${lastWird['wirdType']} - ${lastWird['surahName']}',
                    style: TextStyle(color: Colors.grey[600]),
                  ),
                ),
              ],
            ),
          ],
        );
      },
    );
  }
} 