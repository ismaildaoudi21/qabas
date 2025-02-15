//lib/screens/teacher/wird/add_wird_dialog.dart

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:qabas/utils/app_colors.dart';
import 'package:qabas/utils/notification_helper.dart';

class AddWirdDialog extends StatefulWidget {
  final String studentId;
  final bool editMode;
  final Map<String, dynamic>? wirdData;
  final String? wirdId;

  const AddWirdDialog({
    Key? key,
    required this.studentId,
    this.editMode = false,
    this.wirdData,
    this.wirdId,
  }) : super(key: key);

  @override
  _AddWirdDialogState createState() => _AddWirdDialogState();
}

class _AddWirdDialogState extends State<AddWirdDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _surahController;
  late final TextEditingController _startController;
  late final TextEditingController _endController;
  late final TextEditingController _notesController;
  late String _selectedType;

  final List<String> wirdTypes = [
    'ورد الحفظ',
    'ورد التلاوة',
    'ورد المراجعة',
    'ورد المتن',
  ];

  @override
  void initState() {
    super.initState();
    _selectedType = widget.wirdData?['wirdType'] ?? 'ورد الحفظ';
    _surahController = TextEditingController(text: widget.wirdData?['surahName'] ?? '');
    _startController = TextEditingController(
      text: _getStartValue(widget.wirdData),
    );
    _endController = TextEditingController(
      text: _getEndValue(widget.wirdData),
    );
    _notesController = TextEditingController(text: widget.wirdData?['teacherNotes'] ?? '');
  }

  String _getStartValue(Map<String, dynamic>? data) {
    if (data == null) return '';
    if (data['wirdType'] == 'ورد المتن') {
      return data['startPoint']?.toString() ?? '';
    }
    return data['startAyah']?.toString() ?? '';
  }

  String _getEndValue(Map<String, dynamic>? data) {
    if (data == null) return '';
    if (data['wirdType'] == 'ورد المتن') {
      return data['endPoint']?.toString() ?? '';
    }
    return data['endAyah']?.toString() ?? '';
  }

  @override
  void dispose() {
    _surahController.dispose();
    _startController.dispose();
    _endController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Color _getTypeColor(String type) {
    switch (type) {
      case 'ورد الحفظ':
        return AppColors.orange1;
      case 'ورد التلاوة':
        return AppColors.blue1;
      case 'ورد المراجعة':
        return AppColors.blue3;
      case 'ورد المتن':
        return AppColors.green2;
      default:
        return Colors.grey;
    }
  }

  Widget _buildInputFields() {
    if (_selectedType == 'ورد المتن') {
      return Column(
        children: [
          TextFormField(
            controller: _surahController,
            decoration: InputDecoration(
              labelText: 'اسم المتن',
              hintText: 'أدخل اسم المتن',
              border: OutlineInputBorder(),
            ),
            validator: (value) => value?.isEmpty ?? true ? 'الرجاء إدخال اسم المتن' : null,
          ),
          SizedBox(height: 16),
          TextFormField(
            controller: _startController,
            decoration: InputDecoration(
              labelText: 'من',
              hintText: 'من أين تبدأ',
              border: OutlineInputBorder(),
            ),
            validator: (value) => value?.isEmpty ?? true ? 'الرجاء تحديد البداية' : null,
          ),
          SizedBox(height: 16),
          TextFormField(
            controller: _endController,
            decoration: InputDecoration(
              labelText: 'إلى',
              hintText: 'إلى أين تنتهي',
              border: OutlineInputBorder(),
            ),
            validator: (value) => value?.isEmpty ?? true ? 'الرجاء تحديد النهاية' : null,
          ),
        ],
      );
    }

    return Column(
      children: [
        TextFormField(
          controller: _surahController,
          decoration: InputDecoration(
            labelText: 'اسم السورة',
            border: OutlineInputBorder(),
          ),
          validator: (value) => value?.isEmpty ?? true ? 'الرجاء إدخال اسم السورة' : null,
        ),
        SizedBox(height: 16),
        TextFormField(
          controller: _startController,
          decoration: InputDecoration(
            labelText: 'من آية',
            border: OutlineInputBorder(),
          ),
          keyboardType: TextInputType.number,
          validator: (value) {
            if (value?.isEmpty ?? true) return 'الرجاء إدخال رقم الآية';
            if (int.tryParse(value!) == null) return 'الرجاء إدخال رقم صحيح';
            return null;
          },
        ),
        SizedBox(height: 16),
        TextFormField(
          controller: _endController,
          decoration: InputDecoration(
            labelText: 'إلى آية',
            border: OutlineInputBorder(),
          ),
          keyboardType: TextInputType.number,
          validator: (value) {
            if (value?.isEmpty ?? true) return 'الرجاء إدخال رقم الآية';
            if (int.tryParse(value!) == null) return 'الرجاء إدخال رقم صحيح';
            final start = int.tryParse(_startController.text);
            final end = int.tryParse(value);
            if (start != null && end != null && end <= start) {
              return 'يجب أن تكون الآية النهائية أكبر من البداية';
            }
            return null;
          },
        ),
      ],
    );
  }

  Future<void> _saveWird() async {
    if (_formKey.currentState!.validate()) {
      try {
        final data = {
          'studentId': widget.studentId,
          'wirdType': _selectedType,
          'teacherNotes': _notesController.text,
        };

        if (_selectedType == 'ورد المتن') {
          data.addAll({
            'surahName': _surahController.text,
            'startPoint': _startController.text,
            'endPoint': _endController.text,
          });
        } else {
          data.addAll({
            'surahName': _surahController.text,
            'startAyah': int.parse(_startController.text).toString(),
            'endAyah': int.parse(_endController.text).toString(),
          });

          if (!widget.editMode) {
            data.addAll({
              'currentAyah': int.parse(_startController.text).toString(),
              'assignedDate': DateTime.now().toString(),
              'status': 'assigned',
            });
          }
        }

        if (widget.editMode && widget.wirdId != null) {
          await FirebaseFirestore.instance
              .collection('wird')
              .doc(widget.wirdId)
              .update(data);
        } else {
          data['assignedDate'] = DateTime.now().toString();
          data['status'] = 'assigned';
          await FirebaseFirestore.instance.collection('wird').add(data);

          // Create notification for new wird assignment
          await NotificationHelper.createWirdAssignedNotification(
            studentId: widget.studentId,
            studentName: '', // This will be shown to the student, so we don't need it
            wirdType: _selectedType,
            surahName: _surahController.text,
          );
        }

        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(widget.editMode ? 'تم تحديث الورد بنجاح' : 'تم إضافة الورد بنجاح')),
        );
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('حدث خطأ أثناء حفظ الورد')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: AlertDialog(
        title: Text(widget.editMode ? 'تعديل الورد' : 'إضافة ورد جديد'),
        content: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: EdgeInsets.symmetric(vertical: 8),
                  width: double.infinity,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'نوع الورد',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.grey[700],
                        ),
                      ),
                      SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        children: wirdTypes.map((type) {
                          Color color = _getTypeColor(type);
                          return ChoiceChip(
                            label: Text(type),
                            selected: _selectedType == type,
                            selectedColor: color.withOpacity(0.2),
                            onSelected: (selected) {
                              if (selected) {
                                setState(() {
                                  _selectedType = type;
                                  if (!widget.editMode) {
                                    _surahController.clear();
                                    _startController.clear();
                                    _endController.clear();
                                  }
                                });
                              }
                            },
                          );
                        }).toList(),
                      ),
                    ],
                  ),
                ),
                SizedBox(height: 16),
                _buildInputFields(),
                SizedBox(height: 16),
                TextFormField(
                  controller: _notesController,
                  decoration: InputDecoration(
                    labelText: 'ملاحظات',
                    border: OutlineInputBorder(),
                  ),
                  maxLines: 3,
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('إلغاء'),
          ),
          ElevatedButton(
            onPressed: _saveWird,
            child: Text(widget.editMode ? 'تحديث' : 'حفظ'),
            style: ElevatedButton.styleFrom(
              backgroundColor: _getTypeColor(_selectedType),
            ),
          ),
        ],
      ),
    );
  }
}