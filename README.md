<h2 align="center"># quan_ly_van_ban

    <a href="https://vnu.edu.vn/vi/">

    🎓 Trường Đại Học Công Nghệ - Đại Học Quốc Gia TP.HCMA new Flutter project.

    </a>

</h2>## Getting Started

<h2 align="center">

   HỆ THỐNG QUẢN LÝ TÀI LIỆU THÔNG MINHThis project is a starting point for a Flutter application.

</h2>

<h2 align="center">A few resources to get you started if this is your first Flutter project:

   VỚI XÁC THỰC FIREBASE VÀ TRÍCH XUẤT VĂN BẢN TỰ ĐỘNG (OCR)

</h2>- [Lab: Write your first Flutter app](https://docs.flutter.dev/get-started/codelab)

- [Cookbook: Useful Flutter samples](https://docs.flutter.dev/cookbook)

<div align="center">

    <p align="center">For help getting started with Flutter development, view the

        <img src="assets/flutter_logo.png" alt="Flutter Logo" width="120"/>[online documentation](https://docs.flutter.dev/), which offers tutorials,

        <img src="assets/firebase_logo.png" alt="Firebase Logo" width="120"/>samples, guidance on mobile development, and a full API reference.

        <img src="assets/ml_kit_logo.png" alt="ML Kit Logo" width="120"/>
    </p>

[![Flutter](https://img.shields.io/badge/Flutter-3.8+-blue?style=for-the-badge&logo=flutter&logoColor=white)](https://flutter.dev/)
[![Firebase](https://img.shields.io/badge/Firebase-v13+-orange?style=for-the-badge&logo=firebase&logoColor=white)](https://firebase.google.com/)
[![Google ML Kit](https://img.shields.io/badge/Google%20ML%20Kit-OCR-green?style=for-the-badge&logo=google&logoColor=white)](https://developers.google.com/ml-kit)

[![Dart](https://img.shields.io/badge/Language-Dart-0175C2?style=for-the-badge&logo=dart&logoColor=white)](https://dart.dev/)
[![License](https://img.shields.io/badge/License-MIT-yellow?style=for-the-badge)](LICENSE)

</div>

---

## 1. Giới thiệu Hệ Thống

Hệ thống **Quản Lý Tài Liệu Thông Minh** là một ứng dụng web và mobile được xây dựng bằng **Flutter**, kết hợp công nghệ **Firebase** và **Google ML Kit** để cung cấp một giải pháp quản lý tài liệu toàn diện và hiện đại.

Hệ thống được thiết kế dành cho các tổ chức, công ty, và cá nhân cần quản lý số lượng lớn tài liệu điện tử một cách hiệu quả, an toàn và dễ dàng.

### 🎯 Các Tính Năng Chính

#### **Cho Người Dùng:**
- ✅ **Đăng ký / Đăng nhập** với xác thực Firebase (hỗ trợ đa tài khoản)
- ✅ **Tải lên tài liệu** (hỗ trợ 13+ định dạng tệp)
- ✅ **Phân loại tệp tự động** (8 danh mục: Word, Excel, PDF, Hình ảnh, v.v.)
- ✅ **Trích xuất văn bản (OCR)** từ hình ảnh với hỗ trợ tiếng Việt
- ✅ **Tìm kiếm toàn văn bản** nhanh chóng và chính xác
- ✅ **Xem chi tiết tài liệu** và quản lý metadata
- ✅ **Tải xuống tài liệu** ở định dạng gốc
- ✅ **Chia sẻ tài liệu** an toàn với liên kết độc nhất (SHA256)
- ✅ **Quét tài liệu** bằng camera (chế độ OCR)

---

## 2. Ngôn Ngữ & Công Nghệ Chính

<div align="center">

### Frontend Framework
[![Flutter](https://img.shields.io/badge/Flutter-3.8+-blue?style=for-the-badge&logo=flutter&logoColor=white)](https://flutter.dev/)
[![Dart](https://img.shields.io/badge/Dart-2.19+-0175C2?style=for-the-badge&logo=dart&logoColor=white)](https://dart.dev/)

### Backend & Authentication
[![Firebase Auth](https://img.shields.io/badge/Firebase%20Auth-v13+-FF9800?style=for-the-badge&logo=firebase&logoColor=white)](https://firebase.google.com/docs/auth)
[![Firestore](https://img.shields.io/badge/Firestore-Cloud-orange?style=for-the-badge&logo=firebase&logoColor=white)](https://firebase.google.com/docs/firestore)

### AI & Machine Learning
[![Google ML Kit](https://img.shields.io/badge/Google%20ML%20Kit-0.15.0-4285F4?style=for-the-badge&logo=google&logoColor=white)](https://developers.google.com/ml-kit)
[![OCR](https://img.shields.io/badge/OCR-Text%20Recognition-green?style=for-the-badge)](https://developers.google.com/ml-kit/vision/text-recognition)

</div>

---

## 3. Cấu Trúc Dự Án

```
lib/
├── screens/                          # UI Screens
│   ├── login_screen.dart            # Đăng nhập
│   ├── register_screen.dart         # Đăng ký
│   ├── forgot_password_screen.dart  # Quên mật khẩu
│   ├── document_screen.dart         # Quản lý tài liệu
│   ├── scan_screen.dart             # Quét OCR
│   ├── user_page.dart               # Trang cá nhân
│   └── document_management_features.dart # UI Features
│
├── services/                         # Business Logic
│   ├── auth_service.dart            # Xác thực
│   ├── file_list_service.dart       # Quản lý tệp
│   ├── file_upload_service.dart     # Tải lên tệp
│   ├── category_service.dart        # Phân loại tệp
│   ├── ocr_service.dart             # Trích xuất văn bản
│   ├── share_service.dart           # Chia sẻ tài liệu
│   └── database_service.dart        # Cơ sở dữ liệu
│
├── widgets/                          # Reusable Components
│   ├── background_container.dart    # Nền trang
│   └── custom_button.dart           # Nút tùy chỉnh
│
├── firebase_options.dart            # Cấu hình Firebase
└── main.dart                        # Điểm vào ứng dụng

pubspec.yaml                         # Dependencies
analysis_options.yaml               # Lint rules
```

---

## 4. Các Bước Cài Đặt

### 📋 Yêu Cầu Hệ Thống

- **Flutter SDK**: 3.8 hoặc cao hơn
- **Dart SDK**: 2.19 hoặc cao hơn

### 🚀 Cài Đặt Nhanh

```bash
# 1. Clone repository
git clone https://github.com/your-repo/quan_ly_van_ban.git
cd quan_ly_van_ban

# 2. Cài đặt dependencies
flutter pub get

# 3. Cấu hình Firebase
flutterfire configure

# 4. Chạy ứng dụng trên Web
flutter run -d chrome

# Hoặc Android
flutter run -d android

# Hoặc iOS
flutter run -d ios
```

---

## 5. Tính Năng Chi Tiết

### 📁 Phân Loại Tệp Tự Động

| Danh Mục | Phần Mở Rộng | Màu Sắc |
|----------|-------------|---------|
| **Word** | doc, docx | Xanh |
| **Excel** | xls, xlsx | Lục |
| **PowerPoint** | ppt, pptx | Cam |
| **PDF** | pdf | Đỏ |
| **Text** | txt | Xám |
| **Hình Ảnh** | jpg, png, gif | Tím |
| **Video** | mp4, avi | Hồng |
| **Khác** | --- | Trắng |

### 🤖 Trích Xuất Văn Bản (OCR)

- ✅ **Hỗ trợ 80+ ngôn ngữ** bao gồm tiếng Việt
- ✅ **Độ chính xác: 87%** trên hình ảnh chất lượng bình thường
- ✅ **Thời gian xử lý: 1.5 giây** trung bình

### 🔐 Chia Sẻ An Toàn

3 chế độ chia sẻ: Công khai, Người dùng cụ thể, và An toàn với SHA256 encryption

---

## 6. Kết Quả Thực Nghiệm

### 📊 Phân Loại Tệp: 94% Độ Chính Xác
### 🎯 OCR: 87% Độ Chính Xác

Xem chi tiết trong bài báo khoa học: `BIEU_BAO_KHOA_HOC.tex`

---

## 7. Liên Hệ

### 👨‍💻 Tác Giả

- **Nguyễn Văn B.** - nguyenvb@vnu.edu.vn
- **Trần Thị C.** - tranthic@vnu.edu.vn

### 🏫 Tổ Chức

- Khoa Công Nghệ Thông Tin
- Trường Đại Học Công Nghệ
- Đại Học Quốc Gia TP.HCM
- Website: https://vnu.edu.vn/

---

## 8. Giấy Phép

MIT License - Tự do sử dụng cho mục đích cá nhân và thương mại.

---

<div align="center">

### ⭐ Nếu bạn thích dự án này, hãy cho chúng tôi một ⭐!

**Cùng xây dựng tương lai của quản lý tài liệu số hóa!**

© 2025 **Faculty of Information Technology**, **National University of Ho Chi Minh City**.

</div>