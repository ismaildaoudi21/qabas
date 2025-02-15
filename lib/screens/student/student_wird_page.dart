// lib/screens/student/student_wird_page.dart

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:qabas/utils/app_colors.dart';
import 'package:async/async.dart' show StreamZip;
import 'package:intl/intl.dart' as intl;

class StudentWirdPage extends StatelessWidget {
  final String studentId;

  const StudentWirdPage({Key? key, required this.studentId}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3,
      child: Directionality(
        textDirection: TextDirection.rtl,
        child: Scaffold(
          appBar: AppBar(
            title: Text('الورد اليومي'),
            centerTitle: true,
            backgroundColor: AppColors.orange1,
            bottom: TabBar(
              tabs: [
                Tab(text: 'ورد الحفظ والتلاوة'),
                Tab(text: 'ورد المراجعة'),
                Tab(text: 'السجل'),
              ],
            ),
          ),
          body: TabBarView(
            children: [
              _RegularWirdTab(studentId: studentId),
              _ReviewWirdTab(studentId: studentId),
              _WirdHistoryTab(studentId: studentId),
            ],
          ),
        ),
      ),
    );
  }
}

class _RegularWirdTab extends StatelessWidget {
  final String studentId;

  const _RegularWirdTab({required this.studentId});

  @override
  Widget build(BuildContext context) {
    Stream<QuerySnapshot> hifdStream = FirebaseFirestore.instance
        .collection('wird')
        .where('studentId', isEqualTo: studentId)
        .where('status', whereIn: ['assigned', 'in_progress'])
        .where('wirdType', isEqualTo: 'ورد الحفظ')
        .snapshots();

    Stream<QuerySnapshot> tilawahStream = FirebaseFirestore.instance
        .collection('wird')
        .where('studentId', isEqualTo: studentId)
        .where('status', whereIn: ['assigned', 'in_progress'])
        .where('wirdType', isEqualTo: 'ورد التلاوة')
        .snapshots();

    return StreamBuilder<List<QuerySnapshot>>(
      stream: StreamZip([hifdStream, tilawahStream]),
      builder: (context, snapshot) {
        if (snapshot.hasError) return Center(child: Text('حدث خطأ'));
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(child: CircularProgressIndicator());
        }
        
        final List<DocumentSnapshot> wirds = [];
        if (snapshot.data != null) {
          for (var querySnapshot in snapshot.data!) {
            wirds.addAll(querySnapshot.docs);
          }
        }
        
        if (wirds.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.menu_book_outlined, size: 64, color: Colors.grey),
                SizedBox(height: 16),
                Text('لا يوجد ورد حالي',
                  style: TextStyle(fontSize: 18, color: Colors.grey[600])),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: EdgeInsets.all(16),
          itemCount: wirds.length,
          itemBuilder: (context, index) {
            final wird = wirds[index];
            final data = wird.data() as Map<String, dynamic>;
            final wirdType = data['wirdType']?.toString() ?? 'ورد الحفظ';
            final color = wirdType == 'ورد الحفظ' ? AppColors.orange1 : AppColors.blue1;
            final icon = wirdType == 'ورد الحفظ' ? Icons.menu_book : Icons.record_voice_over;

            return Card(
              margin: EdgeInsets.only(bottom: 16),
              child: Column(
                children: [
                  Container(
                    padding: EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: color.withOpacity(0.1),
                      borderRadius: BorderRadius.vertical(top: Radius.circular(4)),
                    ),
                    child: Row(
                      children: [
                        Icon(icon, color: color),
                        SizedBox(width: 8),
                        Text(
                          wirdType,
                          style: TextStyle(
                            color: color,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Padding(
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
                        Text(
                          'من آية ${data['startAyah']} إلى آية ${data['endAyah']}',
                        ),
                        SizedBox(height: 16),
                        if (data['teacherNotes']?.isNotEmpty ?? false) ...[
                          SizedBox(height: 8),
                          Text(
                            'ملاحظات المعلم: ${data['teacherNotes']}',
                            style: TextStyle(color: Colors.grey[700]),
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}

class _ReviewWirdTab extends StatelessWidget {
  final String studentId;

  const _ReviewWirdTab({required this.studentId});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('wird')
          .where('studentId', isEqualTo: studentId)
          .where('status', whereIn: ['assigned', 'in_progress'])
          .where('wirdType', isEqualTo: 'ورد المراجعة')
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError) return Center(child: Text('حدث خطأ'));
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(child: CircularProgressIndicator());
        }
        
        final wirds = snapshot.data?.docs ?? [];
        if (wirds.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.auto_stories_outlined, size: 64, color: Colors.grey),
                SizedBox(height: 16),
                Text('لا يوجد ورد مراجعة حالي',
                  style: TextStyle(fontSize: 18, color: Colors.grey[600])),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: EdgeInsets.all(16),
          itemCount: wirds.length,
          itemBuilder: (context, index) {
            final wird = wirds[index];
            final data = wird.data() as Map<String, dynamic>;

            return Card(
              margin: EdgeInsets.only(bottom: 16),
              child: Column(
                children: [
                  Container(
                    padding: EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.blue3.withOpacity(0.1),
                      borderRadius: BorderRadius.vertical(top: Radius.circular(4)),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.auto_stories, color: AppColors.blue3),
                        SizedBox(width: 8),
                        Text(
                          'ورد المراجعة',
                          style: TextStyle(
                            color: AppColors.blue3,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Padding(
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
                        Text(
                          'من آية ${data['startAyah']} إلى آية ${data['endAyah']}',
                        ),
                        if (data['teacherNotes']?.isNotEmpty ?? false) ...[
                          SizedBox(height: 8),
                          Text(
                            'ملاحظات المعلم: ${data['teacherNotes']}',
                            style: TextStyle(color: Colors.grey[700]),
                          ),
                        ],
                        SizedBox(height: 16),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            ElevatedButton(
                              onPressed: () => _markReviewComplete(context, wird),
                              child: Text('تم المراجعة'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.blue3,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Future<void> _markReviewComplete(BuildContext context, DocumentSnapshot wird) async {
    bool shouldComplete = false;
    await showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return Directionality(
          textDirection: TextDirection.rtl,
          child: AlertDialog(
            title: Text('تأكيد إكمال المراجعة'),
            content: Text('هل تم الانتهاء من المراجعة؟'),
            actions: [
              TextButton(
                child: Text('إلغاء'),
                onPressed: () {
                  shouldComplete = false;
                  Navigator.of(dialogContext).pop();
                },
              ),
              ElevatedButton(
                child: Text('تأكيد'),
                onPressed: () {
                  shouldComplete = true;
                  Navigator.of(dialogContext).pop();
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.blue3,
                ),
              ),
            ],
          ),
        );
      },
    );

    if (!shouldComplete) return;

    try {
      await wird.reference.update({
        'status': 'completed',
        'completionDate': DateTime.now(),
      });

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('تم إكمال المراجعة بنجاح'),
            backgroundColor: AppColors.blue3,
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('حدث خطأ أثناء تحديث المراجعة'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}

class _WirdHistoryTab extends StatelessWidget {
  final String studentId;
  final String? selectedType;

  const _WirdHistoryTab({
    required this.studentId,
    this.selectedType,
  });

  @override
  Widget build(BuildContext context) {
    Query query = FirebaseFirestore.instance
        .collection('wird')
        .where('studentId', isEqualTo: studentId)
        .where('status', isEqualTo: 'completed')
        .orderBy('completionDate', descending: true);

    if (selectedType != null) {
      query = query.where('wirdType', isEqualTo: selectedType);
    }

    return StreamBuilder<QuerySnapshot>(
      stream: query.snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError) return Center(child: Text('حدث خطأ'));
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(child: CircularProgressIndicator());
        }

        final wirds = snapshot.data?.docs ?? [];
        if (wirds.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.history, size: 64, color: Colors.grey),
                SizedBox(height: 16),
                Text(
                  'لا يوجد سجل للأوراد المكتملة',
                  style: TextStyle(
                    fontSize: 18,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: EdgeInsets.all(16),
          itemCount: wirds.length,
          itemBuilder: (context, index) {
            final wird = wirds[index];
            final data = wird.data() as Map<String, dynamic>;
            final wirdType = data['wirdType'] as String;

            return _buildHistoryCard(data, wirdType);
          },
        );
      },
    );
  }

  Widget _buildHistoryCard(Map<String, dynamic> data, String wirdType) {
    Color typeColor;
    IconData typeIcon;
    switch (wirdType) {
      case 'ورد الحفظ':
        typeColor = AppColors.orange1;
        typeIcon = Icons.menu_book;
        break;
      case 'ورد التلاوة':
        typeColor = AppColors.blue1;
        typeIcon = Icons.record_voice_over;
        break;
      case 'ورد المراجعة':
        typeColor = AppColors.blue3;
        typeIcon = Icons.auto_stories;
        break;
      default:
        typeColor = Colors.grey;
        typeIcon = Icons.help_outline;
    }

    return Card(
      margin: EdgeInsets.only(bottom: 8),
      child: Column(
        children: [
          Container(
            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: typeColor.withOpacity(0.1),
              borderRadius: BorderRadius.vertical(top: Radius.circular(4)),
            ),
            child: Row(
              children: [
                Icon(typeIcon, color: typeColor, size: 20),
                SizedBox(width: 8),
                Text(
                  wirdType,
                  style: TextStyle(
                    color: typeColor,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Spacer(),
                Text(
                  _formatDate(data['completionDate']),
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (wirdType == 'ورد المتن') ...[
                  Text(
                    'المتن: ${data['surahName'] ?? ''}',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  Text('من ${data['startPoint'] ?? ''} إلى ${data['endPoint'] ?? ''}'),
                ] else ...[
                  Text(
                    'سورة ${data['surahName']}',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  Text('من آية ${data['startAyah']} إلى آية ${data['endAyah']}'),
                ],
                if (wirdType != 'ورد المراجعة' && data['grade'] != null) ...[
                  SizedBox(height: 8),
                  Text(
                    'التقدير: ${data['grade']}',
                    style: TextStyle(
                      color: typeColor,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
                if (data['assessmentNotes']?.isNotEmpty ?? false) ...[
                  SizedBox(height: 8),
                  Text(
                    'ملاحظات: ${data['assessmentNotes']}',
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(Timestamp timestamp) {
    return intl.DateFormat('yyyy-MM-dd').format(timestamp.toDate());
  }
}