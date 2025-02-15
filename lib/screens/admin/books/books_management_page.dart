import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:qabas/utils/app_colors.dart';
import 'package:url_launcher/url_launcher_string.dart';

class BooksManagementPage extends StatefulWidget {
  @override
  _BooksManagementPageState createState() => _BooksManagementPageState();
}

class _BooksManagementPageState extends State<BooksManagementPage> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _authorController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _urlController = TextEditingController();
  bool _isLoading = false;
  String? _editingBookId;

  @override
  void dispose() {
    _titleController.dispose();
    _authorController.dispose();
    _descriptionController.dispose();
    _urlController.dispose();
    super.dispose();
  }

  void _clearForm() {
    _formKey.currentState?.reset();
    _titleController.clear();
    _authorController.clear();
    _descriptionController.clear();
    _urlController.clear();
    setState(() {
      _editingBookId = null;
    });
  }

  void _editBook(Map<String, dynamic> book, String bookId) {
    setState(() {
      _editingBookId = bookId;
      _titleController.text = book['title'] ?? '';
      _authorController.text = book['author'] ?? '';
      _descriptionController.text = book['description'] ?? '';
      _urlController.text = book['pdfUrl'] ?? '';
    });
  }

  Future<void> _saveBook() async {
    if (!_formKey.currentState!.validate()) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('الرجاء تعبئة جميع الحقول المطلوبة')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final data = {
        'title': _titleController.text,
        'author': _authorController.text,
        'description': _descriptionController.text,
        'pdfUrl': _urlController.text,
        'uploadDate': FieldValue.serverTimestamp(),
      };

      if (_editingBookId != null) {
        await FirebaseFirestore.instance
            .collection('books')
            .doc(_editingBookId)
            .update(data);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('تم تحديث الكتاب بنجاح')),
        );
      } else {
        await FirebaseFirestore.instance.collection('books').add(data);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('تم إضافة الكتاب بنجاح')),
        );
      }

      _clearForm();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('حدث خطأ أثناء حفظ الكتاب')),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _deleteBook(DocumentSnapshot book, BuildContext parentContext) async {
    final scaffoldMessenger = ScaffoldMessenger.of(parentContext);
    
    try {
      await book.reference.delete();
      if (!mounted) return;
      scaffoldMessenger.showSnackBar(
        SnackBar(content: Text('تم حذف الكتاب بنجاح')),
      );
    } catch (e) {
      if (!mounted) return;
      scaffoldMessenger.showSnackBar(
        SnackBar(content: Text('حدث خطأ أثناء حذف الكتاب')),
      );
    }
  }

  Future<void> _launchURL(String url) async {
    try {
      if (await canLaunchUrlString(url)) {
        await launchUrlString(url);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('لا يمكن فتح الرابط')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('حدث خطأ أثناء فتح الرابط')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(
          title: Text('إدارة الكتب'),
          backgroundColor: AppColors.orange1,
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
                      _editingBookId != null ? 'تعديل كتاب' : 'إضافة كتاب جديد',
                      style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                    ),
                    SizedBox(height: 16),
                    TextFormField(
                      controller: _titleController,
                      decoration: InputDecoration(
                        labelText: 'عنوان الكتاب',
                        border: OutlineInputBorder(),
                      ),
                      validator: (value) =>
                          value?.isEmpty ?? true ? 'هذا الحقل مطلوب' : null,
                    ),
                    SizedBox(height: 16),
                    TextFormField(
                      controller: _authorController,
                      decoration: InputDecoration(
                        labelText: 'المؤلف',
                        border: OutlineInputBorder(),
                      ),
                      validator: (value) =>
                          value?.isEmpty ?? true ? 'هذا الحقل مطلوب' : null,
                    ),
                    SizedBox(height: 16),
                    TextFormField(
                      controller: _descriptionController,
                      decoration: InputDecoration(
                        labelText: 'وصف الكتاب',
                        border: OutlineInputBorder(),
                      ),
                      maxLines: 3,
                    ),
                    SizedBox(height: 16),
                    TextFormField(
                      controller: _urlController,
                      decoration: InputDecoration(
                        labelText: 'رابط الكتاب',
                        border: OutlineInputBorder(),
                        hintText: 'https://example.com/book.pdf',
                      ),
                      validator: (value) {
                        if (value?.isEmpty ?? true) {
                          return 'هذا الحقل مطلوب';
                        }
                        if (!Uri.parse(value!).isAbsolute) {
                          return 'الرجاء إدخال رابط صحيح';
                        }
                        return null;
                      },
                    ),
                    SizedBox(height: 24),
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton(
                            onPressed: _isLoading ? null : _saveBook,
                            child: _isLoading
                                ? CircularProgressIndicator(color: Colors.white)
                                : Text(_editingBookId != null ? 'حفظ التغييرات' : 'إضافة كتاب'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.orange1,
                              minimumSize: Size(double.infinity, 48),
                            ),
                          ),
                        ),
                        if (_editingBookId != null) ...[
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
                'قائمة الكتب',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 16),
              StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance
                    .collection('books')
                    .orderBy('uploadDate', descending: true)
                    .snapshots(),
                builder: (context, snapshot) {
                  if (snapshot.hasError) {
                    return Text('حدث خطأ في تحميل الكتب');
                  }

                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return Center(child: CircularProgressIndicator());
                  }

                  final books = snapshot.data?.docs ?? [];

                  if (books.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.library_books, size: 64, color: Colors.grey),
                          SizedBox(height: 16),
                          Text(
                            'لا توجد كتب مضافة',
                            style: TextStyle(fontSize: 18, color: Colors.grey[600]),
                          ),
                        ],
                      ),
                    );
                  }

                  return ListView.builder(
                    shrinkWrap: true,
                    physics: NeverScrollableScrollPhysics(),
                    itemCount: books.length,
                    itemBuilder: (context, index) {
                      final book = books[index].data() as Map<String, dynamic>;
                      return Card(
                        margin: EdgeInsets.only(bottom: 8),
                        child: ListTile(
                          leading: CircleAvatar(
                            backgroundColor: AppColors.orange1.withOpacity(0.2),
                            child: Icon(Icons.book, color: AppColors.orange1),
                          ),
                          title: Text(book['title'] ?? ''),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(book['author'] ?? ''),
                              if (book['description']?.isNotEmpty ?? false)
                                Text(
                                  book['description'],
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(color: Colors.grey[600]),
                                ),
                            ],
                          ),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                icon: Icon(Icons.open_in_new, color: AppColors.blue1),
                                onPressed: () => _launchURL(book['pdfUrl']),
                              ),
                              IconButton(
                                icon: Icon(Icons.edit, color: AppColors.orange1),
                                onPressed: () => _editBook(book, books[index].id),
                              ),
                              IconButton(
                                icon: Icon(Icons.delete, color: Colors.red),
                                onPressed: () {
                                  final parentContext = context;
                                  showDialog(
                                    context: context,
                                    builder: (dialogContext) => AlertDialog(
                                      title: Text('تأكيد الحذف'),
                                      content: Text('هل أنت متأكد من حذف هذا الكتاب؟'),
                                      actions: [
                                        TextButton(
                                          onPressed: () => Navigator.pop(dialogContext),
                                          child: Text('إلغاء'),
                                        ),
                                        TextButton(
                                          onPressed: () {
                                            Navigator.pop(dialogContext);
                                            _deleteBook(books[index], parentContext);
                                          },
                                          child: Text('حذف', style: TextStyle(color: Colors.red)),
                                        ),
                                      ],
                                    ),
                                  );
                                },
                              ),
                            ],
                          ),
                          isThreeLine: book['description']?.isNotEmpty ?? false,
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