import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart' as intl;

class AddParentPage extends StatefulWidget {
  final Map<String, dynamic> studentData;

  AddParentPage({required this.studentData});

  @override
  _AddParentPageState createState() => _AddParentPageState();
}

class _AddParentPageState extends State<AddParentPage> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _parentNameController = TextEditingController();
  final TextEditingController _phoneNumberController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _parentUsernameController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController = TextEditingController();

  bool _isLoading = false;

  Future<void> _createAccount() async {
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
        var usernameQuery = await FirebaseFirestore.instance
            .collection('users')
            .where('username', whereIn: [widget.studentData['username'], _parentUsernameController.text])
            .get();

        if (usernameQuery.docs.isNotEmpty) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('اسم المستخدم موجود مسبقاً')),
          );
          return;
        }

        Map<String, dynamic> userData = {
          ...widget.studentData,
          'parentName': _parentNameController.text,
          'phoneNumber': _phoneNumberController.text,
          'email': _emailController.text,
          'parentUsername': _parentUsernameController.text,
          'parentPassword': _passwordController.text,
          'parentRole': 'parent',
          'createdAt': FieldValue.serverTimestamp(),
          'name': widget.studentData['firstName'] + ' ' + widget.studentData['lastName'],
        };

        userData['birthDate'] = Timestamp.fromDate(
            intl.DateFormat('yyyy-MM-dd').parse(userData['birthDate']));
        userData['joinDate'] = Timestamp.fromDate(
            intl.DateFormat('yyyy-MM-dd').parse(userData['joinDate']));

        await FirebaseFirestore.instance.collection('users').add(userData);

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('تم إنشاء الحساب بنجاح')),
        );
        
        Navigator.of(context).pop();
        Navigator.of(context).pop();
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('حدث خطأ أثناء إنشاء الحساب: $e')),
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

  String? _validateEmail(String? value) {
    if (value == null || value.isEmpty) {
      return 'الرجاء إدخال البريد الإلكتروني';
    }
    if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value)) {
      return 'الرجاء إدخال بريد إلكتروني صحيح';
    }
    return null;
  }

  String? _validatePhoneNumber(String? value) {
    if (value == null || value.isEmpty) {
      return 'الرجاء إدخال رقم الهاتف';
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(
          title: Text('إنشاء حساب طالب'),
        ),
        body: _isLoading 
          ? Center(child: CircularProgressIndicator())
          : Form(
              key: _formKey,
              child: ListView(
                padding: EdgeInsets.all(16.0),
                children: [
                  Text('معلومات خاصة بولي الأمر:', 
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  SizedBox(height: 16),
                  TextFormField(
                    controller: _parentNameController,
                    decoration: InputDecoration(
                      labelText: 'اسم ولي الأمر',
                      border: OutlineInputBorder(),
                    ),
                    validator: (value) => value!.isEmpty ? 'الرجاء إدخال اسم ولي الأمر' : null,
                  ),
                  SizedBox(height: 16),
                  TextFormField(
                    controller: _phoneNumberController,
                    decoration: InputDecoration(
                      labelText: 'رقم الهاتف',
                      border: OutlineInputBorder(),
                    ),
                    keyboardType: TextInputType.phone,
                    validator: _validatePhoneNumber,
                  ),
                  SizedBox(height: 16),
                  TextFormField(
                    controller: _emailController,
                    decoration: InputDecoration(
                      labelText: 'البريد الإلكتروني',
                      border: OutlineInputBorder(),
                    ),
                    keyboardType: TextInputType.emailAddress,
                    validator: _validateEmail,
                  ),
                  SizedBox(height: 16),
                  Divider(),
                  Text('معلومات تسجيل الدخول:', 
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  SizedBox(height: 16),
                  TextFormField(
                    controller: _parentUsernameController,
                    decoration: InputDecoration(
                      labelText: 'اسم المستخدم',
                      border: OutlineInputBorder(),
                    ),
                    validator: (value) => value!.isEmpty ? 'الرجاء إدخال اسم المستخدم' : null,
                  ),
                  SizedBox(height: 16),
                  TextFormField(
                    controller: _passwordController,
                    decoration: InputDecoration(
                      labelText: 'كلمة المرور',
                      border: OutlineInputBorder(),
                    ),
                    obscureText: true,
                    validator: (value) => value!.isEmpty ? 'الرجاء إدخال كلمة المرور' : null,
                  ),
                  SizedBox(height: 16),
                  TextFormField(
                    controller: _confirmPasswordController,
                    decoration: InputDecoration(
                      labelText: 'تأكيد كلمة المرور',
                      border: OutlineInputBorder(),
                    ),
                    obscureText: true,
                    validator: (value) {
                      if (value!.isEmpty) return 'الرجاء تأكيد كلمة المرور';
                      if (value != _passwordController.text) return 'كلمات المرور غير متطابقة';
                      return null;
                    },
                  ),
                  SizedBox(height: 20),
                  ElevatedButton(
                    child: Text('إنشاء حساب'),
                    onPressed: _isLoading ? null : _createAccount,
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
    _parentNameController.dispose();
    _phoneNumberController.dispose();
    _emailController.dispose();
    _parentUsernameController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }
}