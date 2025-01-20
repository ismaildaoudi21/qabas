// add_wird_dialog.dart
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AddWirdDialog extends StatefulWidget {
  final String studentId;

  const AddWirdDialog({Key? key, required this.studentId}) : super(key: key);

  @override
  _AddWirdDialogState createState() => _AddWirdDialogState();
}

class _AddWirdDialogState extends State<AddWirdDialog> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _surahController;
  late TextEditingController _startAyahController;
  late TextEditingController _endAyahController;
  late TextEditingController _notesController;

  @override
  void initState() {
    super.initState();
    _surahController = TextEditingController();
    _startAyahController = TextEditingController();
    _endAyahController = TextEditingController();
    _notesController = TextEditingController();
  }

  @override
  void dispose() {
  _surahController.dispose();
  _startAyahController.dispose();
  _endAyahController.dispose();
  _notesController.dispose();
  super.dispose();
  }

  Future<void> _saveWird() async {
  if (_formKey.currentState!.validate()) {
    try {
      await FirebaseFirestore.instance.collection('wird').add({
        'studentId': widget.studentId,
        'surahName': _surahController.text,
        'startAyah': int.parse(_startAyahController.text),
        'endAyah': int.parse(_endAyahController.text),
        'assignedDate': DateTime.now(),
        'status': 'assigned',
        'currentAyah': int.parse(_startAyahController.text),
        'teacherNotes': _notesController.text,
      });
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('تم إضافة الورد بنجاح')),
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
      title: Text('إضافة ورد جديد'),
      content: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
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
                controller: _startAyahController,
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
                controller: _endAyahController,
                decoration: InputDecoration(
                  labelText: 'إلى آية',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value?.isEmpty ?? true) return 'الرجاء إدخال رقم الآية';
                  if (int.tryParse(value!) == null) return 'الرجاء إدخال رقم صحيح';
                  final start = int.tryParse(_startAyahController.text);
                  final end = int.tryParse(value);
                  if (start != null && end != null && end <= start) {
                    return 'يجب أن تكون الآية النهائية أكبر من البداية';
                  }
                  return null;
                },
              ),
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
          child: Text('حفظ'),
        ),
      ],
    ),
  );
  }
}