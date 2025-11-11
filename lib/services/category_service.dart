/// Service quản lý thư mục (Categories/Folders)
class CategoryService {
  // Định nghĩa các thư mục mặc định
  static const Map<String, Map<String, dynamic>> defaultCategories = {
    'word': {
      'name': '📄 Word',
      'extensions': ['doc', 'docx'],
      'icon': '📄',
      'color': '0xFF2196F3',
    },
    'excel': {
      'name': '📊 Excel',
      'extensions': ['xls', 'xlsx'],
      'icon': '📊',
      'color': '0xFF4CAF50',
    },
    'pdf': {
      'name': '📕 PDF',
      'extensions': ['pdf'],
      'icon': '📕',
      'color': '0xFFF44336',
    },
    'powerpoint': {
      'name': '🎯 PowerPoint',
      'extensions': ['ppt', 'pptx'],
      'icon': '🎯',
      'color': '0xFFFF9800',
    },
    'text': {
      'name': '📝 Text',
      'extensions': ['txt'],
      'icon': '📝',
      'color': '0xFF9C27B0',
    },
    'images': {
      'name': '🖼️ Hình Ảnh',
      'extensions': ['jpg', 'jpeg', 'png', 'gif', 'bmp'],
      'icon': '🖼️',
      'color': '0xFF00BCD4',
    },
    'ocr': {
      'name': '🔤 OCR',
      'extensions': [],
      'icon': '🔤',
      'color': '0xFF673AB7',
      'description': 'Tài liệu từ OCR scan',
    },
    'other': {
      'name': '📦 Khác',
      'extensions': [],
      'icon': '📦',
      'color': '0xFF607D8B',
    },
  };

  /// Lấy category từ file extension
  static String getCategoryFromExtension(String extension) {
    final ext = extension.toLowerCase();

    for (final entry in defaultCategories.entries) {
      final extensions = entry.value['extensions'] as List<dynamic>;
      if (extensions.contains(ext)) {
        return entry.key;
      }
    }

    // Kiểm tra nếu là hình ảnh
    final imageExtensions = defaultCategories['images']!['extensions'] as List<dynamic>;
    if (imageExtensions.contains(ext)) {
      return 'images';
    }

    return 'other';
  }

  /// Lấy thông tin category
  static Map<String, dynamic> getCategoryInfo(String categoryId) {
    return defaultCategories[categoryId] ?? defaultCategories['other']!;
  }

  /// Lấy tất cả categories
  static List<Map<String, dynamic>> getAllCategories() {
    return defaultCategories.entries.map((e) {
      return {...e.value, 'id': e.key};
    }).toList();
  }

  /// Kiểm tra xem extension có phải hình ảnh không
  static bool isImage(String extension) {
    final imageExtensions = defaultCategories['images']!['extensions'] as List<dynamic>;
    return imageExtensions.contains(extension.toLowerCase());
  }

  /// Kiểm tra xem file có cần OCR không
  static bool needsOCR(String extension) {
    return isImage(extension);
  }

  /// 🤖 Phân loại file từ extension
  String categorizeFile(String extension) {
    return getCategoryFromExtension(extension);
  }
}
