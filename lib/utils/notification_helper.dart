import 'package:cloud_firestore/cloud_firestore.dart';

class NotificationHelper {
  static Future<void> createNotification({
    required String studentId,
    required String title,
    required String message,
    required String type,
  }) async {
    try {
      await FirebaseFirestore.instance.collection('notifications').add({
        'studentId': studentId,
        'title': title,
        'message': message,
        'type': type,
        'timestamp': FieldValue.serverTimestamp(),
        'isRead': false,
      });
    } catch (e) {
      print('Error creating notification: $e');
    }
  }

  static Future<void> createWirdAssignedNotification({
    required String studentId,
    required String studentName,
    required String wirdType,
    required String surahName,
  }) async {
    await createNotification(
      studentId: studentId,
      title: 'ورد جديد',
      message: 'تم تعيين $wirdType جديد في سورة $surahName',
      type: 'wird',
    );
  }

  static Future<void> createWirdAssessmentNotification({
    required String studentId,
    required String studentName,
    required String wirdType,
    required String surahName,
    required String grade,
  }) async {
    String gradeMessage = grade == 'يكرر' 
        ? 'يجب إعادة $wirdType في سورة $surahName'
        : 'تم تقييم $wirdType في سورة $surahName بتقدير $grade';

    await createNotification(
      studentId: studentId,
      title: 'تقييم الورد',
      message: gradeMessage,
      type: 'assessment',
    );
  }
} 