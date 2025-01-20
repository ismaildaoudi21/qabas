import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'add_admin_page.dart';
import 'admin_details_page.dart';

class AdminListPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(title: Text('المشرفون')),
        floatingActionButton: FloatingActionButton(
          onPressed: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => AddAdminPage()),
          ),
          child: Icon(Icons.add),
          tooltip: 'إضافة مشرف جديد',
        ),
        body: StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance
              .collection('users')
              .where('role', isEqualTo: 'admin')
              .snapshots(),
          builder: (context, snapshot) {
            if (snapshot.hasError) return Center(child: Text('حدث خطأ'));
            if (snapshot.connectionState == ConnectionState.waiting) 
              return Center(child: CircularProgressIndicator());

            final admins = snapshot.data?.docs ?? [];
            
            if (admins.isEmpty) {
              return Center(child: Text('لا يوجد مشرفين'));
            }

            return ListView.builder(
              itemCount: admins.length,
              padding: EdgeInsets.all(8),
              itemBuilder: (context, index) {
                final admin = admins[index].data() as Map<String, dynamic>;
                return Card(
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: Colors.blue,
                      child: Icon(Icons.person, color: Colors.white),
                    ),
                    title: Text(admin['name'] ?? ''),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(admin['email'] ?? ''),
                        Text(admin['username'] ?? ''),
                      ],
                    ),
                    isThreeLine: true,
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => AdminDetailsPage(
                            adminId: admins[index].id,
                          ),
                        ),
                      );
                    },
                    trailing: PopupMenuButton(
                      onSelected: (value) async {
                        if (value == 'delete') {
                          await FirebaseFirestore.instance
                              .collection('users')
                              .doc(admins[index].id)
                              .delete();
                        }
                      },
                      itemBuilder: (context) => [
                        PopupMenuItem(
                          value: 'delete',
                          child: Row(
                            children: [
                              Icon(Icons.delete, color: Colors.red),
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