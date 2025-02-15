import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:qabas/utils/app_colors.dart';

class HalaqatPage extends StatelessWidget {
  final String teacherId;

  const HalaqatPage({Key? key, required this.teacherId}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(
          title: Text('حلقاتي'),
          centerTitle: true,
          backgroundColor: AppColors.blue1,
        ),
        body: StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance
              .collection('halaqahs')
              .where('teacherId', isEqualTo: teacherId)
              .snapshots(),
          builder: (context, halaqahSnapshot) {
            if (halaqahSnapshot.hasError) {
              return Center(child: Text('حدث خطأ في تحميل الحلقات'));
            }

            if (halaqahSnapshot.connectionState == ConnectionState.waiting) {
              return Center(child: CircularProgressIndicator());
            }

            final halaqat = halaqahSnapshot.data?.docs ?? [];

            if (halaqat.isEmpty) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.class_outlined, size: 64, color: Colors.grey),
                    SizedBox(height: 16),
                    Text(
                      'لا توجد حلقات مسندة إليك',
                      style: TextStyle(fontSize: 18, color: Colors.grey[600]),
                    ),
                  ],
                ),
              );
            }

            return ListView.builder(
              padding: EdgeInsets.all(16),
              itemCount: halaqat.length,
              itemBuilder: (context, index) {
                final halaqahDoc = halaqat[index];
                final halaqah = halaqahDoc.data() as Map<String, dynamic>;

                return Card(
                  margin: EdgeInsets.only(bottom: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 2,
                  child: Theme(
                    data: Theme.of(context).copyWith(
                      dividerColor: Colors.transparent,
                    ),
                    child: ExpansionTile(
                      leading: CircleAvatar(
                        backgroundColor: AppColors.blue1.withOpacity(0.2),
                        child: Icon(Icons.class_, color: AppColors.blue1),
                      ),
                      title: Text(
                        halaqah['name'] ?? '',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                        ),
                      ),
                      children: [
                        Padding(
                          padding: EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _buildInfoRow('الجدول:', halaqah['schedule'] ?? ''),
                              SizedBox(height: 8),
                              _buildInfoRow('الموقع:', halaqah['location'] ?? ''),
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

  Widget _buildInfoRow(String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: AppColors.blue1,
          ),
        ),
        SizedBox(width: 8),
        Expanded(
          child: Text(
            value,
            style: TextStyle(fontSize: 16),
          ),
        ),
      ],
    );
  }
} 