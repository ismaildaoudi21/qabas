import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'add_halaqah_page.dart';
import 'halaqah_details_page.dart';

class HalaqahListPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(
          title: Text('قائمة الحلقات'),
        ),
        floatingActionButton: FloatingActionButton(
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => AddHalaqahPage()),
            );
          },
          child: Icon(Icons.add),
        ),
        body: StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance.collection('halaqahs').snapshots(),
          builder: (context, snapshot) {
            if (snapshot.hasError) {
              return Center(child: Text('حدث خطأ: ${snapshot.error}'));
            }

            if (snapshot.connectionState == ConnectionState.waiting) {
              return Center(child: CircularProgressIndicator());
            }

            if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
              return Center(child: Text('لا توجد حلقات'));
            }

            return ListView.builder(
              itemCount: snapshot.data!.docs.length,
              itemBuilder: (context, index) {
                final halaqah = snapshot.data!.docs[index];
                final halaqahData = halaqah.data() as Map<String, dynamic>;

                return Card(
                  margin: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  child: ListTile(
                    title: Text(halaqahData['name'] ?? ''),
                    subtitle: Text(halaqahData['teacherName'] ?? ''),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => HalaqahDetailsPage(
                            halaqahId: halaqah.id,
                            halaqahData: halaqahData,
                          ),
                        ),
                      );
                    },
                    trailing: PopupMenuButton(
                      onSelected: (value) async {
                        if (value == 'edit') {
                          // Navigate to edit page
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => AddHalaqahPage(
                                halaqahId: halaqah.id,
                                halaqahData: halaqahData,
                              ),
                            ),
                          );
                        } else if (value == 'delete') {
                          // Show delete confirmation
                          showDialog(
                            context: context,
                            builder: (context) => AlertDialog(
                              title: Text('تأكيد الحذف'),
                              content: Text('هل أنت متأكد من حذف هذه الحلقة؟'),
                              actions: [
                                TextButton(
                                  child: Text('إلغاء'),
                                  onPressed: () => Navigator.pop(context),
                                ),
                                TextButton(
                                  child: Text('حذف'),
                                  onPressed: () async {
                                    await FirebaseFirestore.instance
                                        .collection('halaqahs')
                                        .doc(halaqah.id)
                                        .delete();
                                    Navigator.pop(context);
                                  },
                                ),
                              ],
                            ),
                          );
                        }
                      },
                      itemBuilder: (context) => [
                        PopupMenuItem(
                          value: 'edit',
                          child: Row(
                            children: [
                              Icon(Icons.edit),
                              SizedBox(width: 8),
                              Text('تعديل'),
                            ],
                          ),
                        ),
                        PopupMenuItem(
                          value: 'delete',
                          child: Row(
                            children: [
                              Icon(Icons.delete),
                              SizedBox(width: 8),
                              Text('حذف'),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }
}