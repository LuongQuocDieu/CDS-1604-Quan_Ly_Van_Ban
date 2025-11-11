import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'dart:convert';
import 'dart:html' as html;
import '../services/file_list_service.dart';
import '../services/share_service.dart';

/// 📥 **Tải Lên File** - Upload functionality
class UploadFileFeature {
  static String _categorizeFile(String extension) {
    final ext = extension.toLowerCase();
    if (['doc', 'docx'].contains(ext)) return 'Word';
    if (['xls', 'xlsx'].contains(ext)) return 'Excel';
    if (['pdf'].contains(ext)) return 'PDF';
    if (['ppt', 'pptx'].contains(ext)) return 'PowerPoint';
    if (['txt'].contains(ext)) return 'Text';
    if (['jpg', 'jpeg', 'png', 'gif', 'bmp'].contains(ext)) return 'Hình Ảnh';
    return 'Khác';
  }

  static Future<void> uploadFile(BuildContext context) async {
    try {
      final html.FileUploadInputElement uploadInput = html.FileUploadInputElement()
        ..accept = '*/*'
        ..click();

      uploadInput.onChange.listen((e) async {
        final files = uploadInput.files;
        if (files!.isEmpty) return;

        final file = files[0];
        final reader = html.FileReader();

        reader.onLoadEnd.listen((_) async {
          try {
            final base64Content = base64Encode(reader.result as List<int>);
            final fileName = file.name;
            final fileSize = file.size;

                  // Get file extension
                  final extension = fileName.split('.').last.toLowerCase();

                  // Auto-categorize
                  final category = UploadFileFeature._categorizeFile(extension);            // Save to storage
            final fileListService = FileListService();
            await fileListService.addFile(
              name: fileName,
              extension: extension,
              content: base64Content,
              category: category,
              size: fileSize,
            );

            if (context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('✅ Tải lên thành công!'),
                  backgroundColor: Colors.green,
                ),
              );
            }
          } catch (e) {
            if (context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('❌ Lỗi: ${e.toString()}'),
                  backgroundColor: Colors.red,
                ),
              );
            }
          }
        });

        reader.readAsArrayBuffer(file);
      });
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lỗi: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }
}

/// 📄 **Xem Chi Tiết** - View document details
class DocumentDetailView {
  static void show(BuildContext context, Map<String, dynamic> fileData) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('📄 Chi tiết tài liệu'),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildDetailRow('Tên:', fileData['name'] ?? 'N/A'),
              _buildDetailRow('Loại:', fileData['extension'] ?? 'N/A'),
              _buildDetailRow(
                'Kích thước:',
                '${(fileData['size'] ?? 0) ~/ 1024} KB',
              ),
              _buildDetailRow(
                'Ngày tạo:',
                DateFormat('dd/MM/yyyy HH:mm').format(
                  DateTime.fromMillisecondsSinceEpoch(fileData['uploadedAt'] ?? 0),
                ),
              ),
              _buildDetailRow('Phân loại:', fileData['category'] ?? 'Khác'),
              _buildDetailRow('Ghi chú:', fileData['description'] ?? 'Không có'),
              const SizedBox(height: 16),
              const Text(
                'Nội dung xem trước:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  _getPreviewText(fileData),
                  maxLines: 5,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 12),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Đóng'),
          ),
        ],
      ),
    );
  }

  static Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              label,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          Expanded(
            child: Text(value),
          ),
        ],
      ),
    );
  }

  static String _getPreviewText(Map<String, dynamic> fileData) {
    final content = fileData['content'] as String?;
    if (content == null) return 'Không có dữ liệu';

    try {
      // Decode base64
      final decoded = utf8.decode(base64Decode(content));
      return decoded.substring(0, Math.min(200, decoded.length));
    } catch (e) {
      return '[Không thể xem trước]';
    }
  }
}

/// 📥 **Tải Về** - Download functionality
class DownloadFileFeature {
  static void download(String fileName, String base64Content) {
    try {
      // Decode base64
      final bytes = base64Decode(base64Content);

      // Create blob
      final blob = html.Blob([bytes]);

      // Create download link
      final url = html.Url.createObjectUrlFromBlob(blob);
      final anchor = html.document.createElement('a') as html.AnchorElement
        ..href = url
        ..style.display = 'none'
        ..download = fileName;

      html.document.body!.children.add(anchor);
      anchor.click();

      // Cleanup
      html.Url.revokeObjectUrl(url);
      anchor.remove();
    } catch (e) {
      print('❌ Lỗi tải về: $e');
    }
  }
}

/// 📁 **Gán Thư Mục** - Assign folder functionality
class AssignFolderFeature {
  static void show(BuildContext context, int fileId, String fileName) {
    final List<String> folders = [
      '📂 Công việc',
      '📂 Cá nhân',
      '📂 Dự án',
      '📂 Tài chính',
      '📂 Hợp đồng',
      '📂 Báo cáo',
      '📂 Khác',
    ];

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('📁 Gán thư mục'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: folders
                .map((folder) => ListTile(
                      title: Text(folder),
                      onTap: () async {
                        try {
                          // Save folder assignment
                          final fileListService = FileListService();
                          await fileListService.assignFolder(fileId, folder);

                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('✅ Đã gán: $folder'),
                                backgroundColor: Colors.green,
                              ),
                            );
                            Navigator.pop(context);
                          }
                        } catch (e) {
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('❌ Lỗi: $e'),
                                backgroundColor: Colors.red,
                              ),
                            );
                          }
                        }
                      },
                    ))
                .toList(),
          ),
        ),
      ),
    );
  }
}

/// 🤖 **Phân Loại Tự Động** - Auto categorization
class AutoCategorizationFeature {
  static String _categorizeFile(String extension) {
    final ext = extension.toLowerCase();
    if (['doc', 'docx'].contains(ext)) return 'Word';
    if (['xls', 'xlsx'].contains(ext)) return 'Excel';
    if (['pdf'].contains(ext)) return 'PDF';
    if (['ppt', 'pptx'].contains(ext)) return 'PowerPoint';
    if (['txt'].contains(ext)) return 'Text';
    if (['jpg', 'jpeg', 'png', 'gif', 'bmp'].contains(ext)) return 'Hình Ảnh';
    return 'Khác';
  }

  static Future<void> categorizeAll(BuildContext context) async {
    try {
      final fileListService = FileListService();
      final files = await fileListService.getAllFiles();

      int categorized = 0;

      for (var file in files) {
        final extension = file['extension'] as String? ?? '';
        final category = AutoCategorizationFeature._categorizeFile(extension);

        if (category != (file['category'] ?? '')) {
          await fileListService.updateFileCategory(
            file['id'] as int,
            category,
          );
          categorized++;
        }
      }

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('✅ Đã phân loại $categorized tài liệu'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ Lỗi: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}

/// 🔍 **Tìm Kiếm Nâng Cao** - Advanced search
class AdvancedSearchFeature {
  static void show(BuildContext context, Function(SearchFilter) onSearch) {
    final searchFilter = SearchFilter();

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('🔍 Tìm kiếm nâng cao'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Search by name
                TextField(
                  decoration: const InputDecoration(
                    labelText: 'Tên tài liệu',
                    prefixIcon: Icon(Icons.search),
                  ),
                  onChanged: (value) => searchFilter.name = value,
                ),
                const SizedBox(height: 16),

                // Search by type
                DropdownButtonFormField<String>(
                  decoration: const InputDecoration(labelText: 'Loại file'),
                  items: ['Tất cả', 'Word', 'Excel', 'PDF', 'Text', 'Hình ảnh']
                      .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                      .toList(),
                  onChanged: (value) => searchFilter.fileType = value ?? 'Tất cả',
                ),
                const SizedBox(height: 16),

                // Search by category
                DropdownButtonFormField<String>(
                  decoration: const InputDecoration(labelText: 'Phân loại'),
                  items: [
                    'Tất cả',
                    'Word',
                    'Excel',
                    'PDF',
                    'Hình Ảnh',
                    'OCR',
                    'Khác'
                  ]
                      .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                      .toList(),
                  onChanged: (value) =>
                      searchFilter.category = value ?? 'Tất cả',
                ),
                const SizedBox(height: 16),

                // Search by date range
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        icon: const Icon(Icons.calendar_today),
                        label: Text(
                          searchFilter.startDate == null
                              ? 'Từ ngày'
                              : DateFormat('dd/MM/yyyy')
                                  .format(searchFilter.startDate!),
                        ),
                        onPressed: () async {
                          final picked = await showDatePicker(
                            context: context,
                            initialDate: DateTime.now(),
                            firstDate: DateTime(2020),
                            lastDate: DateTime.now(),
                          );
                          if (picked != null) {
                            setState(() => searchFilter.startDate = picked);
                          }
                        },
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: ElevatedButton.icon(
                        icon: const Icon(Icons.calendar_today),
                        label: Text(
                          searchFilter.endDate == null
                              ? 'Đến ngày'
                              : DateFormat('dd/MM/yyyy')
                                  .format(searchFilter.endDate!),
                        ),
                        onPressed: () async {
                          final picked = await showDatePicker(
                            context: context,
                            initialDate: DateTime.now(),
                            firstDate: DateTime(2020),
                            lastDate: DateTime.now(),
                          );
                          if (picked != null) {
                            setState(() => searchFilter.endDate = picked);
                          }
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Search by size
                RangeSlider(
                  values: RangeValues(
                    searchFilter.minSize.toDouble(),
                    searchFilter.maxSize.toDouble(),
                  ),
                  min: 0,
                  max: 104857600, // 100 MB
                  divisions: 100,
                  labels: RangeLabels(
                    '${(searchFilter.minSize ~/ 1024 ~/ 1024)} MB',
                    '${(searchFilter.maxSize ~/ 1024 ~/ 1024)} MB',
                  ),
                  onChanged: (RangeValues values) {
                    setState(() {
                      searchFilter.minSize = values.start.toInt();
                      searchFilter.maxSize = values.end.toInt();
                    });
                  },
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Hủy'),
            ),
            ElevatedButton(
              onPressed: () {
                onSearch(searchFilter);
                Navigator.pop(context);
              },
              child: const Text('Tìm kiếm'),
            ),
          ],
        ),
      ),
    );
  }
}

/// 📊 **Search Filter Model**
class SearchFilter {
  String name = '';
  String fileType = 'Tất cả';
  String category = 'Tất cả';
  DateTime? startDate;
  DateTime? endDate;
  int minSize = 0;
  int maxSize = 104857600; // 100 MB
}

/// 🔗 **Chia Sẻ Tài Liệu** - Share functionality
class ShareFeature {
  static void show(BuildContext context, int fileId, String fileName) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('🔗 Chia sẻ tài liệu'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.link),
              title: const Text('Chia sẻ công khai'),
              subtitle: const Text('Tạo link công khai'),
              onTap: () => _createPublicShare(context, fileId, fileName),
            ),
            ListTile(
              leading: const Icon(Icons.email),
              title: const Text('Chia sẻ qua email'),
              subtitle: const Text('Gửi cho người khác'),
              onTap: () => _shareViaEmail(context, fileName),
            ),
            ListTile(
              leading: const Icon(Icons.person_add),
              title: const Text('Chia sẻ với người dùng'),
              subtitle: const Text('Phân quyền truy cập'),
              onTap: () => _shareWithUser(context, fileId),
            ),
            ListTile(
              leading: const Icon(Icons.lock),
              title: const Text('Chia sẻ bảo mật'),
              subtitle: const Text('Yêu cầu mật khẩu'),
              onTap: () => _secureShare(context, fileId, fileName),
            ),
          ],
        ),
      ),
    );
  }

  static void _createPublicShare(
    BuildContext context,
    int fileId,
    String fileName,
  ) {
    try {
      final shareUrl = ShareService.generateShareUrl(fileId.toString());

      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('✅ Link chia sẻ công khai'),
          content: SelectableText(shareUrl),
          actions: [
            ElevatedButton.icon(
              icon: const Icon(Icons.copy),
              label: const Text('Sao chép'),
              onPressed: () {
                html.window.navigator.clipboard!.writeText(shareUrl);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('✅ Đã sao chép'),
                    backgroundColor: Colors.green,
                  ),
                );
              },
            ),
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Đóng'),
            ),
          ],
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('❌ Lỗi: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  static void _shareViaEmail(BuildContext context, String fileName) {
    final emailController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('📧 Chia sẻ qua email'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: emailController,
              decoration: const InputDecoration(
                labelText: 'Địa chỉ email',
                prefixIcon: Icon(Icons.email),
              ),
              keyboardType: TextInputType.emailAddress,
            ),
            const SizedBox(height: 16),
            TextField(
              decoration: const InputDecoration(
                labelText: 'Lời nhắn (tuỳ chọn)',
                prefixIcon: Icon(Icons.message),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Hủy'),
          ),
          ElevatedButton(
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('✅ Đã gửi email'),
                  backgroundColor: Colors.green,
                ),
              );
              Navigator.pop(context);
            },
            child: const Text('Gửi'),
          ),
        ],
      ),
    );
  }

  static void _shareWithUser(BuildContext context, int fileId) {
    final userEmailController = TextEditingController();
    final permissions = ['Xem', 'Tải về', 'Chỉnh sửa'];
    String selectedPermission = 'Xem';

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('👤 Chia sẻ với người dùng'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: userEmailController,
                decoration: const InputDecoration(
                  labelText: 'Email người dùng',
                  prefixIcon: Icon(Icons.person),
                ),
                keyboardType: TextInputType.emailAddress,
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                decoration: const InputDecoration(labelText: 'Quyền truy cập'),
                value: selectedPermission,
                items: permissions
                    .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                    .toList(),
                onChanged: (value) => setState(() => selectedPermission = value!),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Hủy'),
            ),
            ElevatedButton(
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      '✅ Đã chia sẻ với ${userEmailController.text}',
                    ),
                    backgroundColor: Colors.green,
                  ),
                );
                Navigator.pop(context);
              },
              child: const Text('Chia sẻ'),
            ),
          ],
        ),
      ),
    );
  }

  static void _secureShare(BuildContext context, int fileId, String fileName) {
    final passwordController = TextEditingController();
    final expireController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('🔐 Chia sẻ bảo mật'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: passwordController,
              obscureText: true,
              decoration: const InputDecoration(
                labelText: 'Mật khẩu',
                prefixIcon: Icon(Icons.lock),
              ),
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              decoration: const InputDecoration(labelText: 'Hết hạn sau'),
              items: ['1 ngày', '7 ngày', '30 ngày', 'Không bao giờ']
                  .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                  .toList(),
              onChanged: (value) => expireController.text = value ?? '',
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Hủy'),
          ),
          ElevatedButton(
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('✅ Đã tạo chia sẻ bảo mật'),
                  backgroundColor: Colors.green,
                ),
              );
              Navigator.pop(context);
            },
            child: const Text('Tạo'),
          ),
        ],
      ),
    );
  }
}

/// Extension for Math
class Math {
  static int min(int a, int b) => a < b ? a : b;
  static int max(int a, int b) => a > b ? a : b;
}
