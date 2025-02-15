import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:qabas/utils/app_colors.dart';

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

  final List<String> grades = ['ممتاز', 'جيد جداً', 'جيد', 'يكرر'];

  @override
  void initState() {
    super.initState();
    final data = widget.wird.data() as Map<String, dynamic>;
    _notesController.text = data['teacherNotes'] ?? '';
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

  @override
  Widget build(BuildContext context) {
    final data = widget.wird.data() as Map<String, dynamic>;
    final color = _getTypeColor();

    return Directionality(
      textDirection: TextDirection.rtl,
      child: AlertDialog(
        title: Text('تقييم الورد'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                widget.studentName,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
              if (widget.wirdType == 'ورد المتن')
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
                      style: TextStyle(fontSize: 16),
                    ),
                  ],
                ),
              if (data['studentNotes']?.isNotEmpty ?? false) ...[
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
                      Text(data['studentNotes']),
                    ],
                  ),
                ),
              ],
              SizedBox(height: 16),
              Text(
                'التقدير:',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
              SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: grades.map((grade) {
                  return ChoiceChip(
                    label: Text(grade),
                    selected: selectedGrade == grade,
                    selectedColor: color.withOpacity(0.2),
                    onSelected: (selected) {
                      setState(() {
                        selectedGrade = selected ? grade : null;
                      });
                    },
                  );
                }).toList(),
              ),
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
              backgroundColor: color,
            ),
          ),
        ],
      ),
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

      if (context.mounted) {
        Navigator.pop(context, true); // Pass `true` to indicate success
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('تم حفظ التقييم بنجاح')),
        );

        // Call the callback to notify the parent widget
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