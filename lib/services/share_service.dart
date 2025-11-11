import 'dart:convert';
import 'package:crypto/crypto.dart';

/// Service để quản lý chia sẻ tài liệu
/// Hỗ trợ: Chia sẻ đường dẫn, Chia sẻ với người dùng cụ thể
class ShareService {

  // Singleton pattern
  static final ShareService _instance = ShareService._internal();

  factory ShareService() {
    return _instance;
  }

  ShareService._internal();

  /// Tạo share link duy nhất cho file
  /// Returns: unique share key (hash)
  static String generateShareLink(int fileId, String fileName) {
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final data = '$fileId-$fileName-$timestamp';
    final hash = sha256.convert(utf8.encode(data)).toString();
    return hash.substring(0, 16); // Use first 16 chars for shorter URL
  }

  /// Lưu thông tin share file
  /// permissions: {
  ///   'canView': true/false,
  ///   'canDownload': true/false,
  ///   'canShare': true/false,
  /// }
  static Map<String, dynamic> createShareRecord(
    int fileId,
    String fileName,
    String ownerUserId,
    Map<String, bool> permissions,
  ) {
    final shareKey = generateShareLink(fileId, fileName);

    return {
      'shareKey': shareKey,
      'fileId': fileId,
      'fileName': fileName,
      'ownerUserId': ownerUserId,
      'createdAt': DateTime.now().toIso8601String(),
      'permissions': permissions,
      'isPublic': permissions['canView'] ?? false,
      'accessCount': 0,
      'lastAccessedAt': null,
      'expireAt': null, // null = no expiration
    };
  }

  /// Share file với người dùng cụ thể
  /// Returns: share record
  static Map<String, dynamic> shareWithUser(
    int fileId,
    String fileName,
    String ownerUserId,
    String recipientUserId,
    Map<String, bool> permissions,
  ) {
    final shareRecord = createShareRecord(
      fileId,
      fileName,
      ownerUserId,
      permissions,
    );

    return {
      ...shareRecord,
      'recipientUserId': recipientUserId,
      'shareType': 'user', // 'user' or 'public'
    };
  }

  /// Tạo public share link (bất kỳ ai cũng có thể truy cập nếu có link)
  static Map<String, dynamic> createPublicShare(
    int fileId,
    String fileName,
    String ownerUserId,
    Map<String, bool> permissions,
  ) {
    final shareRecord = createShareRecord(
      fileId,
      fileName,
      ownerUserId,
      permissions,
    );

    return {
      ...shareRecord,
      'shareType': 'public',
      'accessibleByAnyone': true,
    };
  }

  /// Kiểm tra quyền truy cập
  static bool hasPermission(
    Map<String, dynamic> shareRecord,
    String action,
  ) {
    final permissions = shareRecord['permissions'] as Map<String, dynamic>?;
    if (permissions == null) return false;

    switch (action) {
      case 'view':
        return permissions['canView'] ?? false;
      case 'download':
        return permissions['canDownload'] ?? false;
      case 'share':
        return permissions['canShare'] ?? false;
      default:
        return false;
    }
  }

  /// Cập nhật lần truy cập cuối
  static void updateLastAccessed(Map<String, dynamic> shareRecord) {
    shareRecord['lastAccessedAt'] = DateTime.now().toIso8601String();
    final accessCount = shareRecord['accessCount'] as int? ?? 0;
    shareRecord['accessCount'] = accessCount + 1;
  }

  /// Kiểm tra share link có hợp lệ không
  static bool isShareLinkValid(Map<String, dynamic> shareRecord) {
    // Check if expired
    if (shareRecord['expireAt'] != null) {
      final expireAt = DateTime.parse(shareRecord['expireAt'] as String);
      if (DateTime.now().isAfter(expireAt)) {
        return false; // Expired
      }
    }

    // Check if public share is still active
    if (shareRecord['shareType'] == 'public' &&
        shareRecord['isPublic'] == false) {
      return false; // Disabled
    }

    return true;
  }

  /// Tạo đường dẫn chia sẻ dạng URL
  static String generateShareUrl(String shareKey, {String? domain}) {
    final baseDomain = domain ?? 'localhost:3000';
    return 'https://$baseDomain/share/$shareKey';
  }

  /// Revoking (vô hiệu hóa) share link
  static Map<String, dynamic> revokeShare(Map<String, dynamic> shareRecord) {
    return {
      ...shareRecord,
      'isPublic': false,
      'permissions': {
        'canView': false,
        'canDownload': false,
        'canShare': false,
      },
      'revokedAt': DateTime.now().toIso8601String(),
    };
  }

  /// Tạo mã thời gian hết hạn (trong n ngày)
  static String generateExpiryDate(int daysFromNow) {
    final expireAt = DateTime.now().add(Duration(days: daysFromNow));
    return expireAt.toIso8601String();
  }

  /// Format share info để hiển thị
  static String formatShareInfo(Map<String, dynamic> shareRecord) {
    final shareType = shareRecord['shareType'] as String? ?? 'unknown';
    final recipientUserId =
        shareRecord['recipientUserId'] as String? ?? 'Public';
    final createdAt = shareRecord['createdAt'] as String?;
    final permissions = shareRecord['permissions'] as Map<String, dynamic>?;

    final permStr = [
      if (permissions?['canView'] == true) 'Xem',
      if (permissions?['canDownload'] == true) 'Tải xuống',
      if (permissions?['canShare'] == true) 'Chia sẻ tiếp',
    ].join(', ');

    final createdDate = createdAt != null
        ? DateTime.parse(createdAt).toLocal().toString().split('.')[0]
        : 'Unknown';

    return 'Chia sẻ với $recipientUserId ($shareType) - Quyền: $permStr - Lúc: $createdDate';
  }
}
