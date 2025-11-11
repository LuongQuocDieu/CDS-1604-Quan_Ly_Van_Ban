import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'dart:convert';
import 'dart:async';

// ignore: avoid_web_libraries_in_flutter
import 'dart:html' as html;

/// Đơn giản: Chỉ lưu tên file và ngày tải lên
/// Web: dùng localStorage
/// Mobile: có thể mở rộng dùng SQLite
class FileListService {
  final FirebaseAuth _firebaseAuth = FirebaseAuth.instance;
  static const String _storageKey = 'uploaded_files';
  
  // Stream controller để notify khi có thay đổi
  final _filesStreamController = StreamController<List<Map<String, dynamic>>>.broadcast();
  
  // Singleton instance
  static FileListService? _instance;
  
  // Private constructor
  FileListService._internal();
  
  // Factory constructor
  factory FileListService() {
    _instance ??= FileListService._internal();
    return _instance!;
  }
  
  // Direct access to singleton
  static FileListService get instance {
    _instance ??= FileListService._internal();
    return _instance!;
  }

  /// Lấy localStorage (web only)
  dynamic get _localStorage {
    if (!kIsWeb) return null;
    try {
      return html.window.localStorage;
    } catch (e) {
      return null;
    }
  }

  /// Lấy user ID hiện tại
  String _getUserId() {
    final user = _firebaseAuth.currentUser;
    if (user == null) throw 'User not logged in';
    return user.uid;
  }

  /// Lấy key duy nhất cho user này
  String _getKey() => '${_storageKey}_${_getUserId()}';
  
  /// Getter cho stream files
  Stream<List<Map<String, dynamic>>> get filesStream => _filesStreamController.stream;
  
  /// Load dữ liệu từ localStorage vào stream
  Future<void> loadFiles() async {
    try {
      final files = await getFiles();
      _filesStreamController.add(files);
    } catch (e) {
      _filesStreamController.addError(e);
    }
  }
  
  /// Refresh stream với data mới từ localStorage
  Future<void> _refreshStream() async {
    try {
      final files = await getFiles();
      _filesStreamController.add(files);
    } catch (e) {
      _filesStreamController.addError(e);
    }
  }

  /// Lấy danh sách files
  Future<List<Map<String, dynamic>>> getFiles() async {
    try {
      final key = _getKey();

      if (kIsWeb) {
        final storage = _localStorage;
        if (storage != null) {
          // ignore: avoid_dynamic_calls
          String? jsonStr = storage[key] as String?;
          if (jsonStr != null && jsonStr.isNotEmpty) {
            final List<dynamic> files = jsonDecode(jsonStr);
            return files.cast<Map<String, dynamic>>();
          }
        }
      }
      return [];
    } catch (e) {
      return [];
    }
  }

  /// Xóa file khỏi list
  Future<void> deleteFile(int id) async {
    try {
      final key = _getKey();

      if (kIsWeb) {
        final storage = _localStorage;
        if (storage != null) {
          // ignore: avoid_dynamic_calls
          String? jsonStr = storage[key] as String?;
          if (jsonStr != null && jsonStr.isNotEmpty) {
            List<dynamic> files = jsonDecode(jsonStr);
            files.removeWhere((f) => f['id'] == id);
            // ignore: avoid_dynamic_calls
            storage[key] = jsonEncode(files);
            
            // Refresh stream để notify listeners
            await _refreshStream();
          }
        }
      }
    } catch (e) {
      rethrow;
    }
  }

  /// Tìm kiếm files theo tên
  Future<List<Map<String, dynamic>>> searchFiles(String query) async {
    try {
      final files = await getFiles();
      if (query.isEmpty) return files;
      return files
          .where((f) =>
              (f['name'] as String).toLowerCase().contains(query.toLowerCase()))
          .toList();
    } catch (e) {
      return [];
    }
  }

  /// ✅ Thêm file với content base64
  Future<void> addFile({
    required String name,
    required String extension,
    required String content, // base64 encoded
    required String category,
    required int size,
    String? description,
  }) async {
    try {
      final key = _getKey();
      final now = DateTime.now().millisecondsSinceEpoch;

      final fileInfo = {
        'id': DateTime.now().microsecondsSinceEpoch,
        'name': name,
        'extension': extension,
        'uploadedAt': now,
        'content': content,
        'category': category,
        'size': size,
        'description': description ?? '',
        'folder': '📂 Khác',
      };

      if (kIsWeb) {
        final storage = _localStorage;
        if (storage != null) {
          // ignore: avoid_dynamic_calls
          String? existingJson = storage[key] as String?;
          final List<dynamic> files = existingJson != null
              ? jsonDecode(existingJson)
              : [];

          files.add(fileInfo);
          // ignore: avoid_dynamic_calls
          storage[key] = jsonEncode(files);

          await _refreshStream();
        }
      }
    } catch (e) {
      rethrow;
    }
  }

  /// 📁 Gán thư mục cho file
  Future<void> assignFolder(int fileId, String folder) async {
    try {
      final key = _getKey();

      if (kIsWeb) {
        final storage = _localStorage;
        if (storage != null) {
          // ignore: avoid_dynamic_calls
          String? jsonStr = storage[key] as String?;
          if (jsonStr != null && jsonStr.isNotEmpty) {
            List<dynamic> files = jsonDecode(jsonStr);
            for (var file in files) {
              if (file['id'] == fileId) {
                file['folder'] = folder;
                break;
              }
            }
            // ignore: avoid_dynamic_calls
            storage[key] = jsonEncode(files);

            await _refreshStream();
          }
        }
      }
    } catch (e) {
      rethrow;
    }
  }

  /// 🔄 Cập nhật category file
  Future<void> updateFileCategory(int fileId, String category) async {
    try {
      final key = _getKey();

      if (kIsWeb) {
        final storage = _localStorage;
        if (storage != null) {
          // ignore: avoid_dynamic_calls
          String? jsonStr = storage[key] as String?;
          if (jsonStr != null && jsonStr.isNotEmpty) {
            List<dynamic> files = jsonDecode(jsonStr);
            for (var file in files) {
              if (file['id'] == fileId) {
                file['category'] = category;
                break;
              }
            }
            // ignore: avoid_dynamic_calls
            storage[key] = jsonEncode(files);

            await _refreshStream();
          }
        }
      }
    } catch (e) {
      rethrow;
    }
  }

  /// 🔍 Lấy tất cả files
  Future<List<Map<String, dynamic>>> getAllFiles() async {
    return getFiles();
  }

  /// 📝 Cập nhật mô tả file
  Future<void> updateFileDescription(int fileId, String description) async {
    try {
      final key = _getKey();

      if (kIsWeb) {
        final storage = _localStorage;
        if (storage != null) {
          // ignore: avoid_dynamic_calls
          String? jsonStr = storage[key] as String?;
          if (jsonStr != null && jsonStr.isNotEmpty) {
            List<dynamic> files = jsonDecode(jsonStr);
            for (var file in files) {
              if (file['id'] == fileId) {
                file['description'] = description;
                break;
              }
            }
            // ignore: avoid_dynamic_calls
            storage[key] = jsonEncode(files);

            await _refreshStream();
          }
        }
      }
    } catch (e) {
      rethrow;
    }
  }

  /// 🗂️ Lấy files theo folder
  Future<List<Map<String, dynamic>>> getFilesByFolder(String folder) async {
    try {
      final files = await getFiles();
      return files.where((f) => (f['folder'] ?? '📂 Khác') == folder).toList();
    } catch (e) {
      return [];
    }
  }

  /// 💾 Lưu file để tải về (trả về base64)
  Future<String?> getFileContent(int fileId) async {
    try {
      final files = await getFiles();
      final file = files.firstWhere((f) => f['id'] == fileId);
      return file['content'] as String?;
    } catch (e) {
      return null;
    }
  }

  /// Dispose
  void dispose() {
    _filesStreamController.close();
  }
}
