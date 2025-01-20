import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AddHalaqahPage extends StatefulWidget {
  final String? halaqahId;
  final Map<String, dynamic>? halaqahData;

  AddHalaqahPage({this.halaqahId, this.halaqahData});

  @override
  _AddHalaqahPageState createState() => _AddHalaqahPageState();
}

class _AddHalaqahPageState extends State<AddHalaqahPage> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _locationController = TextEditingController();
  final TextEditingController _scheduleController = TextEditingController();
  String? _selectedTeacherId;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    if (widget.halaqahData != null) {
      _nameController.text = widget.halaqahData!['name'] ?? '';
      _locationController.text = widget.halaqahData!['location'] ?? '';
      _scheduleController.text = widget.halaqahData!['schedule'] ?? '';
      _selectedTeacherId = widget.halaqahData!['teacherId'];
    }
  }

  Widget _buildTeacherDropdown() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('users')
          .where('role', isEqualTo: 'teacher')
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Text('حدث خطأ: ${snapshot.error}');
        }

        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(child: CircularProgressIndicator());
        }

        List<DropdownMenuItem<String>> teacherItems = [
          DropdownMenuItem<String>(
            value: null,
            child: Text('اختر المعلم'),
          ),
        ];

        if (snapshot.hasData) {
          teacherItems.addAll(
            snapshot.data!.docs.map((doc) {
              final data = doc.data() as Map<String, dynamic>;
              final teacherName = '${data['firstName']} ${data['lastName']}';
              return DropdownMenuItem<String>(
                value: doc.id,
                child: Text(teacherName),
              );
            }).toList(),
          );
        }

        return Padding(
          padding: const EdgeInsets.only(bottom: 16.0),
          child: DropdownButtonFormField<String>(
            value: _selectedTeacherId,
            decoration: InputDecoration(
              labelText: 'المعلم المسؤول',
              border: OutlineInputBorder(),
            ),
            items: teacherItems,
            onChanged: (newValue) {
              setState(() {
                _selectedTeacherId = newValue;
              });
            },
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'الرجاء اختيار المعلم';
              }
              return null;
            },
            isExpanded: true,
          ),
        );
      },
    );
  }

  Future<void> _saveHalaqah() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
      });

      try {
        // Get teacher name
        DocumentSnapshot teacherDoc = await FirebaseFirestore.instance
            .collection('users')
            .doc(_selectedTeacherId)
            .get();
        
        final teacherData = teacherDoc.data() as Map<String, dynamic>;
        final teacherName = '${teacherData['firstName']} ${teacherData['lastName']}';

        final halaqahData = {
          'name': _nameController.text,
          'location': _locationController.text,
          'schedule': _scheduleController.text,
          'teacherId': _selectedTeacherId,
          'teacherName': teacherName,
          'updatedAt': FieldValue.serverTimestamp(),
        };

        if (widget.halaqahId == null) {
          // Add new halaqah
          halaqahData['createdAt'] = FieldValue.serverTimestamp();
          await FirebaseFirestore.instance.collection('halaqahs').add(halaqahData);

          // Update teacher's halaqahs list (optional)
          await FirebaseFirestore.instance
              .collection('users')
              .doc(_selectedTeacherId)
              .update({
            'halaqahs': FieldValue.arrayUnion([halaqahData['name']]),
          });
        } else {
          // If teacher has changed, update old and new teacher's halaqahs lists
          if (widget.halaqahData!['teacherId'] != _selectedTeacherId) {
            // Remove halaqah from old teacher's list
            if (widget.halaqahData!['teacherId'] != null) {
              await FirebaseFirestore.instance
                  .collection('users')
                  .doc(widget.halaqahData!['teacherId'])
                  .update({
                'halaqahs': FieldValue.arrayRemove([widget.halaqahData!['name']]),
              });
            }
            
            // Add halaqah to new teacher's list
            await FirebaseFirestore.instance
                .collection('users')
                .doc(_selectedTeacherId)
                .update({
              'halaqahs': FieldValue.arrayUnion([halaqahData['name']]),
            });
          }

          // Update halaqah
          await FirebaseFirestore.instance
              .collection('halaqahs')
              .doc(widget.halaqahId)
              .update(halaqahData);

          // Update all students in this halaqah with new halaqah name if it changed
          if (widget.halaqahData!['name'] != halaqahData['name']) {
            QuerySnapshot studentsQuery = await FirebaseFirestore.instance
                .collection('users')
                .where('halaqahId', isEqualTo: widget.halaqahId)
                .get();

            WriteBatch batch = FirebaseFirestore.instance.batch();
            for (var doc in studentsQuery.docs) {
              batch.update(doc.reference, {'halaqahName': halaqahData['name']});
            }
            await batch.commit();
          }
        }

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(widget.halaqahId == null
                ? 'تم إنشاء الحلقة بنجاح'
                : 'تم تحديث الحلقة بنجاح'),
          ),
        );

        Navigator.pop(context);
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('حدث خطأ: $e')),
        );
      } finally {
        if (mounted) {
          setState(() {
            _isLoading = false;
          });
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(
          title: Text(widget.halaqahId == null ? 'إضافة حلقة جديدة' : 'تعديل الحلقة'),
        ),
        body: _isLoading
            ? Center(child: CircularProgressIndicator())
            : Form(
                key: _formKey,
                child: ListView(
                  padding: EdgeInsets.all(16.0),
                  children: [
                    TextFormField(
                      controller: _nameController,
                      decoration: InputDecoration(
                        labelText: 'اسم الحلقة',
                        border: OutlineInputBorder(),
                      ),
                      validator: (value) =>
                          value!.isEmpty ? 'الرجاء إدخال اسم الحلقة' : null,
                    ),
                    SizedBox(height: 16),
                    _buildTeacherDropdown(),
                    TextFormField(
                      controller: _locationController,
                      decoration: InputDecoration(
                        labelText: 'موقع الحلقة',
                        border: OutlineInputBorder(),
                      ),
                      validator: (value) =>
                          value!.isEmpty ? 'الرجاء إدخال موقع الحلقة' : null,
                    ),
                    SizedBox(height: 16),
                    TextFormField(
                      controller: _scheduleController,
                      decoration: InputDecoration(
                        labelText: 'جدول الحلقة',
                        border: OutlineInputBorder(),
                        hintText: 'مثال: السبت والأحد 4-6 مساءً',
                      ),
                      validator: (value) =>
                          value!.isEmpty ? 'الرجاء إدخال جدول الحلقة' : null,
                    ),
                    SizedBox(height: 20),
                    ElevatedButton(
                      onPressed: _saveHalaqah,
                      child: Text(widget.halaqahId == null ? 'إضافة الحلقة' : 'تحديث الحلقة'),
                      style: ElevatedButton.styleFrom(
                        padding: EdgeInsets.symmetric(vertical: 12),
                      ),
                    ),
                  ],
                ),
              ),
      ),
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _locationController.dispose();
    _scheduleController.dispose();
    super.dispose();
  }
}