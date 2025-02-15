import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:qabas/utils/app_colors.dart';
import 'package:qabas/utils/notification_helper.dart';

class AssessmentDialog extends StatefulWidget {
  final DocumentSnapshot wird;
  final String wirdType;
  final String studentName;
  final VoidCallback? onAssessmentSaved; // Callback to notify parent

  const AssessmentDialog({
    Key? key,
    required this.wird,
    required this.wirdType,
    required this.studentName,
    this.onAssessmentSaved, // Add this parameter
  }) : super(key: key);

  @override
  _AssessmentDialogState createState() => _AssessmentDialogState();
}

class _AssessmentDialogState extends State<AssessmentDialog> {
  String? selectedGrade;
  final TextEditingController _notesController = TextEditingController();
  bool _isLoading = false;
  late final Color _typeColor;
  late final Map<String, dynamic> _wirdData;

  final List<String> grades = ['ممتاز', 'جيد جداً', 'جيد', 'يكرر'];

  @override
  void initState() {
    super.initState();
    _wirdData = widget.wird.data() as Map<String, dynamic>;
    _notesController.text = _wirdData['teacherNotes'] ?? '';
    _typeColor = _getTypeColor();
  }

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  Color _getTypeColor() {
    switch (widget.wirdType) {
      case 'ورد الحفظ':
        return AppColors.orange1;
      case 'ورد التلاوة':
        return AppColors.blue1;
      case 'ورد المتن':
        return AppColors.green2;
      default:
        return AppColors.orange1;
    }
  }

  Widget _buildGradeChips() {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: grades.map((grade) {
        return ChoiceChip(
          label: Text(grade),
          selected: selectedGrade == grade,
          selectedColor: _typeColor.withOpacity(0.2),
          onSelected: (selected) {
            setState(() {
              selectedGrade = selected ? grade : null;
            });
          },
        );
      }).toList(),
    );
  }

  Widget _buildStudentNotes() {
    if (_wirdData['studentNotes']?.isEmpty ?? true) return SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(height: 16),
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
              Text(_wirdData['studentNotes']),
            ],
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('تقييم الورد - ${widget.studentName}'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'نوع الورد: ${widget.wirdType}',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: _typeColor,
              ),
            ),
            SizedBox(height: 8),
            Text(
              'سورة ${_wirdData['surahName']}',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            Text(
              widget.wirdType == 'ورد المتن'
                  ? 'من ${_wirdData['startPoint']} إلى ${_wirdData['endPoint']}'
                  : 'من آية ${_wirdData['startAyah']} إلى آية ${_wirdData['endAyah']}',
            ),
            _buildStudentNotes(),
            SizedBox(height: 16),
            Text(
              'التقدير:',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: _typeColor,
              ),
            ),
            SizedBox(height: 8),
            _buildGradeChips(),
            SizedBox(height: 16),
            TextField(
              controller: _notesController,
              decoration: InputDecoration(
                labelText: 'ملاحظات المعلم',
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isLoading ? null : () => Navigator.pop(context),
          child: Text('إلغاء'),
        ),
        ElevatedButton(
          onPressed: _isLoading ? null : _saveAssessment,
          child: _isLoading
              ? SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    strokeWidth: 2,
                  ),
                )
              : Text('حفظ التقييم'),
          style: ElevatedButton.styleFrom(
            backgroundColor: _typeColor,
          ),
        ),
      ],
    );
  }

  Future<void> _saveAssessment() async {
    if (selectedGrade == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('الرجاء اختيار التقدير')),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      await widget.wird.reference.update({
        'grade': selectedGrade,
        'teacherNotes': _notesController.text,
        'assessmentDate': FieldValue.serverTimestamp(),
        'status': selectedGrade == 'يكرر' ? 'in_progress' : 'completed',
        if (selectedGrade != 'يكرر') 'completionDate': FieldValue.serverTimestamp(),
      });

      // Create notification for wird assessment
      await NotificationHelper.createWirdAssessmentNotification(
        studentId: _wirdData['studentId'],
        studentName: widget.studentName,
        wirdType: widget.wirdType,
        surahName: _wirdData['surahName'],
        grade: selectedGrade!,
      );

      if (context.mounted) {
        Navigator.pop(context, true);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('تم حفظ التقييم بنجاح')),
        );

        if (widget.onAssessmentSaved != null) {
          widget.onAssessmentSaved!();
        }
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('حدث خطأ أثناء حفظ التقييم')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }
}