import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class DocumentService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _firebaseAuth = FirebaseAuth.instance;

  // Thêm tài liệu mới
  Future<String> addDocument({
    required String title,
    required String type,
    required String size,
    required String description,
  }) async {
    try {
      User? user = _firebaseAuth.currentUser;
      if (user == null) {
        throw 'Người dùng chưa đăng nhập';
      }

      final docRef = await _firestore
          .collection('users')
          .doc(user.uid)
          .collection('documents')
          .add({
        'title': title,
        'type': type,
        'size': size,
        'description': description,
        'createdAt': DateTime.now(),
        'updatedAt': DateTime.now(),
        'status': 'active',
      });

      return docRef.id;
    } catch (e) {
      throw 'Lỗi thêm tài liệu: ${e.toString()}';
    }
  }

  // Lấy danh sách tài liệu của người dùng hiện tại
  Stream<List<Map<String, dynamic>>> getDocumentsStream() {
    try {
      User? user = _firebaseAuth.currentUser;
      if (user == null) {
        throw 'Người dùng chưa đăng nhập';
      }

      return _firestore
          .collection('users')
          .doc(user.uid)
          .collection('documents')
          .orderBy('createdAt', descending: true)
          .snapshots()
          .map((snapshot) {
        return snapshot.docs.map((doc) {
          final data = doc.data();
          data['id'] = doc.id;
          return data;
        }).toList();
      });
    } catch (e) {
      throw 'Lỗi tải tài liệu: ${e.toString()}';
    }
  }

  // Lấy danh sách tài liệu (một lần)
  Future<List<Map<String, dynamic>>> getDocuments() async {
    try {
      User? user = _firebaseAuth.currentUser;
      if (user == null) {
        throw 'Người dùng chưa đăng nhập';
      }

      final snapshot = await _firestore
          .collection('users')
          .doc(user.uid)
          .collection('documents')
          .orderBy('createdAt', descending: true)
          .get();

      return snapshot.docs.map((doc) {
        final data = doc.data();
        data['id'] = doc.id;
        return data;
      }).toList();
    } catch (e) {
      throw 'Lỗi tải tài liệu: ${e.toString()}';
    }
  }

  // Cập nhật tài liệu
  Future<void> updateDocument({
    required String documentId,
    required Map<String, dynamic> updates,
  }) async {
    try {
      User? user = _firebaseAuth.currentUser;
      if (user == null) {
        throw 'Người dùng chưa đăng nhập';
      }

      updates['updatedAt'] = DateTime.now();

      await _firestore
          .collection('users')
          .doc(user.uid)
          .collection('documents')
          .doc(documentId)
          .update(updates);
    } catch (e) {
      throw 'Lỗi cập nhật tài liệu: ${e.toString()}';
    }
  }

  // Xóa tài liệu
  Future<void> deleteDocument(String documentId) async {
    try {
      User? user = _firebaseAuth.currentUser;
      if (user == null) {
        throw 'Người dùng chưa đăng nhập';
      }

      await _firestore
          .collection('users')
          .doc(user.uid)
          .collection('documents')
          .doc(documentId)
          .delete();
    } catch (e) {
      throw 'Lỗi xóa tài liệu: ${e.toString()}';
    }
  }

  // Tìm kiếm tài liệu theo tên
  Future<List<Map<String, dynamic>>> searchDocuments(String query) async {
    try {
      User? user = _firebaseAuth.currentUser;
      if (user == null) {
        throw 'Người dùng chưa đăng nhập';
      }

      final snapshot = await _firestore
          .collection('users')
          .doc(user.uid)
          .collection('documents')
          .get();

      return snapshot.docs
          .map((doc) {
            final data = doc.data();
            data['id'] = doc.id;
            return data;
          })
          .where((doc) =>
              doc['title'].toString().toLowerCase().contains(query.toLowerCase()))
          .toList();
    } catch (e) {
      throw 'Lỗi tìm kiếm tài liệu: ${e.toString()}';
    }
  }

  // Lấy tài liệu theo loại
  Future<List<Map<String, dynamic>>> getDocumentsByType(String type) async {
    try {
      User? user = _firebaseAuth.currentUser;
      if (user == null) {
        throw 'Người dùng chưa đăng nhập';
      }

      final snapshot = await _firestore
          .collection('users')
          .doc(user.uid)
          .collection('documents')
          .where('type', isEqualTo: type)
          .orderBy('createdAt', descending: true)
          .get();

      return snapshot.docs.map((doc) {
        final data = doc.data();
        data['id'] = doc.id;
        return data;
      }).toList();
    } catch (e) {
      throw 'Lỗi tải tài liệu theo loại: ${e.toString()}';
    }
  }

  // Đếm tổng số tài liệu
  Future<int> countDocuments() async {
    try {
      User? user = _firebaseAuth.currentUser;
      if (user == null) {
        throw 'Người dùng chưa đăng nhập';
      }

      final snapshot = await _firestore
          .collection('users')
          .doc(user.uid)
          .collection('documents')
          .get();

      return snapshot.docs.length;
    } catch (e) {
      throw 'Lỗi đếm tài liệu: ${e.toString()}';
    }
  }

  // Lấy kích thước tổng cộng của tất cả tài liệu
  Future<String> getTotalSize() async {
    try {
      User? user = _firebaseAuth.currentUser;
      if (user == null) {
        throw 'Người dùng chưa đăng nhập';
      }

      final snapshot = await _firestore
          .collection('users')
          .doc(user.uid)
          .collection('documents')
          .get();

      double totalSize = 0;
      for (var doc in snapshot.docs) {
        final sizeStr = doc['size'].toString().replaceAll(RegExp(r'[^0-9.]'), '');
        totalSize += double.tryParse(sizeStr) ?? 0;
      }

      if (totalSize < 1024) {
        return '${totalSize.toStringAsFixed(2)} MB';
      } else {
        return '${(totalSize / 1024).toStringAsFixed(2)} GB';
      }
    } catch (e) {
      throw 'Lỗi tính toán kích thước: ${e.toString()}';
    }
  }

  // Thêm file upload info vào Firestore
  Future<String> addUploadedFile({
    required String fileName,
    required String fileExtension,
    required int fileSizeInBytes,
    required String downloadUrl,
    required String storagePath,
    String? description,
  }) async {
    try {
      User? user = _firebaseAuth.currentUser;
      if (user == null) {
        throw 'Người dùng chưa đăng nhập';
      }

      final docRef = await _firestore
          .collection('users')
          .doc(user.uid)
          .collection('documents')
          .add({
        'fileName': fileName,
        'fileExtension': fileExtension,
        'fileSizeInBytes': fileSizeInBytes,
        'fileSizeInMB': (fileSizeInBytes / (1024 * 1024)).toStringAsFixed(2),
        'downloadUrl': downloadUrl,
        'storagePath': storagePath,
        'description': description ?? '',
        'type': 'file_$fileExtension',
        'createdAt': DateTime.now(),
        'updatedAt': DateTime.now(),
        'status': 'active',
      });

      return docRef.id;
    } catch (e) {
      throw 'Lỗi lưu thông tin file: ${e.toString()}';
    }
  }

  // Lấy danh sách file của người dùng
  Stream<List<Map<String, dynamic>>> getUploadedFilesStream() {
    try {
      User? user = _firebaseAuth.currentUser;
      if (user == null) {
        throw 'Người dùng chưa đăng nhập';
      }

      return _firestore
          .collection('users')
          .doc(user.uid)
          .collection('documents')
          .where('downloadUrl', isNotEqualTo: '')
          .orderBy('downloadUrl')
          .orderBy('createdAt', descending: true)
          .snapshots()
          .map((snapshot) => snapshot.docs
              .map((doc) => {
                    'id': doc.id,
                    ...doc.data(),
                  })
              .toList());
    } catch (e) {
      throw 'Lỗi lấy danh sách file: ${e.toString()}';
    }
  }

  // Xóa file
  Future<void> deleteUploadedFile(String docId) async {
    try {
      User? user = _firebaseAuth.currentUser;
      if (user == null) {
        throw 'Người dùng chưa đăng nhập';
      }

      await _firestore
          .collection('users')
          .doc(user.uid)
          .collection('documents')
          .doc(docId)
          .delete();
    } catch (e) {
      throw 'Lỗi xóa file: ${e.toString()}';
    }
  }

  // Cập nhật thông tin file
  Future<void> updateUploadedFile(
    String docId,
    Map<String, dynamic> updates,
  ) async {
    try {
      User? user = _firebaseAuth.currentUser;
      if (user == null) {
        throw 'Người dùng chưa đăng nhập';
      }

      updates['updatedAt'] = DateTime.now();

      await _firestore
          .collection('users')
          .doc(user.uid)
          .collection('documents')
          .doc(docId)
          .update(updates);
    } catch (e) {
      throw 'Lỗi cập nhật file: ${e.toString()}';
    }
  }
}

