import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class StudentWirdPage extends StatelessWidget {
  final String studentId;

  const StudentWirdPage({Key? key, required this.studentId}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(
          title: Text('الورد اليومي'),
          centerTitle: true,
        ),
        body: StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance
              .collection('wird')
              .where('studentId', isEqualTo: studentId)
              .where('status', whereIn: ['assigned', 'in_progress'])
              .snapshots(),
          builder: (context, snapshot) {
            if (snapshot.hasError) return Center(child: Text('حدث خطأ'));
            if (snapshot.connectionState == ConnectionState.waiting) {
              return Center(child: CircularProgressIndicator());
            }
            
            final wirds = snapshot.data?.docs ?? [];
            if (wirds.isEmpty) return Center(child: Text('لا يوجد ورد حالي'));

            return ListView.builder(
              padding: EdgeInsets.all(16),
              itemCount: wirds.length,
              itemBuilder: (context, index) {
                final wird = wirds[index];
                final data = wird.data() as Map<String, dynamic>;
                final progress = ((data['currentAyah'] - data['startAyah']) / 
                               (data['endAyah'] - data['startAyah']) * 100).round();

                return Card(
                  margin: EdgeInsets.only(bottom: 16),
                  child: Padding(
                    padding: EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'السورة: ${data['surahName']}',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold
                          ),
                          textDirection: TextDirection.rtl,
                        ),
                        SizedBox(height: 8),
                        Text(
                          'من آية ${data['startAyah']} إلى آية ${data['endAyah']}',
                          textDirection: TextDirection.rtl,
                        ),
                        SizedBox(height: 16),
                        LinearProgressIndicator(
                          value: progress / 100,
                          backgroundColor: Colors.grey[200],
                          valueColor: AlwaysStoppedAnimation<Color>(Colors.green),
                        ),
                        SizedBox(height: 8),
                        Text(
                          'التقدم: $progress%',
                          textDirection: TextDirection.rtl,
                        ),
                        if (data['teacherNotes']?.isNotEmpty ?? false) ...[
                          SizedBox(height: 8),
                          Text(
                            'ملاحظات المعلم: ${data['teacherNotes']}',
                            style: TextStyle(color: Colors.grey[700]),
                            textDirection: TextDirection.rtl,
                          ),
                        ],
                        
                        SizedBox(height: 16),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            ElevatedButton(
                              onPressed: () => _markAyahComplete(context, wird),
                              child: Text('تم الحفظ'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.green,
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
          },
        ),
      ),
    );
  }

  void _markAyahComplete(BuildContext context, DocumentSnapshot wird) async {
    final data = wird.data() as Map<String, dynamic>;
    final currentAyah = data['currentAyah'] as int;
    final endAyah = data['endAyah'] as int;
    
    if (currentAyah >= endAyah) return;

    try {
      final newAyah = currentAyah + 1;
      final status = newAyah >= endAyah ? 'completed' : 'in_progress';
      
      await wird.reference.update({
        'currentAyah': newAyah,
        'status': status,
        if (status == 'completed') 'completionDate': DateTime.now(),
      });

      if (status == 'completed') {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('تم إكمال الورد بنجاح')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('حدث خطأ أثناء تحديث التقدم')),
      );
    }
  }
}