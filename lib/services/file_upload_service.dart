import 'package:file_picker/file_picker.dart';
import 'dart:io';
import 'dart:convert';
import 'package:path/path.dart' as path;
import 'package:firebase_auth/firebase_auth.dart';
import 'file_list_service.dart';
import 'category_service.dart';
import 'ocr_service.dart';

class FileUploadService {
  final FirebaseAuth _firebaseAuth = FirebaseAuth.instance;
  late final FileListService _fileListService;
  late final OCRService _ocrService;

  FileUploadService() {
    // Use singleton instance of FileListService
    _fileListService = FileListService.instance;
    _ocrService = OCRService();
  }

  // Danh sách loại file được phép upload
  static const List<String> allowedExtensions = [
    'doc',
    'docx',
    'xls',
    'xlsx',
    'txt',
    'pdf',
    'ppt',
    'pptx',
    'jpg',
    'jpeg',
    'png',
    'gif',
    'bmp',
  ];

  // Image extensions that trigger auto-OCR
  static const List<String> imageExtensions = [
    'jpg',
    'jpeg',
    'png',
    'gif',
    'bmp',
  ];

  /// Chọn và upload file
  Future<Map<String, dynamic>?> pickAndUploadFile() async {
    try {
      User? user = _firebaseAuth.currentUser;
      if (user == null) {
        throw 'Vui lòng đăng nhập trước khi upload file';
      }

      // Mở file picker
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: allowedExtensions,
        allowMultiple: false,
      );

      if (result != null) {
        PlatformFile platformFile = result.files.single;

        // Xử lý cả mobile (path) và web (bytes)
        if (platformFile.bytes != null) {
          // Web hoặc nền tảng khác sử dụng bytes
          return await uploadFileFromBytes(platformFile);
        } else if (platformFile.path != null) {
          // Mobile sử dụng path
          File file = File(platformFile.path!);
          return await uploadFileFromPath(file);
        }
      }
    } catch (e) {
      throw 'Lỗi chọn file: ${e.toString()}';
    }
    return null;
  }

  /// Upload file từ bytes (Web support)
  Future<Map<String, dynamic>> uploadFileFromBytes(
    PlatformFile platformFile,
  ) async {
    try {
      String fileName = platformFile.name;
      String fileExtension = path.extension(fileName).toLowerCase().replaceFirst('.', '');

      // Kiểm tra loại file
      if (!allowedExtensions.contains(fileExtension)) {
        throw 'Loại file không được phép. Chỉ cho phép: ${allowedExtensions.join(', ')}';
      }

      // Lấy file bytes
      List<int> fileBytes = platformFile.bytes ?? [];
      int fileSizeInBytes = fileBytes.length;
      double fileSizeInMB = fileSizeInBytes / (1024 * 1024);

      // Kiểm tra kích thước file (max 50MB)
      if (fileSizeInMB > 50) {
        throw 'Kích thước file quá lớn (tối đa 50MB)';
      }

      // Auto-detect category
      String category = CategoryService.getCategoryFromExtension(fileExtension);

      // Auto-OCR cho hình ảnh
      String? ocrText;
      if (imageExtensions.contains(fileExtension)) {
        try {
          // Lưu bytes tạm thời vào file để OCR
          final tempDir = Directory.systemTemp;
          final tempFile = File('${tempDir.path}/upload_ocr_${DateTime.now().millisecondsSinceEpoch}.$fileExtension');
          await tempFile.writeAsBytes(fileBytes);
          
          // Chạy OCR
          ocrText = await _ocrService.extractTextFromImage(tempFile.path);
          
          // Xóa file tạm
          if (await tempFile.exists()) {
            await tempFile.delete();
          }
        } catch (e) {
          // Nếu OCR lỗi, không ảnh hưởng đến việc upload
          print('OCR lỗi: $e');
        }
      }

      // Thêm vào danh sách file (bao gồm nội dung)
      String base64Content = base64Encode(fileBytes);
      await _fileListService.addFile(
        name: fileName,
        extension: fileExtension,
        content: base64Content,
        category: category,
        size: fileSizeInBytes,
        description: ocrText ?? '',
      );

      // Trả về thông tin file
      return {
        'fileName': fileName,
        'fileExtension': fileExtension,
        'fileSizeInBytes': fileSizeInBytes,
        'fileSizeInMB': fileSizeInMB.toStringAsFixed(2),
        'uploadedAt': DateTime.now(),
        'hasOCR': ocrText != null && ocrText.isNotEmpty,
      };
    } catch (e) {
      throw 'Lỗi upload file: ${e.toString()}';
    }
  }

  /// Upload file từ path (Mobile support)
  Future<Map<String, dynamic>> uploadFileFromPath(File file) async {
    try {
      String fileName = path.basename(file.path);
      String fileExtension = path.extension(fileName).toLowerCase().replaceFirst('.', '');

      // Kiểm tra loại file
      if (!allowedExtensions.contains(fileExtension)) {
        throw 'Loại file không được phép. Chỉ cho phép: ${allowedExtensions.join(', ')}';
      }

      // Tính kích thước file
      int fileSizeInBytes = await file.length();
      double fileSizeInMB = fileSizeInBytes / (1024 * 1024);

      // Kiểm tra kích thước file (max 50MB)
      if (fileSizeInMB > 50) {
        throw 'Kích thước file quá lớn (tối đa 50MB)';
      }

      // Đọc file bytes
      List<int> fileBytes = await file.readAsBytes();
      
      // Auto-detect category
      String category = CategoryService.getCategoryFromExtension(fileExtension);

      // Auto-OCR cho hình ảnh
      String? ocrText;
      if (imageExtensions.contains(fileExtension)) {
        try {
          ocrText = await _ocrService.extractTextFromImage(file.path);
        } catch (e) {
          // Nếu OCR lỗi, không ảnh hưởng đến việc upload
          print('OCR lỗi: $e');
        }
      }

      // Thêm vào danh sách file (bao gồm nội dung)
      String base64Content = base64Encode(fileBytes);
      await _fileListService.addFile(
        name: fileName,
        extension: fileExtension,
        content: base64Content,
        category: category,
        size: fileSizeInBytes,
        description: ocrText ?? '',
      );

      // Trả về thông tin file
      return {
        'fileName': fileName,
        'fileExtension': fileExtension,
        'fileSizeInBytes': fileSizeInBytes,
        'fileSizeInMB': fileSizeInMB.toStringAsFixed(2),
        'uploadedAt': DateTime.now(),
        'hasOCR': ocrText != null && ocrText.isNotEmpty,
      };
    } catch (e) {
      throw 'Lỗi upload file: ${e.toString()}';
    }
  }
}
