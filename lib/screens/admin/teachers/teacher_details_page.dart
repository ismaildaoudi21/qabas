import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart' as intl;

class TeacherDetailsPage extends StatefulWidget {
  final String teacherId;
  final Map<String, dynamic> teacherData;

  TeacherDetailsPage({required this.teacherId, required this.teacherData});

  @override
  _TeacherDetailsPageState createState() => _TeacherDetailsPageState();
}

class _TeacherDetailsPageState extends State<TeacherDetailsPage> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _firstNameController;
  late TextEditingController _lastNameController;
  late TextEditingController _birthDateController;
  late TextEditingController _addressController;
  late TextEditingController _joinDateController;
  late TextEditingController _emailController;
  late TextEditingController _phoneNumberController;
  late TextEditingController _qualificationController;
  late TextEditingController _usernameController;
  late TextEditingController _passwordController;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _firstNameController = TextEditingController(text: widget.teacherData['firstName']);
    _lastNameController = TextEditingController(text: widget.teacherData['lastName']);
    _birthDateController = TextEditingController(text: _formatTimestamp(widget.teacherData['birthDate']));
    _addressController = TextEditingController(text: widget.teacherData['address']);
    _joinDateController = TextEditingController(text: _formatTimestamp(widget.teacherData['joinDate']));
    _emailController = TextEditingController(text: widget.teacherData['email']);
    _phoneNumberController = TextEditingController(text: widget.teacherData['phoneNumber']);
    _qualificationController = TextEditingController(text: widget.teacherData['qualification']);
    _usernameController = TextEditingController(text: widget.teacherData['username']);
    _passwordController = TextEditingController(text: widget.teacherData['password']);
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
    super.dispose();
  }

  String _formatTimestamp(dynamic value) {
    if (value == null) return '';
    if (value is Timestamp) {
      return intl.DateFormat('yyyy-MM-dd').format(value.toDate());
    }
    return value.toString();
  }

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

  Future<void> _updateTeacher() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
      });

      try {
        var usernameQuery = await FirebaseFirestore.instance
            .collection('users')
            .where('username', isEqualTo: _usernameController.text)
            .where(FieldPath.documentId, isNotEqualTo: widget.teacherId)
            .get();

        if (usernameQuery.docs.isNotEmpty) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('اسم المستخدم موجود مسبقاً')),
          );
          return;
        }

        await FirebaseFirestore.instance
            .collection('users')
            .doc(widget.teacherId)
            .update({
          'firstName': _firstNameController.text,
          'lastName': _lastNameController.text,
          'birthDate': Timestamp.fromDate(intl.DateFormat('yyyy-MM-dd').parse(_birthDateController.text)),
          'address': _addressController.text,
          'joinDate': Timestamp.fromDate(intl.DateFormat('yyyy-MM-dd').parse(_joinDateController.text)),
          'email': _emailController.text,
          'phoneNumber': _phoneNumberController.text,
          'qualification': _qualificationController.text,
          'username': _usernameController.text,
          'password': _passwordController.text,
          'name': '${_firstNameController.text} ${_lastNameController.text}',
          'role': 'teacher',
        });
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('تم تحديث بيانات المعلم بنجاح')),
        );
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('حدث خطأ أثناء تحديث بيانات المعلم')),
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
          title: Text('تعديل بيانات المعلم'),
        ),
        body: _isLoading 
          ? Center(child: CircularProgressIndicator())
          : Form(
              key: _formKey,
              child: ListView(
                padding: EdgeInsets.all(16.0),
                children: [
                  Text(
                    'المعلومات الشخصية:',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  SizedBox(height: 16),
                  _buildTextFormField(_firstNameController, 'الاسم'),
                  _buildTextFormField(_lastNameController, 'اسم العائلة'),
                  _buildDateFormField(_birthDateController, 'تاريخ الميلاد'),
                  _buildTextFormField(_addressController, 'العنوان'),
                  _buildDateFormField(_joinDateController, 'تاريخ الانضمام'),
                  _buildTextFormField(_emailController, 'البريد الإلكتروني'),
                  _buildTextFormField(_phoneNumberController, 'رقم الهاتف'),
                  _buildTextFormField(_qualificationController, 'المؤهل العلمي'),
                  
                  Divider(height: 32),
                  Text('بيانات تسجيل الدخول:', 
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  SizedBox(height: 16),
                  _buildTextFormField(_usernameController, 'اسم المستخدم'),
                  _buildTextFormField(_passwordController, 'كلمة المرور', 
                    obscureText: true),
                  
                  SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: _isLoading ? null : _updateTeacher,
                    child: Text('تحديث بيانات المعلم'),
                  ),
                ],
              ),
            ),
      ),
    );
  }

  Widget _buildTextFormField(TextEditingController controller, String label, 
      {bool obscureText = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: TextFormField(
        controller: controller,
        decoration: InputDecoration(
          labelText: label,
          border: OutlineInputBorder(),
        ),
        obscureText: obscureText,
        validator: (value) {
          if (value == null || value.isEmpty) {
            return 'الرجاء إدخال $label';
          }
          return null;
        },
      ),
    );
  }

  Widget _buildDateFormField(TextEditingController controller, String label) {
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
            return 'الرجاء إدخال $label';
          }
          return null;
        },
      ),
    );
  }
}