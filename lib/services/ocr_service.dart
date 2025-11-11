import 'package:google_ml_kit/google_ml_kit.dart';
import 'dart:io';
import 'package:image/image.dart' as img;
import 'dart:typed_data';
import 'package:image_picker/image_picker.dart';

/// Service xử lý OCR (Optical Character Recognition)
class OCRService {
  final _textRecognizer = GoogleMlKit.vision.textRecognizer(
    script: TextRecognitionScript.latin, // Hỗ trợ tiếng Việt
  );

  final _imagePicker = ImagePicker();

  /// Chọn hình ảnh từ camera
  Future<File?> pickImageFromCamera() async {
    try {
      final XFile? pickedFile = await _imagePicker.pickImage(
        source: ImageSource.camera,
        imageQuality: 95,
      );
      return pickedFile != null ? File(pickedFile.path) : null;
    } catch (e) {
      throw 'Lỗi chụp ảnh: ${e.toString()}';
    }
  }

  /// Chọn hình ảnh từ thư viện
  Future<File?> pickImageFromGallery() async {
    try {
      final XFile? pickedFile = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 95,
      );
      return pickedFile != null ? File(pickedFile.path) : null;
    } catch (e) {
      throw 'Lỗi chọn ảnh: ${e.toString()}';
    }
  }

  /// Recognizing text từ hình ảnh (alias để match scan_screen)
  Future<String> recognizeTextFromImage(File imageFile) async {
    return extractTextFromImage(imageFile.path);
  }

  /// Quét text từ file ảnh
  Future<String> extractTextFromImage(String imagePath) async {
    try {
      final inputImage = InputImage.fromFilePath(imagePath);
      final recognizedText = await _textRecognizer.processImage(inputImage);

      // Lấy tất cả text blocks
      String extractedText = '';
      for (final textBlock in recognizedText.blocks) {
        for (final line in textBlock.lines) {
          extractedText += '${line.text}\n';
        }
      }

      return extractedText.trim();
    } catch (e) {
      throw 'Lỗi OCR: ${e.toString()}';
    }
  }

  /// Quét text từ bytes ảnh
  Future<String> extractTextFromBytes(Uint8List imageBytes) async {
    try {
      // Lưu bytes tạm thời vào file
      final tempDir = Directory.systemTemp;
      final tempFile = File('${tempDir.path}/ocr_temp_${DateTime.now().millisecondsSinceEpoch}.jpg');
      await tempFile.writeAsBytes(imageBytes);

      // Quét OCR
      final text = await extractTextFromImage(tempFile.path);

      // Xóa file tạm
      if (await tempFile.exists()) {
        await tempFile.delete();
      }

      return text;
    } catch (e) {
      throw 'Lỗi xử lý ảnh: ${e.toString()}';
    }
  }

  /// Cải thiện chất lượng ảnh trước OCR (Tăng độ sáng, contrast)
  Future<Uint8List?> preprocessImage(Uint8List imageBytes) async {
    try {
      // Decode ảnh
      img.Image? image = img.decodeImage(imageBytes);
      if (image == null) return null;

      // Tăng độ sáng
      img.Image brightened = img.adjustColor(
        image,
        brightness: 1.2, // Tăng 20%
        contrast: 1.3,   // Tăng contrast
        saturation: 1.0,
      );

      // Convert to grayscale để tốt hơn với OCR
      img.Image grayscale = img.grayscale(brightened);

      // Encode lại
      return Uint8List.fromList(img.encodeJpg(grayscale, quality: 95));
    } catch (e) {
      // Nếu fail, trả về original
      return imageBytes;
    }
  }

  /// Quét multiple trang (cho PDF ảnh)
  Future<List<String>> extractTextFromMultipleImages(
    List<String> imagePaths,
  ) async {
    final results = <String>[];

    for (final imagePath in imagePaths) {
      try {
        final text = await extractTextFromImage(imagePath);
        results.add(text);
      } catch (e) {
        results.add('Lỗi trang: ${e.toString()}');
      }
    }

    return results;
  }

  /// Cleanup
  Future<void> dispose() async {
    await _textRecognizer.close();
  }

  /// Kiểm tra xem text có chứa Vietnamese không
  static bool containsVietnamese(String text) {
    final vietnameseRegex = RegExp(r'[àáảãạăằắẳẵặâầấẩẫậèéẻẽẹêềếểễệìíỉĩịòóỏõọôồốổỗộơờớởỡợùúủũụưừứửữựỳýỷỹỵđ]', caseSensitive: false);
    return vietnameseRegex.hasMatch(text);
  }

  /// Clean text - remove extra spaces và newlines
  static String cleanText(String text) {
    // Remove multiple spaces
    text = text.replaceAll(RegExp(r' +'), ' ');
    // Remove multiple newlines
    text = text.replaceAll(RegExp(r'\n\n+'), '\n');
    // Trim
    return text.trim();
  }

  /// Format OCR result cho lưu trữ
  static Map<String, dynamic> formatOCRResult({
    required String rawText,
    required String imageName,
    required DateTime scannedAt,
    String? imagePreview,
  }) {
    return {
      'originalFileName': imageName,
      'scannedAt': scannedAt.toIso8601String(),
      'rawText': rawText,
      'cleanText': cleanText(rawText),
      'wordCount': rawText.split(RegExp(r'\s+')).length,
      'language': containsVietnamese(rawText) ? 'vi' : 'en',
      'imagePreview': imagePreview, // Base64 thumbnail
      'searchable': true,
    };
  }
}
