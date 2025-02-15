import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:qabas/utils/app_colors.dart';

class StudentsManagementPage extends StatefulWidget {
  @override
  _StudentsManagementPageState createState() => _StudentsManagementPageState();
}

class _StudentsManagementPageState extends State<StudentsManagementPage> {
  final _formKey = GlobalKey<FormState>();
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  String? _selectedHalaqahId;
  bool _isLoading = false;
  String? _editingStudentId;

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _editStudent(Map<String, dynamic> student, String studentId) {
    setState(() {
      _editingStudentId = studentId;
      _firstNameController.text = student['firstName'] ?? '';
      _lastNameController.text = student['lastName'] ?? '';
      _usernameController.text = student['username'] ?? '';
      _selectedHalaqahId = student['halaqahId'];
    });
  }

  Future<void> _saveStudent() async {
    if (!_formKey.currentState!.validate() || _selectedHalaqahId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('الرجاء تعبئة جميع الحقول المطلوبة')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final data = {
        'firstName': _firstNameController.text,
        'lastName': _lastNameController.text,
        'username': _usernameController.text,
        'halaqahId': _selectedHalaqahId,
        'role': 'student',
      };

      if (_passwordController.text.isNotEmpty) {
        data['password'] = _passwordController.text;
      }

      if (_editingStudentId != null) {
        await FirebaseFirestore.instance
            .collection('users')
            .doc(_editingStudentId)
            .update(data);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('تم تحديث بيانات الطالب بنجاح')),
        );
      } else {
        if (_passwordController.text.isEmpty) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('كلمة المرور مطلوبة للطالب الجديد')),
          );
          return;
        }
        await FirebaseFirestore.instance.collection('users').add(data);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('تم إضافة الطالب بنجاح')),
        );
      }

      _clearForm();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('حدث خطأ أثناء حفظ بيانات الطالب')),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _clearForm() {
    _formKey.currentState?.reset();
    _firstNameController.clear();
    _lastNameController.clear();
    _usernameController.clear();
    _passwordController.clear();
    _selectedHalaqahId = null;
    setState(() {
      _editingStudentId = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(
          title: Text('إدارة الطلاب'),
          backgroundColor: AppColors.green1,
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
                      _editingStudentId != null ? 'تعديل طالب' : 'إضافة طالب جديد',
                      style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                    ),
                    SizedBox(height: 16),
                    TextFormField(
                      controller: _firstNameController,
                      decoration: InputDecoration(
                        labelText: 'الاسم الأول',
                        border: OutlineInputBorder(),
                      ),
                      validator: (value) =>
                          value?.isEmpty ?? true ? 'هذا الحقل مطلوب' : null,
                    ),
                    SizedBox(height: 16),
                    TextFormField(
                      controller: _lastNameController,
                      decoration: InputDecoration(
                        labelText: 'الاسم الأخير',
                        border: OutlineInputBorder(),
                      ),
                      validator: (value) =>
                          value?.isEmpty ?? true ? 'هذا الحقل مطلوب' : null,
                    ),
                    SizedBox(height: 16),
                    StreamBuilder<QuerySnapshot>(
                      stream: FirebaseFirestore.instance
                          .collection('halaqahs')
                          .snapshots(),
                      builder: (context, snapshot) {
                        if (!snapshot.hasData) {
                          return CircularProgressIndicator();
                        }

                        return DropdownButtonFormField<String>(
                          value: _selectedHalaqahId,
                          decoration: InputDecoration(
                            labelText: 'الحلقة',
                            border: OutlineInputBorder(),
                          ),
                          items: snapshot.data!.docs.map((doc) {
                            final data = doc.data() as Map<String, dynamic>;
                            return DropdownMenuItem(
                              value: doc.id,
                              child: Text(data['name'] ?? ''),
                            );
                          }).toList(),
                          onChanged: (value) {
                            setState(() => _selectedHalaqahId = value);
                          },
                        );
                      },
                    ),
                    SizedBox(height: 16),
                    TextFormField(
                      controller: _usernameController,
                      decoration: InputDecoration(
                        labelText: 'اسم المستخدم',
                        border: OutlineInputBorder(),
                      ),
                      validator: (value) =>
                          value?.isEmpty ?? true ? 'هذا الحقل مطلوب' : null,
                    ),
                    SizedBox(height: 16),
                    TextFormField(
                      controller: _passwordController,
                      decoration: InputDecoration(
                        labelText: _editingStudentId != null 
                            ? 'كلمة المرور (اتركها فارغة إذا لم ترد تغييرها)' 
                            : 'كلمة المرور',
                        border: OutlineInputBorder(),
                      ),
                      obscureText: true,
                      validator: (value) => _editingStudentId == null && 
                          (value?.isEmpty ?? true) ? 'هذا الحقل مطلوب' : null,
                    ),
                    SizedBox(height: 24),
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton(
                            onPressed: _isLoading ? null : _saveStudent,
                            child: _isLoading
                                ? CircularProgressIndicator(color: Colors.white)
                                : Text(_editingStudentId != null 
                                    ? 'حفظ التغييرات' 
                                    : 'إضافة طالب'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.green1,
                              minimumSize: Size(double.infinity, 48),
                            ),
                          ),
                        ),
                        if (_editingStudentId != null) ...[
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
                'قائمة الطلاب',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 16),
              StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance
                    .collection('users')
                    .where('role', isEqualTo: 'student')
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
                            backgroundColor: AppColors.green1.withOpacity(0.2),
                            child: Icon(Icons.person, color: AppColors.green1),
                          ),
                          title: Text('${data['firstName']} ${data['lastName']}'),
                          subtitle: StreamBuilder<DocumentSnapshot>(
                            stream: FirebaseFirestore.instance
                                .collection('halaqahs')
                                .doc(data['halaqahId'])
                                .snapshots(),
                            builder: (context, halaqahSnapshot) {
                              if (!halaqahSnapshot.hasData) {
                                return Text('جاري تحميل الحلقة...');
                              }
                              final halaqahData = halaqahSnapshot.data!.data() 
                                  as Map<String, dynamic>?;
                              return Text(
                                  'الحلقة: ${halaqahData?['name'] ?? 'غير محدد'}');
                            },
                          ),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                icon: Icon(Icons.edit, color: AppColors.green1),
                                onPressed: () => _editStudent(data, doc.id),
                              ),
                              IconButton(
                                icon: Icon(Icons.delete, color: Colors.red),
                                onPressed: () async {
                                  try {
                                    await doc.reference.delete();
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(content: Text('تم حذف الطالب بنجاح')),
                                    );
                                  } catch (e) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(content: Text('حدث خطأ أثناء حذف الطالب')),
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