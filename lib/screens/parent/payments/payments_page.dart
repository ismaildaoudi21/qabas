import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:qabas/utils/app_colors.dart';
import 'package:intl/intl.dart' as intl;

class PaymentsPage extends StatelessWidget {
  final String parentId;

  const PaymentsPage({Key? key, required this.parentId}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(
          title: Text('المدفوعات'),
          backgroundColor: AppColors.orange1,
        ),
        body: StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance
              .collection('students')
              .where('parentId', isEqualTo: parentId)
              .snapshots(),
          builder: (context, studentsSnapshot) {
            if (studentsSnapshot.hasError) {
              return Center(child: Text('حدث خطأ في تحميل البيانات'));
            }

            if (studentsSnapshot.connectionState == ConnectionState.waiting) {
              return Center(child: CircularProgressIndicator());
            }

            if (!studentsSnapshot.hasData || studentsSnapshot.data!.docs.isEmpty) {
              return Center(child: Text('لا يوجد طلاب مسجلين'));
            }

            return ListView.builder(
              padding: EdgeInsets.all(16),
              itemCount: studentsSnapshot.data!.docs.length,
              itemBuilder: (context, index) {
                final studentDoc = studentsSnapshot.data!.docs[index];
                final studentData = studentDoc.data() as Map<String, dynamic>;
                return _buildStudentPaymentsCard(studentDoc.id, studentData);
              },
            );
          },
        ),
      ),
    );
  }

  Widget _buildStudentPaymentsCard(String studentId, Map<String, dynamic> studentData) {
    return Card(
      margin: EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.orange1.withOpacity(0.1),
              borderRadius: BorderRadius.vertical(top: Radius.circular(4)),
            ),
            child: Row(
              children: [
                CircleAvatar(
                  backgroundColor: AppColors.orange1.withOpacity(0.2),
                  child: Icon(Icons.person, color: AppColors.orange1),
                ),
                SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${studentData['firstName']} ${studentData['lastName']}',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        'الحلقة: ${studentData['halaqahName'] ?? 'غير محدد'}',
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collection('payments')
                .where('studentId', isEqualTo: studentId)
                .orderBy('dueDate', descending: true)
                .snapshots(),
            builder: (context, paymentsSnapshot) {
              if (paymentsSnapshot.hasError) {
                return Padding(
                  padding: EdgeInsets.all(16),
                  child: Text('حدث خطأ في تحميل المدفوعات'),
                );
              }

              if (paymentsSnapshot.connectionState == ConnectionState.waiting) {
                return Center(child: CircularProgressIndicator());
              }

              if (!paymentsSnapshot.hasData || paymentsSnapshot.data!.docs.isEmpty) {
                return Padding(
                  padding: EdgeInsets.all(16),
                  child: Text('لا يوجد مدفوعات'),
                );
              }

              return Column(
                children: paymentsSnapshot.data!.docs.map((paymentDoc) {
                  final payment = paymentDoc.data() as Map<String, dynamic>;
                  return _buildPaymentItem(payment);
                }).toList(),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentItem(Map<String, dynamic> payment) {
    final dueDate = (payment['dueDate'] as Timestamp).toDate();
    final isPaid = payment['status'] == 'paid';
    final amount = payment['amount'].toString();
    final paymentDate = payment['paymentDate'] != null
        ? (payment['paymentDate'] as Timestamp).toDate()
        : null;

    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(color: Colors.grey[200]!),
        ),
      ),
      child: Row(
        children: [
          Icon(
            isPaid ? Icons.check_circle : Icons.pending,
            color: isPaid ? AppColors.green2 : Colors.orange,
            size: 24,
          ),
          SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  payment['description'],
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  'تاريخ الاستحقاق: ${intl.DateFormat('dd/MM/yyyy').format(dueDate)}',
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 12,
                  ),
                ),
                if (isPaid && paymentDate != null)
                  Text(
                    'تم الدفع في: ${intl.DateFormat('dd/MM/yyyy').format(paymentDate)}',
                    style: TextStyle(
                      color: AppColors.green2,
                      fontSize: 12,
                    ),
                  ),
              ],
            ),
          ),
          Text(
            '$amount ريال',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: isPaid ? AppColors.green2 : Colors.grey[800],
            ),
          ),
        ],
      ),
    );
  }
} 