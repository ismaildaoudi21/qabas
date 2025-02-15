// lib/screens/teacher/assessments/add_assessment_page.dart

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:qabas/utils/app_colors.dart';

class AddAssessmentPage extends StatefulWidget {
  final String teacherId;

  const AddAssessmentPage({Key? key, required this.teacherId}) : super(key: key);

  @override
  _AddAssessmentPageState createState() => _AddAssessmentPageState();
}

class _AddAssessmentPageState extends State<AddAssessmentPage> {
  final _formKey = GlobalKey<FormState>();
  String? selectedStudentId;
  String? selectedStudentName;
  String? selectedWirdId;
  String? selectedGrade;
  final _notesController = TextEditingController();
  bool _isLoading = false;

  final List<String> gradeOptions = ['ممتاز', 'جيد جداً', 'جيد', 'يكرر'];

  Color _getGradeColor(String grade) {
    switch (grade) {
      case 'ممتاز':
        return AppColors.blue1;
      case 'جيد جداً':
        return AppColors.orange1;
      case 'جيد':
        return AppColors.blue3;
      case 'يكرر':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(
          title: Text('تقييم الطالب'),
          centerTitle: true,
          backgroundColor: AppColors.orange1,
          elevation: 0,
        ),
        body: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                AppColors.orange1.withOpacity(0.1),
                Colors.white,
              ],
            ),
          ),
          child: Form(
            key: _formKey,
            child: ListView(
              padding: EdgeInsets.all(16),
              children: [
                Card(
                  elevation: 2,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Padding(
                    padding: EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'اختيار الطالب والورد',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: AppColors.blue1,
                          ),
                        ),
                        SizedBox(height: 16),
                        _buildStudentDropdown(),
                        SizedBox(height: 16),
                        if (selectedStudentId != null) _buildWirdDropdown(),
                      ],
                    ),
                  ),
                ),
                SizedBox(height: 16),
                if (selectedWirdId != null)
                  Card(
                    elevation: 2,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Padding(
                      padding: EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'التقييم',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: AppColors.blue1,
                            ),
                          ),
                          SizedBox(height: 16),
                          _buildGradeSelection(),
                          SizedBox(height: 16),
                          TextFormField(
                            controller: _notesController,
                            decoration: InputDecoration(
                              labelText: 'ملاحظات',
                              alignLabelWithHint: true,
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                              prefixIcon: Icon(Icons.note_add, color: AppColors.blue1),
                              filled: true,
                              fillColor: Colors.grey[50],
                            ),
                            maxLines: 3,
                          ),
                        ],
                      ),
                    ),
                  ),
                SizedBox(height: 24),
                if (selectedWirdId != null)
                  ElevatedButton(
                    onPressed: _isLoading ? null : _saveAssessment,
                    child: _isLoading
                        ? CircularProgressIndicator(color: Colors.white)
                        : Text(
                            'حفظ التقييم',
                            style: TextStyle(fontSize: 16),
                          ),
                    style: ElevatedButton.styleFrom(
                      padding: EdgeInsets.symmetric(vertical: 16),
                      backgroundColor: AppColors.orange1,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildGradeSelection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'التقدير',
          style: TextStyle(
            fontSize: 16,
            color: Colors.grey[700],
          ),
        ),
        SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: gradeOptions.map((grade) {
            final isSelected = selectedGrade == grade;
            final color = _getGradeColor(grade);
            
            return InkWell(
              onTap: () {
                setState(() {
                  selectedGrade = grade;
                });
              },
              child: Container(
                padding: EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                decoration: BoxDecoration(
                  color: isSelected ? color : color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: color,
                    width: isSelected ? 2 : 1,
                  ),
                ),
                child: Text(
                  grade,
                  style: TextStyle(
                    color: isSelected ? Colors.white : color,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildStudentDropdown() {
    return StreamBuilder<QuerySnapshot>(
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
        final halaqahIds = halaqahs.map((h) => h.id).toList();

        return StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance
              .collection('users')
              .where('halaqahId', whereIn: halaqahIds)
              .where('role', isEqualTo: 'student')
              .snapshots(),
          builder: (context, studentsSnapshot) {
            if (studentsSnapshot.hasError) {
              return Text('حدث خطأ');
            }

            if (studentsSnapshot.connectionState == ConnectionState.waiting) {
              return CircularProgressIndicator();
            }

            final students = studentsSnapshot.data?.docs ?? [];

            if (selectedStudentId != null && 
                !students.any((student) => student.id == selectedStudentId)) {
              selectedStudentId = null;
              selectedStudentName = null;
            }

            return DropdownButtonFormField<String>(
              decoration: InputDecoration(
                labelText: 'اختر الطالب',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                filled: true,
                fillColor: Colors.grey[50],
                prefixIcon: Icon(Icons.person, color: AppColors.blue1),
              ),
              value: selectedStudentId,
              items: students.map((student) {
                final data = student.data() as Map<String, dynamic>;
                final name = '${data['firstName']} ${data['lastName']}';
                return DropdownMenuItem<String>(
                  value: student.id,
                  child: Text(name),
                );
              }).toList(),
              onChanged: (value) {
                setState(() {
                  selectedStudentId = value;
                  selectedWirdId = null;
                  if (value != null) {
                    final student = students.firstWhere((s) => s.id == value);
                    final data = student.data() as Map<String, dynamic>;
                    selectedStudentName = '${data['firstName']} ${data['lastName']}';
                  } else {
                    selectedStudentName = null;
                  }
                });
              },
              validator: (value) => value == null ? 'الرجاء اختيار الطالب' : null,
            );
          },
        );
      },
    );
  }

  Widget _buildWirdDropdown() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('wird')
          .where('studentId', isEqualTo: selectedStudentId)
          .where('status', whereIn: ['assigned', 'in_progress'])
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Text('حدث خطأ');
        }

        if (snapshot.connectionState == ConnectionState.waiting) {
          return CircularProgressIndicator();
        }

        final wirds = snapshot.data?.docs ?? [];
        
        if (selectedWirdId != null && 
            !wirds.any((wird) => wird.id == selectedWirdId)) {
          selectedWirdId = null;
        }

        if (wirds.isEmpty) {
          return Padding(
            padding: EdgeInsets.only(top: 8),
            child: Text(
              'لا يوجد ورد حالي للطالب',
              style: TextStyle(color: Colors.red),
            ),
          );
        }

        return DropdownButtonFormField<String>(
          decoration: InputDecoration(
            labelText: 'اختر الورد',
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
            ),
            filled: true,
            fillColor: Colors.grey[50],
            prefixIcon: Icon(Icons.book, color: AppColors.blue1),
          ),
          value: selectedWirdId,
          items: wirds.map((wird) {
            final data = wird.data() as Map<String, dynamic>;
            return DropdownMenuItem<String>(
              value: wird.id,
              child: Text('سورة ${data['surahName']} - من آية ${data['startAyah']} إلى ${data['endAyah']}'),
            );
          }).toList(),
          onChanged: (value) {
            setState(() {
              selectedWirdId = value;
            });
          },
          validator: (value) => value == null ? 'الرجاء اختيار الورد' : null,
        );
      },
    );
  }

  Future<void> _saveAssessment() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    if (selectedGrade == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('الرجاء اختيار التقدير')),
      );
      return;
    }
    
    setState(() {
      _isLoading = true;
    });

    try {
      await FirebaseFirestore.instance.collection('wird_assessments').add({
        'studentId': selectedStudentId,
        'studentName': selectedStudentName,
        'wirdId': selectedWirdId,
        'teacherId': widget.teacherId,
        'date': FieldValue.serverTimestamp(),
        'grade': selectedGrade,
        'notes': _notesController.text,
      });

      if (selectedGrade != 'يكرر') {
        await FirebaseFirestore.instance
            .collection('wird')
            .doc(selectedWirdId)
            .update({
          'status': 'completed',
          'completionDate': FieldValue.serverTimestamp(),
        });
      }

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('تم حفظ التقييم بنجاح')),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('حدث خطأ أثناء حفظ التقييم'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }
}