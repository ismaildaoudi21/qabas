import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AdminDetailsPage extends StatefulWidget {
 final String adminId;

 AdminDetailsPage({required this.adminId});

 @override
 _AdminDetailsPageState createState() => _AdminDetailsPageState();
}

class _AdminDetailsPageState extends State<AdminDetailsPage> {
 late Future<DocumentSnapshot> _adminFuture;

 @override
 void initState() {
   super.initState();
   _loadAdminData();
 }

 void _loadAdminData() {
   _adminFuture = FirebaseFirestore.instance
       .collection('users')
       .doc(widget.adminId)
       .get();
 }

 Future<void> _deleteAdmin() async {
   try {
     await FirebaseFirestore.instance
         .collection('users')
         .doc(widget.adminId)
         .delete();
     Navigator.pop(context);
     ScaffoldMessenger.of(context).showSnackBar(
       SnackBar(content: Text('تم حذف المشرف بنجاح')),
     );
   } catch (e) {
     ScaffoldMessenger.of(context).showSnackBar(
       SnackBar(content: Text('حدث خطأ أثناء الحذف')),
     );
   }
 }

 @override
 Widget build(BuildContext context) {
   return Directionality(
     textDirection: TextDirection.rtl,
     child: Scaffold(
       appBar: AppBar(
         title: Text('تفاصيل المشرف'),
         actions: [
           IconButton(
             icon: Icon(Icons.edit),
             onPressed: () async {
               final snapshot = await _adminFuture;
               if (snapshot.exists) {
                 Navigator.push(
                   context,
                   MaterialPageRoute(
                     builder: (context) => EditAdminPage(
                       adminId: widget.adminId,
                       adminData: snapshot.data() as Map<String, dynamic>,
                     ),
                   ),
                 ).then((_) => _loadAdminData());
               }
             },
           ),
           IconButton(
             icon: Icon(Icons.delete),
             onPressed: () {
               showDialog(
                 context: context,
                 builder: (context) => AlertDialog(
                   title: Text('تأكيد الحذف'),
                   content: Text('هل أنت متأكد من حذف هذا المشرف؟'),
                   actions: [
                     TextButton(
                       child: Text('إلغاء'),
                       onPressed: () => Navigator.pop(context),
                     ),
                     TextButton(
                       child: Text('حذف'),
                       onPressed: () {
                         Navigator.pop(context);
                         _deleteAdmin();
                       },
                     ),
                   ],
                 ),
               );
             },
           ),
         ],
       ),
       body: FutureBuilder<DocumentSnapshot>(
         future: _adminFuture,
         builder: (context, snapshot) {
           if (snapshot.connectionState == ConnectionState.waiting) {
             return Center(child: CircularProgressIndicator());
           }

           if (snapshot.hasError) {
             return Center(child: Text('حدث خطأ: ${snapshot.error}'));
           }

           if (!snapshot.hasData || !snapshot.data!.exists) {
             return Center(child: Text('لا توجد بيانات للمشرف'));
           }

           var adminData = snapshot.data!.data() as Map<String, dynamic>;

           return SingleChildScrollView(
             padding: EdgeInsets.all(16),
             child: Column(
               crossAxisAlignment: CrossAxisAlignment.stretch,
               children: [
                 Card(
                   child: Padding(
                     padding: EdgeInsets.all(16),
                     child: Column(
                       crossAxisAlignment: CrossAxisAlignment.start,
                       children: [
                         Text(
                           'معلومات المشرف',
                           style: TextStyle(
                             fontSize: 18,
                             fontWeight: FontWeight.bold,
                           ),
                         ),
                         SizedBox(height: 16),
                         _buildInfoRow('الاسم', adminData['name'] ?? 'غير متوفر'),
                         _buildInfoRow('البريد الإلكتروني', adminData['email'] ?? 'غير متوفر'),
                         _buildInfoRow('اسم المستخدم', adminData['username'] ?? 'غير متوفر'),
                       ],
                     ),
                   ),
                 ),
               ],
             ),
           );
         },
       ),
     ),
   );
 }

 Widget _buildInfoRow(String label, String value) {
   return Padding(
     padding: EdgeInsets.symmetric(vertical: 8.0),
     child: Row(
       crossAxisAlignment: CrossAxisAlignment.start,
       children: [
         Text(
           '$label:',
           style: TextStyle(fontWeight: FontWeight.bold),
         ),
         SizedBox(width: 8),
         Expanded(
           child: Text(
             value,
             style: TextStyle(fontSize: 16),
           ),
         ),
       ],
     ),
   );
 }
}

class EditAdminPage extends StatefulWidget {
 final String adminId;
 final Map<String, dynamic> adminData;

 EditAdminPage({required this.adminId, required this.adminData});

 @override
 _EditAdminPageState createState() => _EditAdminPageState();
}

class _EditAdminPageState extends State<EditAdminPage> {
 final _formKey = GlobalKey<FormState>();
 late TextEditingController _nameController;
 late TextEditingController _emailController;
 late TextEditingController _usernameController;
 late TextEditingController _passwordController;
 bool _isLoading = false;

 @override
 void initState() {
   super.initState();
   _nameController = TextEditingController(text: widget.adminData['name']);
   _emailController = TextEditingController(text: widget.adminData['email']);
   _usernameController = TextEditingController(text: widget.adminData['username']);
   _passwordController = TextEditingController(text: widget.adminData['password']);
 }

 Future<void> _updateAdmin() async {
   if (_formKey.currentState!.validate()) {
     setState(() => _isLoading = true);

     try {
       var usernameQuery = await FirebaseFirestore.instance
           .collection('users')
           .where('username', isEqualTo: _usernameController.text)
           .where(FieldPath.documentId, isNotEqualTo: widget.adminId)
           .get();

       if (usernameQuery.docs.isNotEmpty) {
         ScaffoldMessenger.of(context).showSnackBar(
           SnackBar(content: Text('اسم المستخدم موجود مسبقاً')),
         );
         return;
       }

       await FirebaseFirestore.instance
           .collection('users')
           .doc(widget.adminId)
           .update({
         'name': _nameController.text,
         'email': _emailController.text,
         'username': _usernameController.text,
         'password': _passwordController.text,
       });

       Navigator.pop(context);
       ScaffoldMessenger.of(context).showSnackBar(
         SnackBar(content: Text('تم تحديث البيانات بنجاح')),
       );
     } catch (e) {
       ScaffoldMessenger.of(context).showSnackBar(
         SnackBar(content: Text('حدث خطأ أثناء التحديث')),
       );
     } finally {
       if (mounted) setState(() => _isLoading = false);
     }
   }
 }

 @override
 Widget build(BuildContext context) {
   return Directionality(
     textDirection: TextDirection.rtl,
     child: Scaffold(
       appBar: AppBar(title: Text('تعديل بيانات المشرف')),
       body: _isLoading
           ? Center(child: CircularProgressIndicator())
           : Form(
               key: _formKey,
               child: ListView(
                 padding: EdgeInsets.all(16),
                 children: [
                   TextFormField(
                     controller: _nameController,
                     decoration: InputDecoration(
                       labelText: 'الاسم',
                       border: OutlineInputBorder(),
                     ),
                     validator: (v) => v!.isEmpty ? 'مطلوب' : null,
                   ),
                   SizedBox(height: 16),
                   TextFormField(
                     controller: _emailController,
                     decoration: InputDecoration(
                       labelText: 'البريد الإلكتروني',
                       border: OutlineInputBorder(),
                     ),
                     validator: (v) => v!.isEmpty ? 'مطلوب' : null,
                   ),
                   SizedBox(height: 16),
                   TextFormField(
                     controller: _usernameController,
                     decoration: InputDecoration(
                       labelText: 'اسم المستخدم',
                       border: OutlineInputBorder(),
                     ),
                     validator: (v) => v!.isEmpty ? 'مطلوب' : null,
                   ),
                   SizedBox(height: 16),
                   TextFormField(
                     controller: _passwordController,
                     decoration: InputDecoration(
                       labelText: 'كلمة المرور',
                       border: OutlineInputBorder(),
                     ),
                     obscureText: true,
                     validator: (v) => v!.isEmpty ? 'مطلوب' : null,
                   ),
                   SizedBox(height: 20),
                   ElevatedButton(
                     onPressed: _updateAdmin,
                     style: ElevatedButton.styleFrom(
                       padding: EdgeInsets.symmetric(vertical: 12),
                     ),
                     child: Text('تحديث البيانات'),
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
   _emailController.dispose();
   _usernameController.dispose();
   _passwordController.dispose();
   super.dispose();
 }
}