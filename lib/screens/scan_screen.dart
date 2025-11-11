import 'package:flutter/material.dart';
import 'dart:convert';
import '../services/ocr_service.dart';
import '../services/file_list_service.dart';

class ScanScreen extends StatefulWidget {
  const ScanScreen({super.key});

  @override
  State<ScanScreen> createState() => _ScanScreenState();
}

class _ScanScreenState extends State<ScanScreen> with TickerProviderStateMixin {
  bool isScanning = false;
  String resultText = "Sẵn sàng quét tài liệu";
  late AnimationController _scanAnimationController;
  late AnimationController _resultAnimationController;
  late Animation<double> _scanLineAnimation;
  late Animation<double> _resultSlideAnimation;
  late Animation<double> _resultOpacityAnimation;
  
  late OCRService _ocrService;
  late FileListService _fileListService;
  String extractedText = "";

  @override
  void initState() {
    super.initState();
    _ocrService = OCRService();
    _fileListService = FileListService.instance;
    _setupAnimations();
  }

  void _setupAnimations() {
    _scanAnimationController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    )..repeat(reverse: true);

    _scanLineAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(_scanAnimationController);

    _resultAnimationController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );

    _resultSlideAnimation = Tween<double>(begin: 50.0, end: 0.0).animate(
      CurvedAnimation(
        parent: _resultAnimationController,
        curve: Curves.easeOut,
      ),
    );

    _resultOpacityAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _resultAnimationController, curve: Curves.easeIn),
    );
  }

  /// Quét từ camera
  void _startCameraScan() async {
    try {
      setState(() {
        isScanning = true;
        resultText = "Đang quét từ camera...";
      });

      _scanAnimationController.repeat(reverse: true);

      final imageFile = await _ocrService.pickImageFromCamera();
      if (imageFile == null) {
        setState(() {
          isScanning = false;
          resultText = "Hủy quét";
        });
        return;
      }

      // OCR
      extractedText = await _ocrService.recognizeTextFromImage(imageFile);

      setState(() {
        isScanning = false;
        resultText = "✅ Quét thành công!";
      });

      _scanAnimationController.stop();
      _resultAnimationController.forward();

      if (mounted) {
        _showSaveDialog(imageFile.path.split('/').last, extractedText);
      }
    } catch (e) {
      setState(() {
        isScanning = false;
        resultText = "❌ Lỗi: ${e.toString()}";
      });
      _scanAnimationController.stop();
    }
  }

  /// Quét từ thư viện
  void _startGalleryScan() async {
    try {
      setState(() {
        isScanning = true;
        resultText = "Chọn ảnh từ thư viện...";
      });

      _scanAnimationController.repeat(reverse: true);

      final imageFile = await _ocrService.pickImageFromGallery();
      if (imageFile == null) {
        setState(() {
          isScanning = false;
          resultText = "Hủy quét";
        });
        return;
      }

      // OCR
      extractedText = await _ocrService.recognizeTextFromImage(imageFile);

      setState(() {
        isScanning = false;
        resultText = "✅ Quét thành công!";
      });

      _scanAnimationController.stop();
      _resultAnimationController.forward();

      if (mounted) {
        _showSaveDialog(imageFile.path.split('/').last, extractedText);
      }
    } catch (e) {
      setState(() {
        isScanning = false;
        resultText = "❌ Lỗi: ${e.toString()}";
      });
      _scanAnimationController.stop();
    }
  }

  /// Dialog để lưu kết quả OCR
  void _showSaveDialog(String fileName, String text) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Lưu kết quả quét"),
        content: SizedBox(
          width: MediaQuery.of(context).size.width * 0.8,
          height: 300,
          child: Column(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  child: Text(
                    text,
                    style: const TextStyle(fontSize: 14),
                  ),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Hủy"),
          ),
          ElevatedButton(
            onPressed: () async {
              try {
                // Lưu dưới dạng file TXT
                String txtFileName =
                    "${DateTime.now().millisecondsSinceEpoch}_ocr.txt";
                List<int> textBytes = text.codeUnits.cast<int>();
                String base64Content = base64Encode(textBytes);

                await _fileListService.addFile(
                  name: txtFileName,
                  extension: "txt",
                  content: base64Content,
                  category: "Text",
                  size: textBytes.length,
                );

                if (mounted) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text("✅ Lưu OCR thành công!"),
                      backgroundColor: Colors.green,
                    ),
                  );
                }
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text("❌ Lỗi lưu: $e"),
                    backgroundColor: Colors.red,
                  ),
                );
              }
            },
            child: const Text("Lưu"),
          ),
        ],
      ),
    );
  }


  @override
  void dispose() {
    _scanAnimationController.dispose();
    _resultAnimationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    final scanAreaHeight = screenHeight * 0.4;

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        title: const Text(
          "Quét tài liệu",
          style: TextStyle(
            color: Colors.white,
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: Container(
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
        child: SafeArea(
          child: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                children: [
                  const SizedBox(height: 20),
                  _buildScanArea(scanAreaHeight),
                  const SizedBox(height: 20),
                  _buildResultArea(),
                  const SizedBox(height: 20),
                  _buildActionButtons(),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildScanArea(double height) {
    return Container(
      height: height,
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withOpacity(0.3), width: 2),
      ),
      child: Stack(
        children: [
          Center(
            child: Icon(
              Icons.document_scanner,
              size: height * 0.25,
              color: Colors.white.withOpacity(0.3),
            ),
          ),
          if (isScanning)
            AnimatedBuilder(
              animation: _scanLineAnimation,
              builder: (context, child) {
                return Positioned(
                  left: 0,
                  right: 0,
                  top: _scanLineAnimation.value * (height - 20),
                  child: Container(height: 2, color: const Color(0xFFF15A24)),
                );
              },
            ),
          ..._buildCornerMarkers(),
        ],
      ),
    );
  }

  List<Widget> _buildCornerMarkers() {
    return [
      Positioned(top: 20, left: 20, child: _buildCornerMarker()),
      Positioned(top: 20, right: 20, child: _buildCornerMarker(isRight: true)),
      Positioned(
        bottom: 20,
        left: 20,
        child: _buildCornerMarker(isBottom: true),
      ),
      Positioned(
        bottom: 20,
        right: 20,
        child: _buildCornerMarker(isRight: true, isBottom: true),
      ),
    ];
  }

  Widget _buildCornerMarker({bool isRight = false, bool isBottom = false}) {
    return Container(
      width: 20,
      height: 20,
      decoration: BoxDecoration(
        border: Border(
          top: BorderSide(color: Colors.white.withOpacity(0.8), width: 3),
          left: BorderSide(color: Colors.white.withOpacity(0.8), width: 3),
          right: isRight
              ? BorderSide(color: Colors.white.withOpacity(0.8), width: 3)
              : BorderSide.none,
          bottom: isBottom
              ? BorderSide(color: Colors.white.withOpacity(0.8), width: 3)
              : BorderSide.none,
        ),
      ),
    );
  }

  Widget _buildResultArea() {
    return AnimatedBuilder(
      animation: _resultAnimationController,
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(0, _resultSlideAnimation.value),
          child: Opacity(
            opacity: _resultOpacityAnimation.value,
            child: Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.1),
                borderRadius: BorderRadius.circular(15),
              ),
              child: Column(
                children: [
                  Text(
                    resultText,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      height: 1.5,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  if (!isScanning && resultText.contains("thành công"))
                    Padding(
                      padding: const EdgeInsets.only(top: 20),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          _buildActionButton(
                            Icons.edit,
                            "Chỉnh sửa",
                            onTap: () {},
                          ),
                          _buildActionButton(
                            Icons.save_alt,
                            "Lưu",
                            onTap: () {},
                          ),
                          _buildActionButton(
                            Icons.share,
                            "Chia sẻ",
                            onTap: () {},
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildActionButton(
    IconData icon,
    String label, {
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: Colors.white, size: 24),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: TextStyle(
              color: Colors.white.withOpacity(0.9),
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons() {
    return Column(
      children: [
        // Camera button
        ElevatedButton(
          onPressed: isScanning ? null : _startCameraScan,
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFFF15A24),
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            elevation: 4,
            minimumSize: const Size(double.infinity, 50),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                isScanning ? Icons.hourglass_empty : Icons.photo_camera,
                size: 24,
              ),
              const SizedBox(width: 8),
              Text(
                isScanning ? "Đang quét..." : "📷 Chụp ảnh",
                style:
                    const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        // Gallery button
        ElevatedButton(
          onPressed: isScanning ? null : _startGalleryScan,
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.white.withOpacity(0.2),
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            elevation: 2,
            minimumSize: const Size(double.infinity, 50),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                isScanning ? Icons.hourglass_empty : Icons.photo_library,
                size: 24,
              ),
              const SizedBox(width: 8),
              Text(
                isScanning ? "Đang quét..." : "🖼️ Chọn từ thư viện",
                style:
                    const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

