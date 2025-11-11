<h2 align="center">
    <a href="https://dainam.edu.vn/vi/khoa-cong-nghe-thong-tin">
    🎓 Faculty of Information Technology (DaiNam University)
    </a>
</h2>
<h2 align="center">
   ỨNG DỤNG QUẢN LÝ TÀI LIỆU THÔNG MINH
</h2>
<div align="center">
    <p align="center">
        <img src="docs/aiotlab_logo.png" alt="AIoTLab Logo" width="170"/>
        <img src="docs/fitdnu_logo.png" alt="FIT DNU Logo" width="180"/>
        <img src="docs/dnu_logo.png" alt="DaiNam University Logo" width="200"/>
    </p>

[![AIoTLab](https://img.shields.io/badge/AIoTLab-green?style=for-the-badge)](https://www.facebook.com/DNUAIoTLab)
[![Faculty of Information Technology](https://img.shields.io/badge/Faculty%20of%20Information%20Technology-blue?style=for-the-badge)](https://dainam.edu.vn/vi/khoa-cong-nghe-thong-tin)
[![DaiNam University](https://img.shields.io/badge/DaiNam%20University-orange?style=for-the-badge)](https://dainam.edu.vn)

</div>

---

## 1. Giới thiệu hệ thống

Hệ thống **Quản Lý Tài Liệu Thông Minh** được xây dựng bằng Flutter, kết hợp Firebase và Google ML Kit để cung cấp giải pháp quản lý tài liệu toàn diện, hiệu quả và thông minh. Hệ thống tự động phân loại tệp, trích xuất văn bản từ hình ảnh (OCR) và hỗ trợ chia sẻ tài liệu an toàn.

**Các chức năng chính**

Người dùng:
- Đăng ký / Đăng nhập với xác thực Firebase (hỗ trợ đa tài khoản)
- Tải lên tài liệu (hỗ trợ 13+ định dạng tệp)
- Phân loại tệp tự động (8 danh mục: Word, Excel, PDF, Hình ảnh, v.v.)
- Trích xuất văn bản (OCR) từ hình ảnh với hỗ trợ tiếng Việt
- Tìm kiếm toàn văn bản nhanh chóng và chính xác
- Xem chi tiết tài liệu và quản lý metadata
- Tải xuống tài liệu ở định dạng gốc
- Chia sẻ tài liệu an toàn với liên kết độc nhất (SHA256)

Quản trị viên:
- Quản lý người dùng và quyền hạn
- Theo dõi hoạt động tải lên/tải xuống
- Quản lý chia sẻ tài liệu
- Thống kê sử dụng hệ thống

---

## 2. Ngôn ngữ & Công nghệ chính

<div align="center">

[![Flutter](https://img.shields.io/badge/Flutter-3.8+-blue?style=for-the-badge&logo=flutter&logoColor=white)](https://flutter.dev/)
[![Dart](https://img.shields.io/badge/Dart-2.19+-0175C2?style=for-the-badge&logo=dart&logoColor=white)](https://dart.dev/)
[![Firebase Auth](https://img.shields.io/badge/Firebase%20Auth-v13+-FF9800?style=for-the-badge&logo=firebase&logoColor=white)](https://firebase.google.com/docs/auth)
[![Firestore](https://img.shields.io/badge/Firestore-Cloud-orange?style=for-the-badge&logo=firebase&logoColor=white)](https://firebase.google.com/docs/firestore)
[![Google ML Kit](https://img.shields.io/badge/Google%20ML%20Kit-0.15.0-4285F4?style=for-the-badge&logo=google&logoColor=white)](https://developers.google.com/ml-kit)

</div>

| Thành Phần | Công Nghệ | Phiên Bản |
|-----------|----------|---------|
| Frontend | Flutter | 3.8+ |
| Ngôn Ngữ | Dart | 2.19+ |
| Xác Thực | Firebase Auth | v13+ |
| CSDL | Firestore | Latest |
| OCR | Google ML Kit | 0.15.0 |
| File Picker | file_picker | 7.1+ |
| Archive | archive | 3.6.1 |

---

## 3. Cấu trúc dự án

```
lib/
├── screens/
│   ├── login_screen.dart
│   ├── register_screen.dart
│   ├── document_screen.dart
│   ├── scan_screen.dart
│   └── user_page.dart
├── services/
│   ├── auth_service.dart
│   ├── file_list_service.dart
│   ├── category_service.dart
│   ├── ocr_service.dart
│   └── share_service.dart
└── main.dart
```

---

## 4. Các bước cài đặt

**Yêu cầu hệ thống**
- Flutter SDK: 3.8 hoặc cao hơn
- Dart SDK: 2.19 hoặc cao hơn

**Cài đặt**
```bash
# 1. Clone repository
git clone https://github.com/your-repo/quan_ly_van_ban.git
cd quan_ly_van_ban

# 2. Cài đặt dependencies
flutter pub get

# 3. Cấu hình Firebase
flutterfire configure

# 4. Chạy ứng dụng
flutter run -d chrome      # Web
flutter run -d android     # Android
flutter run -d ios         # iOS
```

---

## 5. Liên hệ

- **Sinh viên thực hiện:** **Lương Quốc Diệu**
- **Khoa công nghệ thông tin – Trường Đại học Đại Nam**
- 🌐 Website: [https://dainam.edu.vn/vi/khoa-cong-nghe-thong-tin](https://dainam.edu.vn/vi/khoa-cong-nghe-thong-tin)
- 📧 Email: [luongquocdieu2004@gmail.com](mailto:luongquocdieu2004@gmail.com)
- 📱 Fanpage: [AIoTLab - FIT DNU](https://www.facebook.com/DNUAIoTLab)

© 2025 AIoTLab, Faculty of Information Technology, DaiNam University. All rights reserved.
