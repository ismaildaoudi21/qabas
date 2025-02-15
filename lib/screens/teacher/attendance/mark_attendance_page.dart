import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

class MarkAttendancePage extends StatefulWidget {
  final String teacherId;

  const MarkAttendancePage({Key? key, required this.teacherId}) : super(key: key);

  @override
  _MarkAttendancePageState createState() => _MarkAttendancePageState();
}

class _MarkAttendancePageState extends State<MarkAttendancePage> {
  String? selectedHalaqahId;
  DateTime selectedDate = DateTime.now();
  Map<String, bool> attendanceStatus = {};
  bool isLoading = false;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Date selector
          Card(
            child: ListTile(
              leading: Icon(Icons.calendar_today),
              title: Text('تاريخ الحضور'),
              subtitle: Text(DateFormat('yyyy-MM-dd').format(selectedDate)),
              onTap: () => _selectDate(context),
            ),
          ),
          SizedBox(height: 16),

          // Halaqah selector
          StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collection('halaqahs')
                .where('teacherId', isEqualTo: widget.teacherId)
                .snapshots(),
            builder: (context, snapshot) {
              if (snapshot.hasError) {
                return Text('حدث خطأ');
              }

              if (snapshot.connectionState == ConnectionState.waiting) {
                return CircularProgressIndicator();
              }

              final halaqahs = snapshot.data?.docs ?? [];

              return DropdownButtonFormField<String>(
                decoration: InputDecoration(
                  labelText: 'اختر الحلقة',
                  border: OutlineInputBorder(),
                ),
                value: selectedHalaqahId,
                items: [
                  DropdownMenuItem<String>(
                    value: null,
                    child: Text('اختر الحلقة'),
                  ),
                  ...halaqahs.map((halaqah) {
                    final data = halaqah.data() as Map<String, dynamic>;
                    return DropdownMenuItem<String>(
                      value: halaqah.id,
                      child: Text(data['name'] ?? ''),
                    );
                  }).toList(),
                ],
                onChanged: (value) {
                  setState(() {
                    selectedHalaqahId = value;
                    attendanceStatus.clear();
                  });
                },
              );
            },
          ),
          SizedBox(height: 20),

          // Students list
          if (selectedHalaqahId != null)
            StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('users')
                  .where('halaqahId', isEqualTo: selectedHalaqahId)
                  .where('role', isEqualTo: 'student')
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return Text('حدث خطأ');
                }

                if (snapshot.connectionState == ConnectionState.waiting) {
                  return Center(child: CircularProgressIndicator());
                }

                final students = snapshot.data?.docs ?? [];

                if (students.isEmpty) {
                  return Center(
                    child: Text('لا يوجد طلاب في هذه الحلقة'),
                  );
                }

                return Column(
                  children: [
                    ListView.builder(
                      shrinkWrap: true,
                      physics: NeverScrollableScrollPhysics(),
                      itemCount: students.length,
                      itemBuilder: (context, index) {
                        final student = students[index];
                        final data = student.data() as Map<String, dynamic>;
                        final studentId = student.id;

                        if (!attendanceStatus.containsKey(studentId)) {
                          attendanceStatus[studentId] = false;
                        }

                        return Card(
                          child: CheckboxListTile(
                            title: Text('${data['firstName']} ${data['lastName']}'),
                            value: attendanceStatus[studentId],
                            onChanged: (bool? value) {
                              setState(() {
                                attendanceStatus[studentId] = value ?? false;
                              });
                            },
                          ),
                        );
                      },
                    ),
                    SizedBox(height: 20),
                    ElevatedButton(
                      onPressed: isLoading ? null : _saveAttendance,
                      child: isLoading
                          ? CircularProgressIndicator(color: Colors.white)
                          : Text('حفظ الحضور'),
                      style: ElevatedButton.styleFrom(
                        padding: EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                        backgroundColor: const Color.fromARGB(255, 153, 239, 166),
                      ),
                    ),
                  ],
                );
              },
            ),
        ],
      ),
    );
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: selectedDate,
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
    );
    if (picked != null && picked != selectedDate) {
      setState(() {
        selectedDate = picked;
      });
    }
  }

  Future<void> _saveAttendance() async {
    setState(() {
      isLoading = true;
    });

    try {
      final batch = FirebaseFirestore.instance.batch();
      final dateStr = DateFormat('yyyy-MM-dd').format(selectedDate);

      for (var entry in attendanceStatus.entries) {
        final docRef = FirebaseFirestore.instance
            .collection('attendance')
            .doc('${selectedHalaqahId}_${entry.key}_$dateStr');

        batch.set(docRef, {
          'halaqahId': selectedHalaqahId,
          'studentId': entry.key,
          'date': Timestamp.fromDate(selectedDate),
          'present': entry.value,
          'teacherId': widget.teacherId,
        });
      }

      await batch.commit();

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('تم حفظ الحضور بنجاح')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('حدث خطأ أثناء حفظ الحضور')),
      );
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }
}