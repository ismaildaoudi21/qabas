import 'package:flutter/material.dart';
import 'package:intl/intl.dart' as intl;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'add_parent_page.dart';

class AddStudentPage extends StatefulWidget {
  @override
  _AddStudentPageState createState() => _AddStudentPageState();
}

class _AddStudentPageState extends State<AddStudentPage> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _firstNameController = TextEditingController();
  final TextEditingController _lastNameController = TextEditingController();
  final TextEditingController _birthDateController = TextEditingController();
  final TextEditingController _addressController = TextEditingController();
  final TextEditingController _joinDateController = TextEditingController();
  final TextEditingController _secretCodeController = TextEditingController();
  final TextEditingController _usernameController = TextEditingController();
  String? _selectedHalaqahId;
  bool _isLoading = false;

  Future<void> _selectDate(BuildContext context, TextEditingController controller) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
    );
    if (picked != null) {
      setState(() {
        controller.text = intl.DateFormat('yyyy-MM-dd').format(picked);
      });
    }
  }

  Widget _buildTextFormField({
    required TextEditingController controller,
    required String label,
    required String? Function(String?) validator,
    bool obscureText = false,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: TextFormField(
        controller: controller,
        decoration: InputDecoration(
          labelText: label,
          alignLabelWithHint: true,
          border: OutlineInputBorder(),
        ),
        textAlign: TextAlign.right,
        obscureText: obscureText,
        validator: validator,
      ),
    );
  }

  Widget _buildDateFormField({
    required TextEditingController controller,
    required String label,
    required VoidCallback onTap,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: TextFormField(
        controller: controller,
        decoration: InputDecoration(
          labelText: label,
          alignLabelWithHint: true,
          border: OutlineInputBorder(),
          suffixIcon: Icon(Icons.calendar_today),
        ),
        textAlign: TextAlign.right,
        readOnly: true,
        onTap: onTap,
        validator: (value) => value!.isEmpty ? 'الرجاء إدخال $label' : null,
      ),
    );
  }

  Widget _buildDropdownField() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('halaqahs').snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Text('حدث خطأ: ${snapshot.error}');
        }

        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(child: CircularProgressIndicator());
        }

        List<DropdownMenuItem<String>> halaqahItems = [];
        
        if (snapshot.hasData) {
          halaqahItems = snapshot.data!.docs.map((doc) {
            final data = doc.data() as Map<String, dynamic>;
            return DropdownMenuItem<String>(
              value: doc.id,
              child: Text(data['name'] ?? ''),
            );
          }).toList();
        }

        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 8.0),
          child: DropdownButtonFormField<String>(
            value: _selectedHalaqahId,
            decoration: InputDecoration(
              labelText: 'الحلقة المنضم إليها',
              alignLabelWithHint: true,
              border: OutlineInputBorder(),
            ),
            items: halaqahItems,
            onChanged: (newValue) {
              setState(() {
                _selectedHalaqahId = newValue;
              });
            },
            validator: (value) => value == null ? 'الرجاء اختيار الحلقة' : null,
            isExpanded: true,
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(
          title: Text('إنشاء حساب طالب'),
          centerTitle: true,
        ),
        body: _isLoading
            ? Center(child: CircularProgressIndicator())
            : Center(
                child: SingleChildScrollView(
                  child: Form(
                    key: _formKey,
                    child: Container(
                      width: MediaQuery.of(context).size.width * 0.9,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Text(
                            'معلومات الطالب:',
                            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                            textAlign: TextAlign.center,
                          ),
                          SizedBox(height: 16),
                          _buildTextFormField(
                            controller: _firstNameController,
                            label: 'اسم الطالب',
                            validator: (value) => value!.isEmpty ? 'الرجاء إدخال اسم الطالب' : null,
                          ),
                          _buildTextFormField(
                            controller: _lastNameController,
                            label: 'اللقب',
                            validator: (value) => value!.isEmpty ? 'الرجاء إدخال اللقب' : null,
                          ),
                          _buildDateFormField(
                            controller: _birthDateController,
                            label: 'تاريخ الميلاد',
                            onTap: () => _selectDate(context, _birthDateController),
                          ),
                          _buildTextFormField(
                            controller: _addressController,
                            label: 'عنوان السكن',
                            validator: (value) => value!.isEmpty ? 'الرجاء إدخال عنوان السكن' : null,
                          ),
                          _buildDateFormField(
                            controller: _joinDateController,
                            label: 'تاريخ الالتحاق',
                            onTap: () => _selectDate(context, _joinDateController),
                          ),
                          _buildDropdownField(),
                          Divider(height: 32),
                          Text(
                            'معلومات تسجيل الدخول:',
                            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                            textAlign: TextAlign.center,
                          ),
                          SizedBox(height: 16),
                          _buildTextFormField(
                            controller: _usernameController,
                            label: 'اسم المستخدم',
                            validator: (value) => value!.isEmpty ? 'الرجاء إدخال اسم المستخدم' : null,
                          ),
                          _buildTextFormField(
                            controller: _secretCodeController,
                            label: 'كلمة المرور',
                            validator: (value) => value!.isEmpty ? 'الرجاء إدخال كلمة المرور' : null,
                            obscureText: true,
                          ),
                          SizedBox(height: 20),
                          ElevatedButton(
                            child: Text('التالي'),
                            onPressed: () async {
                              if (_formKey.currentState!.validate()) {
                                setState(() {
                                  _isLoading = true;
                                });

                                try {
                                  var usernameQuery = await FirebaseFirestore.instance
                                      .collection('users')
                                      .where('username', isEqualTo: _usernameController.text)
                                      .get();

                                  if (usernameQuery.docs.isNotEmpty) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(content: Text('اسم المستخدم موجود مسبقاً')),
                                    );
                                    return;
                                  }

                                  DocumentSnapshot halaqahDoc = await FirebaseFirestore.instance
                                      .collection('halaqahs')
                                      .doc(_selectedHalaqahId)
                                      .get();
                                  
                                  final halaqahData = halaqahDoc.data() as Map<String, dynamic>;

                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => AddParentPage(
                                        studentData: {
                                          'firstName': _firstNameController.text,
                                          'lastName': _lastNameController.text,
                                          'birthDate': _birthDateController.text,
                                          'address': _addressController.text,
                                          'joinDate': _joinDateController.text,
                                          'username': _usernameController.text,
                                          'password': _secretCodeController.text,
                                          'halaqahId': _selectedHalaqahId,
                                          'halaqahName': halaqahData['name'],
                                          'role': 'student',
                                        },
                                      ),
                                    ),
                                  );
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
                            },
                            style: ElevatedButton.styleFrom(
                              padding: EdgeInsets.symmetric(vertical: 12),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
      ),
    );
  }

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _birthDateController.dispose();
    _addressController.dispose();
    _joinDateController.dispose();
    _secretCodeController.dispose();
    _usernameController.dispose();
    super.dispose();
  }
}