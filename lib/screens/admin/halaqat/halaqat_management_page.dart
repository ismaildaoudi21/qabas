import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:qabas/utils/app_colors.dart';

class HalaqatManagementPage extends StatefulWidget {
  @override
  _HalaqatManagementPageState createState() => _HalaqatManagementPageState();
}

class _HalaqatManagementPageState extends State<HalaqatManagementPage> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _scheduleController = TextEditingController();
  final _locationController = TextEditingController();
  String? _selectedTeacherId;
  bool _isLoading = false;
  String? _editingHalaqahId;

  @override
  void dispose() {
    _nameController.dispose();
    _scheduleController.dispose();
    _locationController.dispose();
    super.dispose();
  }

  void _editHalaqah(Map<String, dynamic> halaqah, String halaqahId) {
    setState(() {
      _editingHalaqahId = halaqahId;
      _nameController.text = halaqah['name'] ?? '';
      _scheduleController.text = halaqah['schedule'] ?? '';
      _locationController.text = halaqah['location'] ?? '';
      _selectedTeacherId = halaqah['teacherId'];
    });
  }

  Future<void> _saveHalaqah() async {
    if (!_formKey.currentState!.validate() || _selectedTeacherId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('الرجاء تعبئة جميع الحقول المطلوبة')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final data = {
        'name': _nameController.text,
        'schedule': _scheduleController.text,
        'location': _locationController.text,
        'teacherId': _selectedTeacherId,
      };

      if (_editingHalaqahId != null) {
        await FirebaseFirestore.instance
            .collection('halaqahs')
            .doc(_editingHalaqahId)
            .update(data);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('تم تحديث بيانات الحلقة بنجاح')),
        );
      } else {
        await FirebaseFirestore.instance.collection('halaqahs').add({
          ...data,
          'createdAt': FieldValue.serverTimestamp(),
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('تم إضافة الحلقة بنجاح')),
        );
      }

      _clearForm();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('حدث خطأ أثناء حفظ بيانات الحلقة')),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _clearForm() {
    _formKey.currentState?.reset();
    _nameController.clear();
    _scheduleController.clear();
    _locationController.clear();
    _selectedTeacherId = null;
    setState(() {
      _editingHalaqahId = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(
          title: Text('إدارة الحلقات'),
          backgroundColor: AppColors.purple,
        ),
        body: SingleChildScrollView(
          padding: EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Form(
                key: _formKey,
                child: Column(
                  children: [
                    Text(
                      _editingHalaqahId != null ? 'تعديل حلقة' : 'إضافة حلقة جديدة',
                      style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                    ),
                    SizedBox(height: 16),
                    TextFormField(
                      controller: _nameController,
                      decoration: InputDecoration(
                        labelText: 'اسم الحلقة',
                        border: OutlineInputBorder(),
                      ),
                      validator: (value) =>
                          value?.isEmpty ?? true ? 'هذا الحقل مطلوب' : null,
                    ),
                    SizedBox(height: 16),
                    StreamBuilder<QuerySnapshot>(
                      stream: FirebaseFirestore.instance
                          .collection('users')
                          .where('role', isEqualTo: 'teacher')
                          .snapshots(),
                      builder: (context, snapshot) {
                        if (!snapshot.hasData) {
                          return CircularProgressIndicator();
                        }

                        return DropdownButtonFormField<String>(
                          value: _selectedTeacherId,
                          decoration: InputDecoration(
                            labelText: 'المعلم',
                            border: OutlineInputBorder(),
                          ),
                          items: snapshot.data!.docs.map((doc) {
                            final data = doc.data() as Map<String, dynamic>;
                            return DropdownMenuItem(
                              value: doc.id,
                              child: Text('${data['firstName']} ${data['lastName']}'),
                            );
                          }).toList(),
                          onChanged: (value) {
                            setState(() => _selectedTeacherId = value);
                          },
                        );
                      },
                    ),
                    SizedBox(height: 16),
                    TextFormField(
                      controller: _scheduleController,
                      decoration: InputDecoration(
                        labelText: 'الجدول',
                        border: OutlineInputBorder(),
                      ),
                      validator: (value) =>
                          value?.isEmpty ?? true ? 'هذا الحقل مطلوب' : null,
                    ),
                    SizedBox(height: 16),
                    TextFormField(
                      controller: _locationController,
                      decoration: InputDecoration(
                        labelText: 'الموقع',
                        border: OutlineInputBorder(),
                      ),
                      validator: (value) =>
                          value?.isEmpty ?? true ? 'هذا الحقل مطلوب' : null,
                    ),
                    SizedBox(height: 24),
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton(
                            onPressed: _isLoading ? null : _saveHalaqah,
                            child: _isLoading
                                ? CircularProgressIndicator(color: Colors.white)
                                : Text(_editingHalaqahId != null 
                                    ? 'حفظ التغييرات' 
                                    : 'إضافة حلقة'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.purple,
                              minimumSize: Size(double.infinity, 48),
                            ),
                          ),
                        ),
                        if (_editingHalaqahId != null) ...[
                          SizedBox(width: 16),
                          Expanded(
                            child: ElevatedButton(
                              onPressed: _isLoading ? null : _clearForm,
                              child: Text('إلغاء التعديل'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.grey,
                                minimumSize: Size(double.infinity, 48),
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
              SizedBox(height: 32),
              Text(
                'قائمة الحلقات',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 16),
              StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance
                    .collection('halaqahs')
                    .snapshots(),
                builder: (context, snapshot) {
                  if (!snapshot.hasData) {
                    return Center(child: CircularProgressIndicator());
                  }

                  return ListView.builder(
                    shrinkWrap: true,
                    physics: NeverScrollableScrollPhysics(),
                    itemCount: snapshot.data!.docs.length,
                    itemBuilder: (context, index) {
                      final doc = snapshot.data!.docs[index];
                      final data = doc.data() as Map<String, dynamic>;
                      return Card(
                        child: ListTile(
                          leading: CircleAvatar(
                            backgroundColor: AppColors.purple.withOpacity(0.2),
                            child: Icon(Icons.class_, color: AppColors.purple),
                          ),
                          title: Text(data['name'] ?? ''),
                          subtitle: StreamBuilder<DocumentSnapshot>(
                            stream: FirebaseFirestore.instance
                                .collection('users')
                                .doc(data['teacherId'])
                                .snapshots(),
                            builder: (context, teacherSnapshot) {
                              if (!teacherSnapshot.hasData) {
                                return Text('جاري تحميل المعلم...');
                              }
                              final teacherData = teacherSnapshot.data!.data() 
                                  as Map<String, dynamic>?;
                              return Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text('المعلم: ${teacherData?['firstName']} ${teacherData?['lastName']}'),
                                  Text('الجدول: ${data['schedule']}'),
                                  Text('الموقع: ${data['location']}'),
                                ],
                              );
                            },
                          ),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                icon: Icon(Icons.edit, color: AppColors.purple),
                                onPressed: () => _editHalaqah(data, doc.id),
                              ),
                              IconButton(
                                icon: Icon(Icons.delete, color: Colors.red),
                                onPressed: () async {
                                  try {
                                    await doc.reference.delete();
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(content: Text('تم حذف الحلقة بنجاح')),
                                    );
                                  } catch (e) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(content: Text('حدث خطأ أثناء حذف الحلقة')),
                                    );
                                  }
                                },
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
} 