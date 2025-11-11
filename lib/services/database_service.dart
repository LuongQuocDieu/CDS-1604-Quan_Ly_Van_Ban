import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart' as p;
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart' show kIsWeb;

// Import sqflite_common_ffi for non-web platforms ONLY
// This automatically initializes databaseFactory
// ignore_for_file: unused_import
import 'package:sqflite_common_ffi/sqflite_ffi.dart'
    if (dart.library.html) 'dart:core';

class DatabaseService {
  static final DatabaseService _instance = DatabaseService._internal();
  static Database? _database;
  final FirebaseAuth _firebaseAuth = FirebaseAuth.instance;

  DatabaseService._internal();

  factory DatabaseService() {
    return _instance;
  }

  /// Lấy database instance
  Future<Database> get database async {
    _database ??= await _initDatabase();
    return _database!;
  }

  /// Khởi tạo database
  Future<Database> _initDatabase() async {
    try {
      // For web platform, use in-memory database
      if (kIsWeb) {
        print('Web platform detected - using in-memory database');
        return await openDatabase(
          ':memory:',
          version: 1,
          onCreate: _createTables,
        );
      }

      // For non-web platforms, just use the native openDatabase
      // sqflite_common_ffi is already set up by pubspec.yaml
      final databasePath = await getDatabasesPath();
      final path = p.join(databasePath, 'documents_db.db');

      return await openDatabase(
        path,
        version: 1,
        onCreate: _createTables,
      );
    } catch (e) {
      print('Error initializing database: $e');
      // Fallback to in-memory database if file database fails
      try {
        return await openDatabase(
          ':memory:',
          version: 1,
          onCreate: _createTables,
        );
      } catch (memoryError) {
        print('Error initializing memory database: $memoryError');
        rethrow;
      }
    }
  }

  /// Tạo các bảng
  Future<void> _createTables(Database db, int version) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS documents (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        userId TEXT NOT NULL,
        fileName TEXT NOT NULL,
        fileExtension TEXT NOT NULL,
        fileSizeInBytes INTEGER NOT NULL,
        fileSizeInMB TEXT NOT NULL,
        filePath TEXT NOT NULL,
        fileContent BLOB NOT NULL,
        description TEXT,
        createdAt TEXT NOT NULL,
        updatedAt TEXT NOT NULL,
        status TEXT DEFAULT 'active'
      )
    ''');

    await db.execute('''
      CREATE INDEX IF NOT EXISTS idx_userId_documents 
      ON documents(userId)
    ''');
  }

  /// Thêm document mới
  Future<int> addDocument({
    required String fileName,
    required String fileExtension,
    required int fileSizeInBytes,
    required String fileSizeInMB,
    required String filePath,
    required List<int> fileContent,
    String? description,
  }) async {
    try {
      User? user = _firebaseAuth.currentUser;
      if (user == null) {
        throw 'Người dùng chưa đăng nhập';
      }

      final db = await database;
      final now = DateTime.now().toIso8601String();

      return await db.insert(
        'documents',
        {
          'userId': user.uid,
          'fileName': fileName,
          'fileExtension': fileExtension,
          'fileSizeInBytes': fileSizeInBytes,
          'fileSizeInMB': fileSizeInMB,
          'filePath': filePath,
          'fileContent': fileContent,
          'description': description ?? '',
          'createdAt': now,
          'updatedAt': now,
          'status': 'active',
        },
      );
    } catch (e) {
      throw 'Lỗi thêm document: ${e.toString()}';
    }
  }

  /// Lấy danh sách document của người dùng hiện tại
  Future<List<Map<String, dynamic>>> getDocuments() async {
    try {
      User? user = _firebaseAuth.currentUser;
      if (user == null) {
        throw 'Người dùng chưa đăng nhập';
      }

      final db = await database;

      return await db.query(
        'documents',
        where: 'userId = ? AND status = ?',
        whereArgs: [user.uid, 'active'],
        orderBy: 'createdAt DESC',
      );
    } catch (e) {
      throw 'Lỗi lấy danh sách document: ${e.toString()}';
    }
  }

  /// Tìm kiếm document
  Future<List<Map<String, dynamic>>> searchDocuments(String query) async {
    try {
      User? user = _firebaseAuth.currentUser;
      if (user == null) {
        throw 'Người dùng chưa đăng nhập';
      }

      final db = await database;

      return await db.query(
        'documents',
        where: 'userId = ? AND status = ? AND fileName LIKE ?',
        whereArgs: [user.uid, 'active', '%$query%'],
        orderBy: 'createdAt DESC',
      );
    } catch (e) {
      throw 'Lỗi tìm kiếm: ${e.toString()}';
    }
  }

  /// Xóa document
  Future<void> deleteDocument(int id) async {
    try {
      User? user = _firebaseAuth.currentUser;
      if (user == null) {
        throw 'Người dùng chưa đăng nhập';
      }

      final db = await database;

      await db.update(
        'documents',
        {'status': 'deleted', 'updatedAt': DateTime.now().toIso8601String()},
        where: 'id = ? AND userId = ?',
        whereArgs: [id, user.uid],
      );
    } catch (e) {
      throw 'Lỗi xóa document: ${e.toString()}';
    }
  }

  /// Cập nhật document
  Future<void> updateDocument(
    int id,
    Map<String, dynamic> updates,
  ) async {
    try {
      User? user = _firebaseAuth.currentUser;
      if (user == null) {
        throw 'Người dùng chưa đăng nhập';
      }

      final db = await database;
      updates['updatedAt'] = DateTime.now().toIso8601String();

      await db.update(
        'documents',
        updates,
        where: 'id = ? AND userId = ?',
        whereArgs: [id, user.uid],
      );
    } catch (e) {
      throw 'Lỗi cập nhật document: ${e.toString()}';
    }
  }

  /// Lấy nội dung file
  Future<List<int>> getFileContent(int id) async {
    try {
      User? user = _firebaseAuth.currentUser;
      if (user == null) {
        throw 'Người dùng chưa đăng nhập';
      }

      final db = await database;

      final result = await db.query(
        'documents',
        columns: ['fileContent'],
        where: 'id = ? AND userId = ?',
        whereArgs: [id, user.uid],
      );

      if (result.isEmpty) {
        throw 'File không tìm thấy';
      }

      return List<int>.from(result.first['fileContent'] as List);
    } catch (e) {
      throw 'Lỗi lấy nội dung file: ${e.toString()}';
    }
  }

  /// Tính tổng dung lượng file
  Future<String> getTotalSize() async {
    try {
      User? user = _firebaseAuth.currentUser;
      if (user == null) {
        throw 'Người dùng chưa đăng nhập';
      }

      final db = await database;

      final result = await db.rawQuery(
        'SELECT SUM(fileSizeInBytes) as total FROM documents WHERE userId = ? AND status = ?',
        [user.uid, 'active'],
      );

      if (result.isEmpty || result.first['total'] == null) {
        return '0 MB';
      }

      int totalBytes = result.first['total'] as int;
      double totalMB = totalBytes / (1024 * 1024);

      if (totalMB < 1024) {
        return '${totalMB.toStringAsFixed(2)} MB';
      } else {
        return '${(totalMB / 1024).toStringAsFixed(2)} GB';
      }
    } catch (e) {
      throw 'Lỗi tính toán dung lượng: ${e.toString()}';
    }
  }

  /// Đóng database
  Future<void> closeDatabase() async {
    if (_database != null) {
      await _database!.close();
      _database = null;
    }
  }
}
