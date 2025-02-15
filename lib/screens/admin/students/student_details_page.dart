import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart' as intl;

class StudentDetailsPage extends StatefulWidget {
 final String studentId;
 final Map<String, dynamic> studentData;

 StudentDetailsPage({required this.studentId, required this.studentData});

 @override
 _StudentDetailsPageState createState() => _StudentDetailsPageState();
}

class _StudentDetailsPageState extends State<StudentDetailsPage> {
 final _formKey = GlobalKey<FormState>();
 late TextEditingController _firstNameController;
 late TextEditingController _lastNameController;
 late TextEditingController _birthDateController;
 late TextEditingController _addressController;
 late TextEditingController _joinDateController;
 late TextEditingController _emailController;
 late TextEditingController _parentNameController;
 late TextEditingController _phoneNumberController;
 late TextEditingController _studentUsernameController;
 late TextEditingController _studentPasswordController; 
 late TextEditingController _parentUsernameController;
 late TextEditingController _parentPasswordController;
 String? _selectedHalaqahId;
 bool _isLoading = false;

 @override
 void initState() {
   super.initState();
   _firstNameController = TextEditingController(text: widget.studentData['firstName']);
   _lastNameController = TextEditingController(text: widget.studentData['lastName']);
   _birthDateController = TextEditingController(text: _formatTimestamp(widget.studentData['birthDate']));
   _addressController = TextEditingController(text: widget.studentData['address']);
   _joinDateController = TextEditingController(text: _formatTimestamp(widget.studentData['joinDate']));
   _emailController = TextEditingController(text: widget.studentData['email']);
   _parentNameController = TextEditingController(text: widget.studentData['parentName']);
   _phoneNumberController = TextEditingController(text: widget.studentData['phoneNumber']);
   _studentUsernameController = TextEditingController(text: widget.studentData['username']);
   _studentPasswordController = TextEditingController(text: widget.studentData['password']);
   _parentUsernameController = TextEditingController(text: widget.studentData['parentUsername']); 
   _parentPasswordController = TextEditingController(text: widget.studentData['parentPassword']);
   _selectedHalaqahId = widget.studentData['halaqahId'];
 }

 @override
 void dispose() {
   _firstNameController.dispose();
   _lastNameController.dispose();
   _birthDateController.dispose();
   _addressController.dispose();
   _joinDateController.dispose();
   _emailController.dispose();
   _parentNameController.dispose();
   _phoneNumberController.dispose();
   _studentUsernameController.dispose();
   _studentPasswordController.dispose();
   _parentUsernameController.dispose();
   _parentPasswordController.dispose();
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

 Future<void> _updateStudent() async {
   if (_formKey.currentState!.validate()) {
     setState(() {
       _isLoading = true;
     });

     try {
       // Check if username exists
       var studentUsernameQuery = await FirebaseFirestore.instance
           .collection('users')
           .where('username', isEqualTo: _studentUsernameController.text)
           .where(FieldPath.documentId, isNotEqualTo: widget.studentId)
           .get();

       var parentUsernameQuery = await FirebaseFirestore.instance
           .collection('users')
           .where('parentUsername', isEqualTo: _parentUsernameController.text)
           .where(FieldPath.documentId, isNotEqualTo: widget.studentId)
           .get();

       if (studentUsernameQuery.docs.isNotEmpty || parentUsernameQuery.docs.isNotEmpty) {
         ScaffoldMessenger.of(context).showSnackBar(
           SnackBar(content: Text('اسم المستخدم موجود مسبقاً')),
         );
         return;
       }

       String? halaqahName;
       if (_selectedHalaqahId != null) {
         final halaqahDoc = await FirebaseFirestore.instance
             .collection('halaqahs')
             .doc(_selectedHalaqahId)
             .get();
         final halaqahData = halaqahDoc.data();
         halaqahName = halaqahData?['name'];
       }

       await FirebaseFirestore.instance
           .collection('users')
           .doc(widget.studentId)
           .update({
         'firstName': _firstNameController.text,
         'lastName': _lastNameController.text,
         'birthDate': Timestamp.fromDate(intl.DateFormat('yyyy-MM-dd').parse(_birthDateController.text)),
         'address': _addressController.text,
         'joinDate': Timestamp.fromDate(intl.DateFormat('yyyy-MM-dd').parse(_joinDateController.text)),
         'email': _emailController.text,
         'parentName': _parentNameController.text,
         'phoneNumber': _phoneNumberController.text,
         'halaqahId': _selectedHalaqahId,
         'halaqahName': halaqahName,
         'username': _studentUsernameController.text,
         'password': _studentPasswordController.text, 
         'parentUsername': _parentUsernameController.text,
         'parentPassword': _parentPasswordController.text,
         'name': '${_firstNameController.text} ${_lastNameController.text}',
       });
       Navigator.pop(context);
       ScaffoldMessenger.of(context).showSnackBar(
         SnackBar(content: Text('تم تحديث بيانات الطالب بنجاح')),
       );
     } catch (e) {
       ScaffoldMessenger.of(context).showSnackBar(
         SnackBar(content: Text('حدث خطأ أثناء تحديث بيانات الطالب')),
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

 Widget _buildHalaqahDropdown() {
   return StreamBuilder<QuerySnapshot>(
     stream: FirebaseFirestore.instance.collection('halaqahs').snapshots(),
     builder: (context, snapshot) {
       if (snapshot.hasError) {
         return Text('حدث خطأ: ${snapshot.error}');
       }

       if (snapshot.connectionState == ConnectionState.waiting) {
         return Center(child: CircularProgressIndicator());
       }

       List<DropdownMenuItem<String>> halaqahItems = [
         DropdownMenuItem<String>(
           value: null,
           child: Text('بدون حلقة'),
         ),
       ];

       if (snapshot.hasData) {
         halaqahItems.addAll(
           snapshot.data!.docs.map((doc) {
             final data = doc.data() as Map<String, dynamic>;
             return DropdownMenuItem<String>(
               value: doc.id,
               child: Text(data['name'] ?? ''),
             );
           }).toList(),
         );
       }

       return Padding(
         padding: const EdgeInsets.only(bottom: 16.0),
         child: DropdownButtonFormField<String>(
           value: _selectedHalaqahId,
           decoration: InputDecoration(
             labelText: 'الحلقة',
             border: OutlineInputBorder(),
           ),
           items: halaqahItems,
           onChanged: (newValue) {
             setState(() {
               _selectedHalaqahId = newValue;
             });
           },
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
         title: Text('تعديل بيانات الطالب'),
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
                 _buildTextFormField(_parentNameController, 'اسم ولي الأمر'),
                 _buildTextFormField(_phoneNumberController, 'رقم هاتف ولي الأمر'),
                 _buildHalaqahDropdown(),
                 
                 Divider(height: 32),
                 Text('بيانات تسجيل دخول الطالب:', 
                   style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                 SizedBox(height: 16),
                 _buildTextFormField(_studentUsernameController, 'اسم المستخدم للطالب'),
                 _buildTextFormField(_studentPasswordController, 'كلمة المرور للطالب', 
                   obscureText: true),

                 Divider(height: 32), 
                 Text('بيانات تسجيل دخول ولي الأمر:', 
                   style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                 SizedBox(height: 16),
                 _buildTextFormField(_parentUsernameController, 'اسم المستخدم لولي الأمر'),
                 _buildTextFormField(_parentPasswordController, 'كلمة المرور لولي الأمر', 
                   obscureText: true),
                 
                 SizedBox(height: 20),
                 ElevatedButton(
                   onPressed: _isLoading ? null : _updateStudent,
                   child: Text('تحديث بيانات الطالب'),
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