import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:toeic_tracker_admin/models/user_model.dart';

class UserAdminService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instanceFor(app: Firebase.app('AdminApp'));

  // Lấy danh sách tất cả người dùng (Lọc bỏ Admin bằng code Dart)
  Stream<List<UserModel>> getAllUsers() {
    final currentUserUid = FirebaseAuth.instanceFor(app: Firebase.app('AdminApp')).currentUser?.uid;

    return _firestore.collection('users').snapshots().map((snapshot) {
      return snapshot.docs.map((doc) {
        final data = doc.data();
        // CỰC KỲ QUAN TRỌNG: Ghi đè ID từ Document ID thực tế của Firestore
        data['id'] = doc.id; 
        return UserModel.fromJson(data);
      }).where((user) {
        // 1. Lọc bỏ nếu UID trùng với Admin đang đăng nhập
        if (currentUserUid != null && user.authUid == currentUserUid) return false;
        
        // 2. Lọc bỏ Admin
        return !user.isAdmin && user.id != 'admin';
      }).toList();
    });
  }

  // Khóa/Mở khóa tài khoản
  Future<void> toggleUserStatus(String userId, bool isDisabled) async {
    // Chúng ta cập nhật field 'isDisabled' trong Firestore document có ID là userId
    await _firestore.collection('users').doc(userId).update({
      'isDisabled': isDisabled,
    });
  }
}
