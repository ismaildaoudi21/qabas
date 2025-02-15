// lib/screens/teacher/wird/wird_history_tab.dart

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:qabas/utils/app_colors.dart';
import 'package:intl/intl.dart' as intl;

class WirdHistoryTab extends StatelessWidget {
  final String studentId;
  final String? selectedType;

  const WirdHistoryTab({
    Key? key,
    required this.studentId,
    this.selectedType,
  }) : super(key: key);

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
                Text(
                  'سورة ${data['surahName']}',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                Text('من آية ${data['startAyah']} إلى آية ${data['endAyah']}'),
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