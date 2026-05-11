import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AdminAuthService {
  final FirebaseAuth _auth = FirebaseAuth.instanceFor(app: Firebase.app('AdminApp'));
  final FirebaseFirestore _firestore = FirebaseFirestore.instanceFor(app: Firebase.app('AdminApp'));

  // Đăng nhập và kiểm tra quyền Admin
  Future<String?> signInAdmin(String identifier, String password) async {
    try {
      String finalEmail = identifier;
      
      // Nếu là username (không có @), tự động thêm domain ảo
      if (!identifier.contains('@')) {
        finalEmail = '$identifier@toeic.app';
      }

      // 1. Đăng nhập bằng Firebase Auth
      UserCredential result = await _auth.signInWithEmailAndPassword(
        email: finalEmail,
        password: password,
      );

      User? user = result.user;
      if (user == null) return "Không thể xác thực người dùng.";

      // 2. Kiểm tra quyền Admin bằng Query (Linh hoạt hơn)
      final username = identifier.contains('@') ? identifier.split('@')[0] : identifier;
      
      print("Đang truy vấn quyền Admin cho: $username hoặc UID: ${user.uid}");

      // Tìm kiếm trong collection 'users' xem có ai khớp UID hoặc Username không
      final querySnapshot = await _firestore
          .collection('users')
          .where(Filter.or(
            Filter('authUid', isEqualTo: user.uid),
            Filter('id', isEqualTo: username),
          ))
          .get();

      if (querySnapshot.docs.isEmpty) {
        await _auth.signOut();
        return "Lỗi: Không tìm thấy hồ sơ có ID '$username' hoặc UID '${user.uid}' trong Firestore.";
      }

      final userData = querySnapshot.docs.first.data();
      if (userData['isAdmin'] != true) {
        await _auth.signOut();
        return "Tài khoản '${userData['name'] ?? username}' không có quyền Quản trị (isAdmin: true).";
      }

      print("Đăng nhập Admin thành công!");
      return null; // Thành công
    } on FirebaseAuthException catch (e) {
      // Chuyển mã lỗi Firebase sang tiếng Việt thân thiện
      switch (e.code) {
        case 'invalid-credential':
        case 'wrong-password':
          return "Mật khẩu không chính xác. Vui lòng kiểm tra lại.";
        case 'user-not-found':
          return "Tài khoản '$identifier' không tồn tại trên hệ thống.";
        case 'user-disabled':
          return "Tài khoản này đã bị khóa. Vui lòng liên hệ kỹ thuật.";
        case 'too-many-requests':
          return "Bạn đã nhập sai quá nhiều lần. Vui lòng thử lại sau ít phút.";
        case 'invalid-email':
          return "Định dạng tài khoản không hợp lệ.";
        default:
          return "Lỗi đăng nhập (${e.code}): ${e.message}";
      }
    } catch (e) {
      return "Không thể kết nối đến máy chủ: $e";
    }
  }

  // Đăng xuất
  Future<void> signOut() async {
    await _auth.signOut();
  }

  // Lấy trạng thái đăng nhập hiện tại
  Stream<User?> get authStateChanges => _auth.authStateChanges();
}
