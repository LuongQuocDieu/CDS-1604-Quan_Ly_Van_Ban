import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import 'login_screen.dart';

class UserPage extends StatefulWidget {
  const UserPage({super.key});

  @override
  State<UserPage> createState() => _UserPageState();
}

class _UserPageState extends State<UserPage>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  final AuthService _authService = AuthService();

  String userName = '';
  String userEmail = '';
  String userRole = '';
  String userStatus = '';

  @override
  void initState() {
    super.initState();
    _setupAnimations();
    _loadUserInfo();
  }

  void _setupAnimations() {
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeIn),
    );

    _animationController.forward();
  }

  Future<void> _loadUserInfo() async {
    try {
      print('📥 [UserPage] Đang load user info...');
      
      // Lấy user từ Firebase Auth (không dùng stream)
      final currentUser = _authService.currentUser;
      
      if (currentUser != null) {
        print('✅ [UserPage] Current user: ${currentUser.email}');
        
        // Cố gắng lấy từ Firestore
        try {
          final userInfo = await _authService.getCurrentUserInfo();
          if (userInfo != null && mounted) {
            print('✅ [UserPage] User info received from Firestore: $userInfo');
            setState(() {
              userName = userInfo['name'] ?? currentUser.displayName ?? 'Người dùng';
              userEmail = userInfo['email'] ?? currentUser.email ?? '';
              userRole = userInfo['role'] ?? 'Người dùng';
              userStatus = userInfo['status'] ?? 'Đang hoạt động';
            });
            print('✅ [UserPage] UI updated: $userName');
            return;
          }
        } catch (e) {
          print('⚠️ [UserPage] Firestore error (using Firebase Auth fallback): $e');
        }
        
        // Fallback: Dùng Firebase Auth data
        if (mounted) {
          setState(() {
            userName = currentUser.displayName ?? 'Người dùng';
            userEmail = currentUser.email ?? '';
          });
          print('✅ [UserPage] Using Firebase Auth data: $userName');
        }
      } else {
        print('❌ [UserPage] Current user is null');
      }
    } catch (e) {
      print('❌ [UserPage] Error loading user info: $e');
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _navigateToLogin() async {
    try {
      await _authService.signOut();
      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const LoginScreen()),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Lỗi đăng xuất: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
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
            child: FadeTransition(
              opacity: _fadeAnimation,
              child: Column(
                children: [
                  _buildHeader(),
                  const SizedBox(height: 20),
                  _buildUserInfo(),
                  const SizedBox(height: 20),
                  _buildMenuSection(),
                  const SizedBox(height: 20),
                  _buildLogoutButton(),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: const LinearGradient(
                colors: [Color(0xFFF15A24), Color(0xFFFF8C00)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.2),
                  blurRadius: 10,
                  offset: const Offset(0, 5),
                ),
              ],
            ),
            child: Center(
              child: Text(
                userName.isNotEmpty
                    ? userName.substring(0, 1).toUpperCase()
                    : 'U',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 48,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          const SizedBox(height: 15),
          Text(
            userName,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 5),
          Text(
            userEmail,
            style: TextStyle(
              color: Colors.white.withOpacity(0.8),
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUserInfo() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.1),
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: Colors.white.withOpacity(0.2), width: 1),
      ),
      child: Column(
        children: [
          _buildInfoRow(Icons.workspace_premium, "Vai trò", userRole),
          const SizedBox(height: 15),
          _buildInfoRow(Icons.circle, "Trạng thái", userStatus),
        ],
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, color: Colors.white70, size: 20),
        const SizedBox(width: 10),
        Text(
          "$label:",
          style: TextStyle(color: Colors.white.withOpacity(0.9), fontSize: 14),
        ),
        const SizedBox(width: 10),
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _buildMenuSection() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.1),
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: Colors.white.withOpacity(0.2), width: 1),
      ),
      child: Column(
        children: [
          _buildMenuItem(
            Icons.settings,
            "Cài đặt tài khoản",
            "Quản lý thông tin cá nhân",
            onTap: () {},
          ),
          _buildDivider(),
          _buildMenuItem(
            Icons.lock,
            "Đổi mật khẩu",
            "Bảo mật tài khoản",
            onTap: () {},
          ),
          _buildDivider(),
          _buildMenuItem(
            Icons.help_outline,
            "Trợ giúp",
            "Hỗ trợ và hướng dẫn",
            onTap: () {},
          ),
        ],
      ),
    );
  }

  Widget _buildMenuItem(
    IconData icon,
    String title,
    String subtitle, {
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
          child: Row(
            children: [
              Icon(icon, color: Colors.white, size: 24),
              const SizedBox(width: 15),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.7),
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.arrow_forward_ios,
                color: Colors.white.withOpacity(0.5),
                size: 16,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDivider() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      height: 1,
      color: Colors.white.withOpacity(0.1),
    );
  }

  Widget _buildLogoutButton() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      child: ElevatedButton(
        onPressed: _navigateToLogin,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.white,
          foregroundColor: const Color(0xFFF15A24),
          padding: const EdgeInsets.symmetric(vertical: 15),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          elevation: 4,
          shadowColor: Colors.black.withOpacity(0.2),
        ),
        child: const Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.logout, size: 20),
            SizedBox(width: 8),
            Text(
              'Đăng xuất',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ),
    );
  }
}
