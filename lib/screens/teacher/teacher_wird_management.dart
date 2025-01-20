// teacher_wird_management.dart
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'add_wird_dialog.dart';

class TeacherWirdManagement extends StatelessWidget {
  final String studentId;
  final String studentName;

  const TeacherWirdManagement({
    Key? key, 
    required this.studentId, 
    required this.studentName,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: DefaultTabController(
        length: 2,
        child: Scaffold(
          appBar: AppBar(
            title: Text('إدارة الورد - $studentName'),
            bottom: TabBar(
              tabs: [
                Tab(text: 'الورد الحالي'),
                Tab(text: 'سجل الورد'),
              ],
            ),
          ),
          body: TabBarView(
            children: [
              _CurrentWirdTab(studentId: studentId),
              _WirdHistoryTab(studentId: studentId),
            ],
          ),
          floatingActionButton: FloatingActionButton(
            onPressed: () => _showAddWirdDialog(context),
            child: Icon(Icons.add),
          ),
        ),
      ),
    );
  }

  void _showAddWirdDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AddWirdDialog(studentId: studentId),
    );
  }
}

class _CurrentWirdTab extends StatelessWidget {
  final String studentId;

  const _CurrentWirdTab({Key? key, required this.studentId}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
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
                    ),
                    SizedBox(height: 8),
                    Text('من آية ${data['startAyah']} إلى آية ${data['endAyah']}'),
                    SizedBox(height: 16),
                    LinearProgressIndicator(
                      value: progress / 100,
                      backgroundColor: Colors.grey[200],
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.blue),
                    ),
                    SizedBox(height: 8),
                    Text('التقدم: $progress%'),
                    if (data['teacherNotes']?.isNotEmpty ?? false) ...[
                      SizedBox(height: 8),
                      Text('ملاحظات: ${data['teacherNotes']}'),
                    ],
                    SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        TextButton(
                          onPressed: () => _showUpdateProgressDialog(context, wird),
                          child: Text('تعديل التقدم'),
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
    );
  }

  void _showUpdateProgressDialog(BuildContext context, DocumentSnapshot wird) {
    final data = wird.data() as Map<String, dynamic>;
    final TextEditingController controller = TextEditingController(
      text: data['currentAyah'].toString()
    );

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('تحديث التقدم'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('السورة: ${data['surahName']}'),
            Text('من آية ${data['startAyah']} إلى آية ${data['endAyah']}'),
            SizedBox(height: 16),
            TextField(
              controller: controller,
              decoration: InputDecoration(labelText: 'الآية الحالية'),
              keyboardType: TextInputType.number,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('إلغاء'),
          ),
          ElevatedButton(
            onPressed: () async {
              final newAyah = int.tryParse(controller.text);
              if (newAyah == null) return;

              final status = newAyah >= data['endAyah'] ? 'completed' : 'in_progress';

              try {
                await wird.reference.update({
                  'currentAyah': newAyah,
                  'status': status,
                  if (status == 'completed') 'completionDate': DateTime.now(),
                });
                Navigator.pop(context);
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('حدث خطأ أثناء تحديث التقدم')),
                );
              }
            },
            child: Text('تحديث'),
          ),
        ],
      ),
    );
  }
}

class _WirdHistoryTab extends StatelessWidget {
  final String studentId;

  const _WirdHistoryTab({Key? key, required this.studentId}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('wird')
          .where('studentId', isEqualTo: studentId)
          .where('status', isEqualTo: 'completed')
          .orderBy('completionDate', descending: true)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError) return Center(child: Text('حدث خطأ'));
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(child: CircularProgressIndicator());
        }

        final completedWirds = snapshot.data?.docs ?? [];
        if (completedWirds.isEmpty) {
          return Center(child: Text('لا يوجد سجل ورد مكتمل'));
        }

        return ListView.builder(
          padding: EdgeInsets.all(16),
          itemCount: completedWirds.length,
          itemBuilder: (context, index) {
            final wird = completedWirds[index];
            final data = wird.data() as Map<String, dynamic>;
            
            return Card(
              margin: EdgeInsets.only(bottom: 8),
              child: ListTile(
                title: Text('${data['surahName']}'),
                subtitle: Text(
                  'من آية ${data['startAyah']} إلى آية ${data['endAyah']}\n'
                  'تاريخ الإكمال: ${DateFormat('yyyy-MM-dd').format(data['completionDate'].toDate())}'
                ),
                leading: Icon(Icons.check_circle, color: Colors.green),
              ),
            );
          },
        );
      },
    );
  }
}