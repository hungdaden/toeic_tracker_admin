import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import '../models/exam_model.dart';

class ExamService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instanceFor(app: Firebase.app('AdminApp'));

  // Lấy danh sách đề thi
  Stream<List<ToeicExam>> getExams() {
    return _firestore.collection('exams').snapshots().map((snapshot) {
      return snapshot.docs.map((doc) {
        final data = doc.data();
        data['id'] = doc.id;
        return ToeicExam.fromJson(data);
      }).toList();
    });
  }

  // Thêm đề thi mới
  Future<void> addExam(ToeicExam exam) async {
    await _firestore.collection('exams').doc(exam.id).set(exam.toJson());
  }

  // Xóa đề thi
  Future<void> deleteExam(String id) async {
    await _firestore.collection('exams').doc(id).delete();
  }

  // Cập nhật đề thi
  Future<void> updateExam(ToeicExam exam) async {
    await _firestore.collection('exams').doc(exam.id).update(exam.toJson());
  }
}
