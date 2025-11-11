import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AuthService {
  static final AuthService _instance = AuthService._internal();
  
  final FirebaseAuth _firebaseAuth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  
  late Stream<User?> _authStateChangesStream;

  AuthService._internal() {
    // Tạo stream 1 lần và cache (but it will emit fresh events)
    _authStateChangesStream = _firebaseAuth.authStateChanges().asBroadcastStream();
    print('🔄 [AuthService] Initializing authStateChanges stream as broadcast');
  }

  factory AuthService() {
    return _instance;
  }

  // Stream để theo dõi trạng thái đăng nhập
  Stream<User?> get authStateChanges {
    print('📡 [AuthService] Getting cached authStateChanges stream');
    return _authStateChangesStream;
  }

  // Đăng ký tài khoản mới
  Future<User?> registerWithEmailAndPassword({
    required String email,
    required String password,
    required String name,
  }) async {
    try {
      print('🔄 [Register] Bắt đầu với email: $email');
      
      UserCredential userCredential = await _firebaseAuth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      ).timeout(
        const Duration(seconds: 10),
        onTimeout: () => throw 'Timeout: Không nhận được phản hồi từ Firebase trong 10 giây',
      );

      print('✅ [Register] Firebase Auth tạo tài khoản thành công!');
      User? user = userCredential.user;

      // Lưu thông tin người dùng vào Firestore
      if (user != null) {
        try {
          print('🔄 [Register] Tạo document Firestore...');
          await _firestore.collection('users').doc(user.uid).set({
            'uid': user.uid,
            'name': name,
            'email': email,
            'role': 'Người dùng',
            'status': 'Bảo mật',
            'createdAt': DateTime.now(),
            'updatedAt': DateTime.now(),
          }).timeout(
            const Duration(seconds: 5),
            onTimeout: () => print('⚠️ [Register] Timeout Firestore - nhưng vẫn cho đăng ký'),
          );

          print('✅ [Register] Firestore document tạo xong!');
          
          // Cập nhật display name
          await user.updateDisplayName(name);
          await user.reload();
          print('✅ [Register] Display name cập nhật xong!');
        } catch (firestoreError) {
          print('⚠️ [Register] Lỗi Firestore khi tạo user: $firestoreError');
          print('💡 Kiểm tra: Firestore Rules có cho phép write collection "users" không?');
          // Vẫn trả về user ngay cả khi Firestore fail
        }
      }

      return user;
    } on FirebaseAuthException catch (e) {
      print('❌ [Register] Firebase Auth Exception: ${e.code}');
      throw _handleAuthException(e);
    } catch (e) {
      print('❌ [Register] Lỗi chung: $e');
      throw 'Lỗi đăng ký: $e';
    }
  }

  // Đăng nhập
  Future<User?> signInWithEmailAndPassword({
    required String email,
    required String password,
  }) async {
    try {
      print('🔄 [SignIn] Bắt đầu với email: $email');
      
      // Thêm timeout để tránh hang
      UserCredential userCredential = await _firebaseAuth.signInWithEmailAndPassword(
        email: email,
        password: password,
      ).timeout(
        const Duration(seconds: 10),
        onTimeout: () => throw 'Timeout: Không nhận được phản hồi từ Firebase trong 10 giây',
      );

      print('✅ [SignIn] Firebase Auth thành công!');
      User? user = userCredential.user;

      // Cập nhật trạng thái người dùng
      if (user != null) {
        try {
          print('🔄 [SignIn] Cập nhật Firestore...');
          // Dùng set với merge: true thay vì update để tránh lỗi nếu document không tồn tại
          await _firestore.collection('users').doc(user.uid).set({
            'lastLogin': DateTime.now(),
            'status': 'Bảo mật',
          }, SetOptions(merge: true)).timeout(
            const Duration(seconds: 5),
            onTimeout: () => print('⚠️ [SignIn] Timeout Firestore - nhưng vẫn cho đăng nhập'),
          );
          print('✅ [SignIn] Firestore cập nhật xong!');
        } catch (firestoreError) {
          // In lỗi Firestore nhưng vẫn cho phép đăng nhập
          print('⚠️ [SignIn] Lỗi Firestore khi cập nhật lastLogin: $firestoreError');
          print('💡 Kiểm tra: Firestore Rules có cho phép write không?');
          // Không throw - cho phép đăng nhập ngay cả khi Firestore fail
        }
      }

      return user;
    } on FirebaseAuthException catch (e) {
      print('❌ [SignIn] Firebase Auth Exception: ${e.code}');
      throw _handleAuthException(e);
    } catch (e) {
      print('❌ [SignIn] Lỗi chung: $e');
      throw 'Lỗi đăng nhập: $e';
    }
  }

  // Đăng xuất
  Future<void> signOut() async {
    try {
      User? user = _firebaseAuth.currentUser;
      if (user != null) {
        try {
          // Kiểm tra document tồn tại trước khi update
          DocumentSnapshot docSnapshot = await _firestore.collection('users').doc(user.uid).get();
          if (docSnapshot.exists) {
            await _firestore.collection('users').doc(user.uid).update({
              'status': 'Ngoại tuyến',
              'lastLogout': DateTime.now(),
            });
          }
        } catch (firestoreError) {
          // Nếu lỗi Firestore, vẫn tiếp tục đăng xuất từ Firebase Auth
          print('Lỗi cập nhật Firestore: $firestoreError');
        }
      }
      await _firebaseAuth.signOut();
    } catch (e) {
      throw 'Lỗi đăng xuất: ${e.toString()}';
    }
  }

  // Đặt lại mật khẩu
  Future<void> sendPasswordResetEmail(String email) async {
    try {
      await _firebaseAuth.sendPasswordResetEmail(email: email);
    } on FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    }
  }

  // Lấy thông tin người dùng hiện tại từ Firestore
  Future<Map<String, dynamic>?> getCurrentUserInfo() async {
    try {
      User? user = _firebaseAuth.currentUser;
      if (user != null) {
        try {
          DocumentSnapshot doc = await _firestore.collection('users').doc(user.uid).get();
          return doc.data() as Map<String, dynamic>?;
        } catch (firestoreError) {
          print('⚠️ Lỗi Firestore khi lấy thông tin user: $firestoreError');
          print('💡 Kiểm tra: Firestore Rules có cho phép read không?');
          // Trả về null thay vì throw
          return null;
        }
      }
      return null;
    } catch (e) {
      print('❌ Lỗi lấy thông tin người dùng: ${e.toString()}');
      return null;
    }
  }

  // Cập nhật thông tin người dùng
  Future<void> updateUserInfo(Map<String, dynamic> updates) async {
    try {
      User? user = _firebaseAuth.currentUser;
      if (user != null) {
        updates['updatedAt'] = DateTime.now();
        try {
          await _firestore.collection('users').doc(user.uid).update(updates);

          // Cập nhật display name nếu có
          if (updates.containsKey('name')) {
            await user.updateDisplayName(updates['name']);
            await user.reload();
          }
        } catch (firestoreError) {
          print('⚠️ Lỗi Firestore khi cập nhật user: $firestoreError');
          print('💡 Kiểm tra: Firestore Rules có cho phép write không?');
        }
      }
    } catch (e) {
      print('❌ Lỗi cập nhật thông tin: ${e.toString()}');
    }
  }

  // Xử lý lỗi Firebase Auth
  String _handleAuthException(FirebaseAuthException e) {
    switch (e.code) {
      case 'weak-password':
        return 'Mật khẩu quá yếu. Vui lòng chọn mật khẩu mạnh hơn.';
      case 'email-already-in-use':
        return 'Email này đã được đăng ký. Vui lòng sử dụng email khác.';
      case 'invalid-email':
        return 'Email không hợp lệ.';
      case 'user-disabled':
        return 'Tài khoản này đã bị vô hiệu hóa.';
      case 'user-not-found':
        return 'Người dùng không tìm thấy.';
      case 'wrong-password':
        return 'Mật khẩu không chính xác.';
      case 'operation-not-allowed':
        return 'Hoạt động này không được phép.';
      case 'too-many-requests':
        return 'Quá nhiều yêu cầu. Vui lòng thử lại sau.';
      default:
        return 'Lỗi: ${e.message}';
    }
  }

  // Kiểm tra người dùng đã đăng nhập
  User? get currentUser => _firebaseAuth.currentUser;
}
