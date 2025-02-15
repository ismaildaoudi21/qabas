// lib/screens/teacher/wird/wird_history_tab.dart

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:qabas/utils/app_colors.dart';
import 'package:intl/intl.dart' as intl;

class WirdHistoryTab extends StatefulWidget {
  final String studentId;
  final String? selectedType;

  const WirdHistoryTab({
    Key? key,
    required this.studentId,
    this.selectedType,
  }) : super(key: key);

  @override
  _WirdHistoryTabState createState() => _WirdHistoryTabState();
}

class _WirdHistoryTabState extends State<WirdHistoryTab> {
  static const int pageSize = 10;
  final ScrollController _scrollController = ScrollController();
  List<DocumentSnapshot> _wirds = [];
  bool _isLoading = false;
  bool _hasMore = true;
  DocumentSnapshot? _lastDocument;

  @override
  void initState() {
    super.initState();
    _loadMoreWirds();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels == _scrollController.position.maxScrollExtent) {
      _loadMoreWirds();
    }
  }

  Future<void> _loadMoreWirds() async {
    if (!_hasMore || _isLoading) return;

    setState(() {
      _isLoading = true;
    });

    try {
      Query query = FirebaseFirestore.instance
          .collection('wird')
          .where('studentId', isEqualTo: widget.studentId)
          .where('status', isEqualTo: 'completed')
          .orderBy('completionDate', descending: true)
          .limit(pageSize);

      if (widget.selectedType != null) {
        query = query.where('wirdType', isEqualTo: widget.selectedType);
      }

      if (_lastDocument != null) {
        query = query.startAfterDocument(_lastDocument!);
      }

      final QuerySnapshot snapshot = await query.get();
      final docs = snapshot.docs;

      setState(() {
        _wirds.addAll(docs);
        _isLoading = false;
        _hasMore = docs.length == pageSize;
        if (docs.isNotEmpty) {
          _lastDocument = docs.last;
        }
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('حدث خطأ في تحميل السجل')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_wirds.isEmpty && !_isLoading) {
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
      controller: _scrollController,
      padding: EdgeInsets.all(16),
      itemCount: _wirds.length + (_hasMore ? 1 : 0),
      itemBuilder: (context, index) {
        if (index == _wirds.length) {
          return Center(
            child: Padding(
              padding: EdgeInsets.all(8.0),
              child: CircularProgressIndicator(),
            ),
          );
        }

        final wird = _wirds[index];
        final data = wird.data() as Map<String, dynamic>;
        final wirdType = data['wirdType'] as String;

        return _buildHistoryCard(data, wirdType);
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