import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'dart:convert';
import 'dart:typed_data';
import 'dart:html' as html;
import '../services/file_list_service.dart';
import '../services/share_service.dart';
import 'package:pdfx/pdfx.dart';
import 'package:archive/archive.dart';

class DocumentScreen extends StatefulWidget {
  const DocumentScreen({super.key});

  @override
  State<DocumentScreen> createState() => _DocumentScreenState();
}

class _DocumentScreenState extends State<DocumentScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  late FileListService _fileListService;

  final _searchController = TextEditingController();
  // Map friendly names to extensions
  final _fileTypeMap = {
    'Tất cả': '',
    'Word': 'docx',
    'Excel': 'xlsx',
    'PowerPoint': 'pptx',
    'PDF': 'pdf',
    'Text': 'txt',
  };
  late List<String> _fileTypeOptions;

  String _selectedFileType = 'Tất cả';
  String _selectedCategory = ''; // Empty string means "Tất cả"
  DateTime? _startDate;
  DateTime? _endDate;

  // Define categories with colors and icons
  final _categories = [
    {
      'id': '',
      'label': 'Tất cả',
      'icon': Icons.folder_open,
      'color': Colors.grey,
    },
    {
      'id': 'word',
      'label': 'Word',
      'icon': Icons.description,
      'color': Colors.blue,
    },
    {
      'id': 'excel',
      'label': 'Excel',
      'icon': Icons.table_chart,
      'color': Colors.green,
    },
    {
      'id': 'pdf',
      'label': 'PDF',
      'icon': Icons.picture_as_pdf,
      'color': Colors.red,
    },
    {
      'id': 'powerpoint',
      'label': 'PowerPoint',
      'icon': Icons.slideshow,
      'color': Colors.orange,
    },
    {
      'id': 'text',
      'label': 'Text',
      'icon': Icons.text_fields,
      'color': Colors.indigo,
    },
    {
      'id': 'images',
      'label': 'Hình Ảnh',
      'icon': Icons.image,
      'color': Colors.pink,
    },
    {
      'id': 'ocr',
      'label': 'OCR',
      'icon': Icons.document_scanner,
      'color': Colors.purple,
    },
    {
      'id': 'other',
      'label': 'Khác',
      'icon': Icons.insert_drive_file,
      'color': Colors.blueGrey,
    },
  ];

  @override
  void initState() {
    super.initState();
    // Initialize file type options from map keys
    _fileTypeOptions = _fileTypeMap.keys.toList();

    // Use singleton instance
    _fileListService = FileListService.instance;

    // Load files from localStorage into stream
    _fileListService.loadFiles();

    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _scaleAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOut),
    );
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _deleteFile(int id) async {
    try {
      await _fileListService.deleteFile(id);
      setState(() {});
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Xóa file thành công'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Lỗi xóa file: $e')));
      }
    }
  }

  /// Filter files based on search criteria
  List<Map<String, dynamic>> _filterFiles(List<Map<String, dynamic>> files) {
    String searchText = _searchController.text.toLowerCase();
    String selectedExtension = _fileTypeMap[_selectedFileType] ?? '';

    return files.where((file) {
      final fileName = (file['name'] as String).toLowerCase();
      final extension = (file['extension'] as String).toLowerCase();
      final uploadedAtValue = file['uploadedAt'];
      final uploadedAt = uploadedAtValue is int 
          ? DateTime.fromMillisecondsSinceEpoch(uploadedAtValue)
          : DateTime.parse(uploadedAtValue as String);
      final category = (file['category'] as String? ?? 'other').toLowerCase();

      // Filter by name
      bool nameMatch = fileName.contains(searchText);

      // Filter by file type
      bool typeMatch =
          _selectedFileType == 'Tất cả' || extension == selectedExtension;

      // Filter by category
      bool categoryMatch = _selectedCategory.isEmpty || category == _selectedCategory.toLowerCase();

      // Filter by date range
      bool dateMatch = true;
      if (_startDate != null && uploadedAt.isBefore(_startDate!)) {
        dateMatch = false;
      }
      if (_endDate != null) {
        final endDateEndOfDay = _endDate!.add(const Duration(days: 1));
        if (uploadedAt.isAfter(endDateEndOfDay)) {
          dateMatch = false;
        }
      }

      return nameMatch && typeMatch && categoryMatch && dateMatch;
    }).toList();
  }

  void _downloadFile(String fileName, String base64Content) {
    try {
      // Decode base64 to bytes
      List<int> decodedBytes = base64Decode(base64Content);

      // Create blob and download
      final blob = html.Blob([Uint8List.fromList(decodedBytes)]);
      final url = html.Url.createObjectUrlFromBlob(blob);

      // Create anchor element and trigger download
      html.window.open(url, fileName);

      // Cleanup
      html.Url.revokeObjectUrl(url);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Tải xuống thành công!'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Lỗi tải xuống: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _openFile(String fileName, String extension, String base64Content) {
    // Check if file type is viewable
    final ext = extension.toLowerCase();
    final isTextFile = ['txt'].contains(ext);
    final isPdf = ['pdf'].contains(ext);
    final isWord = ['doc', 'docx'].contains(ext);
    final isExcel = ['xls', 'xlsx'].contains(ext);

    late String content;
    String? errorMessage;

    if (isTextFile) {
      try {
        List<int> decodedBytes = base64Decode(base64Content);
        content = utf8.decode(decodedBytes);
      } catch (e) {
        errorMessage = 'Không thể đọc file: $e';
      }
    } else if (isPdf) {
      content = base64Content;
    } else if (isWord) {
      try {
        List<int> decodedBytes = base64Decode(base64Content);
        content = _extractWordContent(decodedBytes);
      } catch (e) {
        errorMessage = 'Lỗi đọc file Word: $e';
      }
    } else if (isExcel) {
      try {
        List<int> decodedBytes = base64Decode(base64Content);
        content = _extractExcelContent(decodedBytes);
      } catch (e) {
        errorMessage = 'Lỗi đọc file Excel: $e';
      }
    } else {
      errorMessage = 'File ${ext.toUpperCase()} không được hỗ trợ.';
    }

    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.white,
        insetPadding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.max,
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Icon(
                    _getFileIcon(extension),
                    color: _getFileColor(extension),
                    size: 28,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      fileName,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
            // Content
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (errorMessage != null)
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.orange[50],
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.orange[300]!),
                        ),
                        child: Text(
                          errorMessage,
                          style: TextStyle(
                            color: Colors.orange[800],
                            fontSize: 14,
                          ),
                        ),
                      )
                    else if (isTextFile)
                      SelectableText(
                        content,
                        style: const TextStyle(
                          fontFamily: 'Courier',
                          fontSize: 13,
                          height: 1.5,
                        ),
                      )
                    else if (isPdf)
                      SizedBox(
                        height: 500,
                        width: double.maxFinite,
                        child: _buildPdfViewer(base64Content),
                      )
                    else if (isWord || isExcel)
                      SelectableText(
                        content,
                        style: const TextStyle(
                          fontFamily: 'Courier',
                          fontSize: 13,
                          height: 1.5,
                        ),
                      ),
                  ],
                ),
              ),
            ),
            const Divider(height: 1),
            // Footer
            Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => _downloadFile(fileName, base64Content),
                    child: const Text('Tải xuống'),
                  ),
                  const SizedBox(width: 8),
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Đóng'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Extract text content from Word file (.docx)
  String _extractWordContent(List<int> fileBytes) {
    try {
      final archive = ZipDecoder().decodeBytes(fileBytes);
      final documentXml = archive.findFile('word/document.xml');

      if (documentXml == null) {
        return 'Không thể đọc file Word.';
      }

      final xmlContent = utf8.decode(documentXml.content as List<int>);
      // Simple text extraction - remove XML tags
      return _extractTextFromXml(xmlContent);
    } catch (e) {
      return 'Lỗi: $e';
    }
  }

  /// Extract text content from Excel file (.xlsx)
  String _extractExcelContent(List<int> fileBytes) {
    try {
      final archive = ZipDecoder().decodeBytes(fileBytes);
      final sheet1 = archive.findFile('xl/worksheets/sheet1.xml');

      if (sheet1 == null) {
        return 'Không thể đọc file Excel.';
      }

      final sheetContent = utf8.decode(sheet1.content as List<int>);
      return _extractTextFromXml(sheetContent);
    } catch (e) {
      return 'Lỗi: $e';
    }
  }

  /// Simple XML text extraction
  String _extractTextFromXml(String xmlContent) {
    // Remove XML tags and keep only text
    final textRegex = RegExp(r'>([^<]*)<');
    final matches = textRegex.allMatches(xmlContent);

    final texts = <String>[];
    for (var match in matches) {
      final text = match.group(1)?.trim() ?? '';
      if (text.isNotEmpty && text.length > 1) {
        texts.add(text);
      }
    }

    return texts.join('\n');
  }

  /// Build PDF viewer using pdfx package
  Widget _buildPdfViewer(String base64Content) {
    try {
      // Decode base64 to bytes
      List<int> decodedBytes = base64Decode(base64Content);
      Uint8List pdfBytes = Uint8List.fromList(decodedBytes);

      return _PdfViewerWidget(pdfBytes: pdfBytes);
    } catch (e) {
      return Container(
        decoration: BoxDecoration(
          color: Colors.red[50],
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.red[300]!),
        ),
        child: Center(
          child: Text(
            'Lỗi: Không thể hiển thị PDF\n$e',
            style: TextStyle(color: Colors.red[800], fontSize: 12),
            textAlign: TextAlign.center,
          ),
        ),
      );
    }
  }

  /// Lấy icon dựa trên extension
  IconData _getFileIcon(String extension) {
    final ext = extension.toLowerCase();
    if (['doc', 'docx'].contains(ext)) return Icons.description;
    if (['xls', 'xlsx'].contains(ext)) return Icons.table_chart;
    if (['pdf'].contains(ext)) return Icons.picture_as_pdf;
    if (['ppt', 'pptx'].contains(ext)) return Icons.slideshow;
    if (['txt'].contains(ext)) return Icons.text_fields;
    return Icons.insert_drive_file;
  }

  /// Lấy màu dựa trên extension
  Color _getFileColor(String extension) {
    final ext = extension.toLowerCase();
    if (['doc', 'docx'].contains(ext)) return Colors.blue;
    if (['xls', 'xlsx'].contains(ext)) return Colors.green;
    if (['pdf'].contains(ext)) return Colors.red;
    if (['ppt', 'pptx'].contains(ext)) return Colors.orange;
    if (['txt'].contains(ext)) return Colors.grey;
    return Colors.blueGrey;
  }

  String _getCategoryLabel(String category) {
    const categoryLabels = {
      'word': 'Word',
      'excel': 'Excel',
      'pdf': 'PDF',
      'powerpoint': 'PowerPoint',
      'text': 'Text',
      'images': 'Hình Ảnh',
      'ocr': 'OCR',
      'other': 'Khác',
    };
    return categoryLabels[category.toLowerCase()] ?? category;
  }

  void _showShareDialog(int fileId, String fileName) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Chia sẻ tài liệu'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Tải liệu: $fileName',
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 16),
            const Text('Chọn cách chia sẻ:'),
            const SizedBox(height: 12),
            ListTile(
              title: const Text('Chia sẻ công khai'),
              subtitle: const Text('Bất kỳ ai có link đều có thể truy cập'),
              trailing: const Icon(Icons.public),
              onTap: () {
                _createPublicShare(fileId, fileName);
                Navigator.pop(context);
              },
            ),
            ListTile(
              title: const Text('Copy link chia sẻ'),
              subtitle: const Text('Sao chép đường dẫn để chia sẻ'),
              trailing: const Icon(Icons.copy),
              onTap: () {
                final shareKey = ShareService.generateShareLink(fileId, fileName);
                final shareUrl = ShareService.generateShareUrl(shareKey);
                
                // Copy to clipboard
                html.window.navigator.clipboard?.writeText(shareUrl);
                
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Đã sao chép: $shareUrl'),
                    backgroundColor: Colors.green,
                  ),
                );
                Navigator.pop(context);
              },
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Hủy'),
          ),
        ],
      ),
    );
  }

  void _createPublicShare(int fileId, String fileName) {
    final shareRecord = ShareService.createPublicShare(
      fileId,
      fileName,
      'current_user', // In real app, get from FirebaseAuth.currentUser?.uid
      {
        'canView': true,
        'canDownload': true,
        'canShare': false,
      },
    );

    final shareUrl = ShareService.generateShareUrl(
      shareRecord['shareKey'] as String,
    );

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Link chia sẻ: $shareUrl'),
        backgroundColor: Colors.green,
        duration: const Duration(seconds: 5),
        action: SnackBarAction(
          label: 'Sao chép',
          onPressed: () {
            html.window.navigator.clipboard?.writeText(shareUrl);
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [
            const Color(0xFF1B3B8B),
            const Color(0xFF1B3B8B),
            const Color(0xFFF15A24),
            const Color(0xFFF15A24),
          ],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
      ),
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Tài Liệu Của Tôi',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 16),
                // Search box
                TextField(
                  controller: _searchController,
                  onChanged: (value) {
                    setState(() {});
                  },
                  decoration: InputDecoration(
                    hintText: 'Tìm kiếm tài liệu...',
                    prefixIcon: const Icon(Icons.search),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    filled: true,
                    fillColor: Colors.white,
                  ),
                ),
                const SizedBox(height: 20),
                // Categories section
                Text(
                  'Loại Tài Liệu',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Colors.white.withOpacity(0.9),
                  ),
                ),
                const SizedBox(height: 12),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: _categories.map((category) {
                      final isSelected = _selectedCategory == category['id'];
                      final color = category['color'] as Color;
                      return Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: GestureDetector(
                          onTap: () {
                            setState(() {
                              _selectedCategory = category['id'] as String;
                            });
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 8,
                            ),
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? color
                                  : color.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: isSelected
                                    ? Colors.white
                                    : color.withOpacity(0.5),
                                width: isSelected ? 2 : 1,
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  category['icon'] as IconData,
                                  size: 16,
                                  color: isSelected
                                      ? Colors.white
                                      : color,
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  category['label'] as String,
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w500,
                                    color: isSelected
                                        ? Colors.white
                                        : color,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ),
                const SizedBox(height: 20),
                // Filter UI
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.white.withOpacity(0.2)),
                  ),
                  child: Column(
                    children: [
                      // File type filter
                      DropdownButtonFormField<String>(
                        value: _selectedFileType,
                        items: _fileTypeOptions
                            .map(
                              (type) => DropdownMenuItem(
                                value: type,
                                child: Text(type),
                              ),
                            )
                            .toList(),
                        onChanged: (value) {
                          setState(() {
                            _selectedFileType = value ?? 'Tất cả';
                          });
                        },
                        decoration: InputDecoration(
                          labelText: 'Loại file',
                          labelStyle: const TextStyle(color: Colors.white),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: BorderSide(
                              color: Colors.white.withOpacity(0.3),
                            ),
                          ),
                          filled: true,
                          fillColor: Colors.white.withOpacity(0.05),
                        ),
                        dropdownColor: const Color(0xFF1e3c72),
                        style: const TextStyle(color: Colors.white),
                      ),
                      const SizedBox(height: 12),
                      // Date range filter
                      Row(
                        children: [
                          Expanded(
                            child: InkWell(
                              onTap: () async {
                                final picked = await showDatePicker(
                                  context: context,
                                  initialDate: _startDate ?? DateTime.now(),
                                  firstDate: DateTime(2020),
                                  lastDate: DateTime.now(),
                                );
                                if (picked != null && mounted) {
                                  setState(() {
                                    _startDate = picked;
                                  });
                                }
                              },
                              child: InputDecorator(
                                decoration: InputDecoration(
                                  labelText: 'Từ ngày',
                                  labelStyle: const TextStyle(
                                    color: Colors.white,
                                  ),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  enabledBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(8),
                                    borderSide: BorderSide(
                                      color: Colors.white.withOpacity(0.3),
                                    ),
                                  ),
                                  filled: true,
                                  fillColor: Colors.white.withOpacity(0.05),
                                  suffixIcon: const Icon(
                                    Icons.calendar_today,
                                    color: Colors.white,
                                  ),
                                ),
                                child: Text(
                                  _startDate != null
                                      ? DateFormat(
                                          'dd/MM/yyyy',
                                        ).format(_startDate!)
                                      : 'Chọn ngày bắt đầu',
                                  style: TextStyle(
                                    color: _startDate != null
                                        ? Colors.white
                                        : Colors.white.withOpacity(0.5),
                                  ),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: InkWell(
                              onTap: () async {
                                final picked = await showDatePicker(
                                  context: context,
                                  initialDate: _endDate ?? DateTime.now(),
                                  firstDate: DateTime(2020),
                                  lastDate: DateTime.now(),
                                );
                                if (picked != null && mounted) {
                                  setState(() {
                                    _endDate = picked;
                                  });
                                }
                              },
                              child: InputDecorator(
                                decoration: InputDecoration(
                                  labelText: 'Đến ngày',
                                  labelStyle: const TextStyle(
                                    color: Colors.white,
                                  ),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  enabledBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(8),
                                    borderSide: BorderSide(
                                      color: Colors.white.withOpacity(0.3),
                                    ),
                                  ),
                                  filled: true,
                                  fillColor: Colors.white.withOpacity(0.05),
                                  suffixIcon: const Icon(
                                    Icons.calendar_today,
                                    color: Colors.white,
                                  ),
                                ),
                                child: Text(
                                  _endDate != null
                                      ? DateFormat(
                                          'dd/MM/yyyy',
                                        ).format(_endDate!)
                                      : 'Chọn ngày kết thúc',
                                  style: TextStyle(
                                    color: _endDate != null
                                        ? Colors.white
                                        : Colors.white.withOpacity(0.5),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      // Reset filters button
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: () {
                            setState(() {
                              _selectedFileType = 'Tất cả';
                              _selectedCategory = '';
                              _startDate = null;
                              _endDate = null;
                              _searchController.clear();
                            });
                          },
                          icon: const Icon(Icons.refresh),
                          label: const Text('Xóa bộ lọc'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.white.withOpacity(0.2),
                            foregroundColor: Colors.white,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                StreamBuilder<List<Map<String, dynamic>>>(
                  stream: _fileListService.filesStream,
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(
                        child: CircularProgressIndicator(
                          valueColor: AlwaysStoppedAnimation(Colors.white),
                        ),
                      );
                    }

                    if (snapshot.hasError) {
                      return Center(
                        child: Text(
                          'Lỗi: ${snapshot.error}',
                          style: const TextStyle(color: Colors.white),
                        ),
                      );
                    }

                    final files = snapshot.data ?? [];
                    final filteredFiles = _filterFiles(files);

                    if (filteredFiles.isEmpty) {
                      return Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.folder_open,
                              size: 64,
                              color: Colors.white.withOpacity(0.5),
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'Chưa có tài liệu nào',
                              style: TextStyle(
                                color: Colors.white.withOpacity(0.7),
                                fontSize: 16,
                              ),
                            ),
                          ],
                        ),
                      );
                    }

                    return ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: filteredFiles.length,
                      itemBuilder: (context, index) {
                        final file = filteredFiles[index];
                        final fileName = file['name'] as String;
                        final extension = file['extension'] as String;
                        final uploadedAtValue = file['uploadedAt'];
                        final uploadedAt = uploadedAtValue is int 
                            ? DateTime.fromMillisecondsSinceEpoch(uploadedAtValue)
                            : DateTime.parse(uploadedAtValue as String);
                        final id = file['id'] as int;
                        final content = file['content'] as String? ?? '';
                        final category = file['category'] as String? ?? 'other';
                        final ocrText = file['ocrText'] as String?;

                        final uploadDate = uploadedAt.toLocal();
                        final formattedDate = DateFormat(
                          'dd/MM/yyyy HH:mm',
                        ).format(uploadDate);

                        return ScaleTransition(
                          scale: _scaleAnimation,
                          child: Container(
                            margin: const EdgeInsets.only(bottom: 12),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(12),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.1),
                                  blurRadius: 8,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: ListTile(
                              contentPadding: const EdgeInsets.all(12),
                              onTap: () =>
                                  _openFile(fileName, extension, content),
                              leading: Container(
                                width: 50,
                                height: 50,
                                decoration: BoxDecoration(
                                  color: _getFileColor(
                                    extension,
                                  ).withOpacity(0.2),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Icon(
                                  _getFileIcon(extension),
                                  color: _getFileColor(extension),
                                  size: 28,
                                ),
                              ),
                              title: Text(
                                fileName,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w600,
                                  fontSize: 14,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              subtitle: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Tải lên: $formattedDate',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.grey[600],
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Wrap(
                                    spacing: 8,
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 8,
                                          vertical: 2,
                                        ),
                                        decoration: BoxDecoration(
                                          color: Colors.blue.withOpacity(0.1),
                                          borderRadius:
                                              BorderRadius.circular(4),
                                        ),
                                        child: Text(
                                          _getCategoryLabel(category),
                                          style: const TextStyle(
                                            fontSize: 10,
                                            color: Colors.blue,
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                      ),
                                      if (ocrText != null)
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 8,
                                            vertical: 2,
                                          ),
                                          decoration: BoxDecoration(
                                            color: Colors.green.withOpacity(0.1),
                                            borderRadius:
                                                BorderRadius.circular(4),
                                          ),
                                          child: const Text(
                                            'OCR',
                                            style: TextStyle(
                                              fontSize: 10,
                                              color: Colors.green,
                                              fontWeight: FontWeight.w500,
                                            ),
                                          ),
                                        ),
                                    ],
                                  ),
                                ],
                              ),
                              trailing: PopupMenuButton(
                                onSelected: (value) {
                                  if (value == 'delete') {
                                    _deleteFile(id);
                                  } else if (value == 'download') {
                                    _downloadFile(fileName, content);
                                  } else if (value == 'share') {
                                    _showShareDialog(id, fileName);
                                  }
                                },
                                itemBuilder: (context) => [
                                  const PopupMenuItem(
                                    value: 'download',
                                    child: Text('Tải xuống'),
                                  ),
                                  const PopupMenuItem(
                                    value: 'share',
                                    child: Text('Chia sẻ'),
                                  ),
                                  const PopupMenuItem(
                                    value: 'delete',
                                    child: Text('Xóa'),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        );
                      },
                    );
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Temporary PDF viewer widget
class _PdfViewerWidget extends StatefulWidget {
  final Uint8List pdfBytes;

  const _PdfViewerWidget({required this.pdfBytes});

  @override
  State<_PdfViewerWidget> createState() => _PdfViewerWidgetState();
}

class _PdfViewerWidgetState extends State<_PdfViewerWidget> {
  late PdfControllerPinch _pdfController;

  @override
  void initState() {
    super.initState();
    _pdfController = PdfControllerPinch(
      document: PdfDocument.openData(widget.pdfBytes),
    );
  }

  @override
  void dispose() {
    _pdfController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.grey[900],
        borderRadius: BorderRadius.circular(8),
      ),
      child: PdfViewPinch(controller: _pdfController),
    );
  }
}
