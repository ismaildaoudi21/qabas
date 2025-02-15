import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:qabas/utils/app_colors.dart';
import 'add_wird_dialog.dart';
import 'assessment_dialog.dart';
import 'package:async/async.dart' show StreamZip;

class TeacherWirdManagement extends StatefulWidget {
  final String studentId;
  final String studentName;

  const TeacherWirdManagement({
    Key? key,
    required this.studentId,
    required this.studentName,
  }) : super(key: key);

  @override
  _TeacherWirdManagementState createState() => _TeacherWirdManagementState();
}

class _TeacherWirdManagementState extends State<TeacherWirdManagement> {
  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Directionality(
        textDirection: TextDirection.rtl,
        child: Scaffold(
          appBar: AppBar(
            title: Text('الورد - ${widget.studentName}'),
            centerTitle: true,
            backgroundColor: AppColors.orange1,
            bottom: TabBar(
              tabs: [
                Tab(text: 'الورد الحالي'),
                Tab(text: 'السجل'),
              ],
            ),
          ),
          body: TabBarView(
            children: [
              _CurrentWirdTab(studentId: widget.studentId, studentName: widget.studentName),
              _WirdHistoryTab(studentId: widget.studentId),
            ],
          ),
          floatingActionButton: FloatingActionButton(
            onPressed: () => _showAddWirdDialog(context),
            child: Icon(Icons.add),
            backgroundColor: AppColors.orange1,
          ),
        ),
      ),
    );
  }

  void _showAddWirdDialog(BuildContext context) async {
    await showDialog(
      context: context,
      builder: (context) => AddWirdDialog(studentId: widget.studentId),
    );
    // Refresh the current wird tab after adding a new wird
    setState(() {});
  }

  Future<void> _assignWird(Map<String, dynamic> wirdData) async {
    try {
      await FirebaseFirestore.instance.collection('wird').add(wirdData);
    } catch (e) {
      print('Error assigning wird: $e');
    }
  }
}

class _CurrentWirdTab extends StatefulWidget {
  final String studentId;
  final String studentName;

  const _CurrentWirdTab({required this.studentId, required this.studentName});

  @override
  __CurrentWirdTabState createState() => __CurrentWirdTabState();
}

class __CurrentWirdTabState extends State<_CurrentWirdTab> {
  @override
  Widget build(BuildContext context) {
    // Combine all wird types into a single stream
    final Stream<QuerySnapshot> combinedStream = FirebaseFirestore.instance
        .collection('wird')
        .where('studentId', isEqualTo: widget.studentId)
        .where('status', whereIn: ['assigned', 'in_progress'])
        .orderBy('assignedDate', descending: true)
        .snapshots();

    return StreamBuilder<QuerySnapshot>(
      stream: combinedStream,
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
                Icon(Icons.menu_book_outlined, size: 64, color: Colors.grey),
                SizedBox(height: 16),
                Text(
                  'لا يوجد ورد حالي',
                  style: TextStyle(fontSize: 18, color: Colors.grey[600]),
                ),
              ],
            ),
          );
        }

        // Group wirds by type for better organization
        final Map<String, List<DocumentSnapshot>> wirdsByType = {};
        for (var wird in wirds) {
          final data = wird.data() as Map<String, dynamic>;
          final type = data['wirdType'] as String;
          if (!wirdsByType.containsKey(type)) {
            wirdsByType[type] = [];
          }
          wirdsByType[type]!.add(wird);
        }

        return ListView.builder(
          padding: EdgeInsets.all(16),
          itemCount: wirds.length,
          itemBuilder: (context, index) {
            final wird = wirds[index];
            final data = wird.data() as Map<String, dynamic>;
            final wirdType = data['wirdType']?.toString() ?? 'ورد الحفظ';

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
              case 'ورد المتن':
                typeColor = AppColors.green2;
                typeIcon = Icons.library_books;
                break;
              default:
                typeColor = AppColors.orange1;
                typeIcon = Icons.menu_book;
            }

            return Card(
              margin: EdgeInsets.only(bottom: 16),
              child: Column(
                children: [
                  Container(
                    padding: EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: typeColor.withOpacity(0.1),
                      borderRadius: BorderRadius.vertical(top: Radius.circular(4)),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Icon(typeIcon, color: typeColor),
                            SizedBox(width: 8),
                            Text(
                              wirdType,
                              style: TextStyle(
                                color: typeColor,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        PopupMenuButton<String>(
                          icon: Icon(Icons.more_vert, color: typeColor),
                          onSelected: (value) {
                            if (value == 'edit') {
                              _showEditDialog(context, wird);
                            } else if (value == 'delete') {
                              _showDeleteConfirmation(context, wird);
                            }
                          },
                          itemBuilder: (context) => [
                            PopupMenuItem(
                              value: 'edit',
                              child: Row(
                                children: [
                                  Icon(Icons.edit, color: typeColor),
                                  SizedBox(width: 8),
                                  Text('تعديل'),
                                ],
                              ),
                            ),
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
                      ],
                    ),
                  ),
                  Padding(
                    padding: EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (wirdType == 'ورد المتن')
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                data['surahName'] ?? '',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Text(
                                'من ${data['startPoint'] ?? ''} إلى ${data['endPoint'] ?? ''}',
                                style: TextStyle(fontSize: 16),
                              ),
                            ],
                          )
                        else
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'سورة ${data['surahName']}',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Text(
                                'من آية ${data['startAyah']} إلى آية ${data['endAyah']}',
                              ),
                            ],
                          ),
                        if (data['teacherNotes']?.isNotEmpty ?? false) ...[
                          SizedBox(height: 16),
                          Container(
                            padding: EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: typeColor.withOpacity(0.05),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: typeColor.withOpacity(0.2)),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'ملاحظات المعلم:',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: typeColor,
                                  ),
                                ),
                                SizedBox(height: 4),
                                Text(data['teacherNotes']),
                              ],
                            ),
                          ),
                        ],
                        if (data['studentNotes']?.isNotEmpty ?? false) ...[
                          SizedBox(height: 8),
                          Container(
                            padding: EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: Colors.grey[50],
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: Colors.grey[300]!),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'ملاحظات الطالب:',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: Colors.grey[700],
                                  ),
                                ),
                                SizedBox(height: 4),
                                Text(data['studentNotes']),
                              ],
                            ),
                          ),
                        ],
                        SizedBox(height: 16),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            if (wirdType == 'ورد المراجعة')
                              ElevatedButton(
                                onPressed: () => _showCompletionDialog(context, wird),
                                child: Text('إكمال المراجعة'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: typeColor,
                                ),
                              )
                            else
                              ElevatedButton(
                                onPressed: () => _showAssessmentDialog(context, wird, wirdType),
                                child: Text('تقييم'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: typeColor,
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

  void _showAssessmentDialog(BuildContext context, DocumentSnapshot wird, String wirdType) async {
    final result = await showDialog(
      context: context,
      builder: (context) => AssessmentDialog(
        wird: wird,
        wirdType: wirdType,
        studentName: widget.studentName,
        onAssessmentSaved: () {
          // This callback will be called when the assessment is saved
          setState(() {}); // Refresh the UI
        },
      ),
    );

    if (result == true) {
      // If the assessment was saved, refresh the UI
      setState(() {});
    }
  }

  void _showEditDialog(BuildContext context, DocumentSnapshot wird) async {
    await showDialog(
      context: context,
      builder: (context) => AddWirdDialog(
        studentId: widget.studentId,
        editMode: true,
        wirdData: wird.data() as Map<String, dynamic>,
        wirdId: wird.id,
      ),
    );
    // Refresh the current wird tab after editing
    setState(() {});
  }

  void _showDeleteConfirmation(BuildContext context, DocumentSnapshot wird) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('تأكيد الحذف'),
        content: Text('هل أنت متأكد من حذف هذا الورد؟'),
        actions: [
          TextButton(
            child: Text('إلغاء'),
            onPressed: () => Navigator.pop(context),
          ),
          ElevatedButton(
            child: Text('حذف'),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () async {
              try {
                await wird.reference.delete();
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('تم حذف الورد بنجاح')),
                );
                // Refresh the current wird tab after deletion
                setState(() {});
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('حدث خطأ أثناء حذف الورد')),
                );
              }
            },
          ),
        ],
      ),
    );
  }

  void _showCompletionDialog(BuildContext context, DocumentSnapshot wird) async {
    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('تأكيد إكمال المراجعة'),
        content: Text('هل تم إكمال المراجعة؟'),
        actions: [
          TextButton(
            child: Text('إلغاء'),
            onPressed: () => Navigator.pop(context),
          ),
          ElevatedButton(
            child: Text('تأكيد'),
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.blue3),
            onPressed: () async {
              try {
                await wird.reference.update({
                  'status': 'completed',
                  'completionDate': DateTime.now(),
                });
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('تم إكمال المراجعة')),
                );
                // Refresh the current wird tab after completion
                setState(() {});
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('حدث خطأ أثناء تحديث المراجعة')),
                );
              }
            },
          ),
        ],
      ),
    );
  }
}

class _WirdHistoryTab extends StatelessWidget {
  final String studentId;

  const _WirdHistoryTab({required this.studentId});

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
                  style: TextStyle(fontSize: 18, color: Colors.grey[600]),
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
            final wirdType = data['wirdType']?.toString() ?? 'ورد الحفظ';

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
              case 'ورد المتن':
                typeColor = AppColors.green2;
                typeIcon = Icons.library_books;
                break;
              default:
                typeColor = AppColors.orange1;
                typeIcon = Icons.menu_book;
            }

            return Card(
              margin: EdgeInsets.only(bottom: 8),
              child: ListTile(
                leading: CircleAvatar(
                  backgroundColor: typeColor.withOpacity(0.2),
                  child: Icon(typeIcon, color: typeColor),
                ),
                title: Text(
                  wirdType == 'ورد المتن'
                      ? data['surahName'] ?? ''
                      : 'سورة ${data['surahName']}',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      wirdType,
                      style: TextStyle(color: typeColor),
                    ),
                    Text(
                      wirdType == 'ورد المتن'
                          ? 'من ${data['startPoint']} إلى ${data['endPoint']}'
                          : 'من آية ${data['startAyah']} إلى آية ${data['endAyah']}',
                    ),
                    if (data['grade'] != null)
                      Text(
                        'التقدير: ${data['grade']}',
                        style: TextStyle(
                          color: data['grade'] == 'يكرر' ? Colors.red : Colors.green,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    Text(
                      'تاريخ الإكمال: ${_formatDate(data['completionDate'])}',
                      style: TextStyle(color: Colors.grey[600]),
                    ),
                  ],
                ),
                isThreeLine: true,
              ),
            );
          },
        );
      },
    );
  }

  String _formatDate(Timestamp? timestamp) {
    if (timestamp == null) return '';
    DateTime date = timestamp.toDate();
    return '${date.year}-${date.month}-${date.day}';
  }
}