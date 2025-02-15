// lib/screens/teacher/attendance/attendance_report_page.dart

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

class AttendanceReportPage extends StatefulWidget {
  final String teacherId;
  final String halaqahId;
  final String halaqahName;

  const AttendanceReportPage({
    Key? key,
    required this.teacherId,
    required this.halaqahId,
    required this.halaqahName,
  }) : super(key: key);

  @override
  _AttendanceReportPageState createState() => _AttendanceReportPageState();
}

class _AttendanceReportPageState extends State<AttendanceReportPage> {
  DateTime? startDate;
  DateTime? endDate;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
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
                value: widget.halaqahId,
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
                  // Handle halaqah selection
                },
              );
            },
          ),
          SizedBox(height: 16),

          // Date range selectors
          Row(
            children: [
              Expanded(
                child: Card(
                  child: ListTile(
                    leading: Icon(Icons.calendar_today),
                    title: Text('من تاريخ'),
                    subtitle: Text(startDate == null
                        ? 'اختر التاريخ'
                        : DateFormat('yyyy-MM-dd').format(startDate!)),
                    onTap: () => _selectDate(context, true),
                  ),
                ),
              ),
              SizedBox(width: 8),
              Expanded(
                child: Card(
                  child: ListTile(
                    leading: Icon(Icons.calendar_today),
                    title: Text('إلى تاريخ'),
                    subtitle: Text(endDate == null
                        ? 'اختر التاريخ'
                        : DateFormat('yyyy-MM-dd').format(endDate!)),
                    onTap: () => _selectDate(context, false),
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 20),

          // Attendance report
          if (widget.halaqahId != null && startDate != null && endDate != null)
            StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('attendance')
                  .where('halaqahId', isEqualTo: widget.halaqahId)
                  .where('date', isGreaterThanOrEqualTo: Timestamp.fromDate(startDate!))
                  .where('date', isLessThanOrEqualTo: Timestamp.fromDate(endDate!))
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return Text('حدث خطأ');
                }

                if (snapshot.connectionState == ConnectionState.waiting) {
                  return Center(child: CircularProgressIndicator());
                }

                final attendanceRecords = snapshot.data?.docs ?? [];

                if (attendanceRecords.isEmpty) {
                  return Center(
                    child: Text('لا يوجد سجلات حضور في هذه الفترة'),
                  );
                }

                // Process attendance data
                Map<String, Map<String, bool>> attendanceData = {};
                Set<DateTime> dates = {};

                for (var record in attendanceRecords) {
                  final data = record.data() as Map<String, dynamic>;
                  final studentId = data['studentId'] as String;
                  final date = (data['date'] as Timestamp).toDate();
                  final present = data['present'] as bool;

                  dates.add(DateTime(date.year, date.month, date.day));

                  if (!attendanceData.containsKey(studentId)) {
                    attendanceData[studentId] = {};
                  }
                  attendanceData[studentId]![DateFormat('yyyy-MM-dd').format(date)] = present;
                }

                return FutureBuilder<QuerySnapshot>(
                  future: FirebaseFirestore.instance
                      .collection('users')
                      .where('halaqahId', isEqualTo: widget.halaqahId)
                      .where('role', isEqualTo: 'student')
                      .get(),
                  builder: (context, studentsSnapshot) {
                    if (!studentsSnapshot.hasData) {
                      return CircularProgressIndicator();
                    }

                    final students = studentsSnapshot.data?.docs ?? [];
                    final sortedDates = dates.toList()..sort();

                    return SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: DataTable(
                        columns: [
                          DataColumn(label: Text('الطالب')),
                          ...sortedDates.map((date) => DataColumn(
                                label: Text(DateFormat('MM/dd').format(date)),
                              )),
                          DataColumn(label: Text('النسبة')),
                        ],
                        rows: students.map((student) {
                          final studentData = student.data() as Map<String, dynamic>;
                          final studentId = student.id;
                          final studentAttendance = attendanceData[studentId] ?? {};
                          
                          int presentDays = 0;
                          List<DataCell> dateCells = [];

                          for (var date in sortedDates) {
                            final dateStr = DateFormat('yyyy-MM-dd').format(date);
                            final present = studentAttendance[dateStr] ?? false;
                            if (present) presentDays++;

                            dateCells.add(DataCell(
                              Icon(
                                present ? Icons.check_circle : Icons.cancel,
                                color: present ? Colors.green : Colors.red,
                              ),
                            ));
                          }

                          final attendanceRate = sortedDates.isEmpty
                              ? 0.0
                              : (presentDays / sortedDates.length) * 100;

                          return DataRow(
                            cells: [
                              DataCell(Text('${studentData['firstName']} ${studentData['lastName']}')),
                              ...dateCells,
                              DataCell(Text('${attendanceRate.toStringAsFixed(1)}%')),
                            ],
                          );
                        }).toList(),
                      ),
                    );
                  },
                );
              },
            ),
        ],
      ),
    );
  }

  Future<void> _selectDate(BuildContext context, bool isStartDate) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: isStartDate ? (startDate ?? DateTime.now()) : (endDate ?? DateTime.now()),
      firstDate: isStartDate ? DateTime(2000) : (startDate ?? DateTime(2000)),
      lastDate: DateTime.now(),
    );
    
    if (picked != null) {
      // Handle date selection
    }
  }
}