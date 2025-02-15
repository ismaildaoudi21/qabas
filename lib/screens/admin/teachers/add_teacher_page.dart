import 'package:flutter/material.dart';
import 'package:intl/intl.dart' as intl;
import 'package:cloud_firestore/cloud_firestore.dart';

class AddTeacherPage extends StatefulWidget {
  @override
  _AddTeacherPageState createState() => _AddTeacherPageState();
}

class _AddTeacherPageState extends State<AddTeacherPage> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _firstNameController = TextEditingController();
  final TextEditingController _lastNameController = TextEditingController();
  final TextEditingController _birthDateController = TextEditingController();
  final TextEditingController _addressController = TextEditingController();
  final TextEditingController _joinDateController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _phoneNumberController = TextEditingController();
  final TextEditingController _qualificationController = TextEditingController();
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController = TextEditingController();
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

  String? _validatePassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'الرجاء إدخال كلمة المرور';
    }
    if (value.length < 6) {
      return 'كلمة المرور يجب أن تكون 6 أحرف على الأقل';
    }
    return null;
  }

  Future<void> _saveTeacher() async {
    if (_formKey.currentState!.validate()) {
      if (_passwordController.text != _confirmPasswordController.text) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('كلمات المرور غير متطابقة')),
        );
        return;
      }

      setState(() {
        _isLoading = true;
      });

      try {
        // Check if username already exists
        var usernameQuery = await FirebaseFirestore.instance
            .collection('users')
            .where('username', isEqualTo: _usernameController.text)
            .get();

        if (usernameQuery.docs.isNotEmpty) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('اسم المستخدم موجود مسبقاً')),
          );
          setState(() {
            _isLoading = false;
          });
          return;
        }

        await FirebaseFirestore.instance.collection('users').add({
          'firstName': _firstNameController.text,
          'lastName': _lastNameController.text,
          'birthDate': Timestamp.fromDate(
              intl.DateFormat('yyyy-MM-dd').parse(_birthDateController.text)),
          'address': _addressController.text,
          'joinDate': Timestamp.fromDate(
              intl.DateFormat('yyyy-MM-dd').parse(_joinDateController.text)),
          'email': _emailController.text,
          'phoneNumber': _phoneNumberController.text,
          'qualification': _qualificationController.text,
          'username': _usernameController.text,
          'password': _passwordController.text,
          'role': 'teacher',
          'createdAt': FieldValue.serverTimestamp(),
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('تم إضافة المعلم بنجاح')),
        );
        Navigator.pop(context);
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('حدث خطأ أثناء إضافة المعلم: $e')),
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
          title: Text('إضافة معلم جديد'),
        ),
        body: _isLoading
            ? Center(child: CircularProgressIndicator())
            : Form(
                key: _formKey,
                child: ListView(
                  padding: EdgeInsets.all(16.0),
                  children: [
                    Text(
                      'المعلومات الشخصية',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 16),
                    _buildTextFormField(
                      controller: _firstNameController,
                      label: 'الاسم الأول',
                    ),
                    _buildTextFormField(
                      controller: _lastNameController,
                      label: 'اسم العائلة',
                    ),
                    _buildDateFormField(
                      controller: _birthDateController,
                      label: 'تاريخ الميلاد',
                    ),
                    _buildTextFormField(
                      controller: _addressController,
                      label: 'العنوان',
                    ),
                    _buildDateFormField(
                      controller: _joinDateController,
                      label: 'تاريخ الانضمام',
                    ),
                    _buildTextFormField(
                      controller: _emailController,
                      label: 'البريد الإلكتروني',
                      keyboardType: TextInputType.emailAddress,
                    ),
                    _buildTextFormField(
                      controller: _phoneNumberController,
                      label: 'رقم الهاتف',
                      keyboardType: TextInputType.phone,
                    ),
                    _buildTextFormField(
                      controller: _qualificationController,
                      label: 'المؤهل العلمي',
                    ),

                    Divider(height: 32),
                    Text(
                      'معلومات تسجيل الدخول',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 16),
                    
                    _buildTextFormField(
                      controller: _usernameController,
                      label: 'اسم المستخدم',
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'الرجاء إدخال اسم المستخدم';
                        }
                        if (value.length < 4) {
                          return 'اسم المستخدم يجب أن يكون 4 أحرف على الأقل';
                        }
                        return null;
                      },
                    ),
                    
                    _buildTextFormField(
                      controller: _passwordController,
                      label: 'كلمة المرور',
                      obscureText: true,
                      validator: _validatePassword,
                    ),
                    
                    _buildTextFormField(
                      controller: _confirmPasswordController,
                      label: 'تأكيد كلمة المرور',
                      obscureText: true,
                      validator: _validatePassword,
                    ),

                    SizedBox(height: 20),
                    ElevatedButton(
                      onPressed: _saveTeacher,
                      child: Text('إضافة المعلم'),
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

  Widget _buildTextFormField({
    required TextEditingController controller,
    required String label,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
    bool obscureText = false,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: TextFormField(
        controller: controller,
        decoration: InputDecoration(
          labelText: label,
          border: OutlineInputBorder(),
        ),
        keyboardType: keyboardType,
        obscureText: obscureText,
        validator: validator ?? (value) {
          if (value == null || value.isEmpty) {
            return 'الرجاء إدخال $label';
          }
          return null;
        },
      ),
    );
  }

  Widget _buildDateFormField({
    required TextEditingController controller,
    required String label,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: TextFormField(
        controller: controller,
        decoration: InputDecoration(
          labelText: label,
          border: OutlineInputBorder(),
          suffixIcon: Icon(Icons.calendar_today),
        ),
        readOnly: true,
        onTap: () => _selectDate(context, controller),
        validator: (value) {
          if (value == null || value.isEmpty) {
            return 'الرجاء اختيار $label';
          }
          return null;
        },
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
    _emailController.dispose();
    _phoneNumberController.dispose();
    _qualificationController.dispose();
    _usernameController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }
}