import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import 'register_screen.dart';
import 'forgot_password_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen>
    with SingleTickerProviderStateMixin {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isPasswordVisible = false;
  bool _rememberMe = false;
  bool _isLoading = false;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  final AuthService _authService = AuthService();

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
    _animationController.forward();
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();

    print('🔍 DEBUG: Bắt đầu _handleLogin');
    print('📧 Email: $email');
    print('🔐 Password: ${password.isNotEmpty ? '***' : 'EMPTY'}');

    if (email.isEmpty || password.isEmpty) {
      print('❌ Email hoặc password trống');
      _showErrorDialog('Vui lòng nhập email và mật khẩu');
      return;
    }

    setState(() => _isLoading = true);
    print('⏳ Loading state set to true');

    try {
      print('🔄 Gọi signInWithEmailAndPassword...');
      await _authService.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      print('✅ Đăng nhập Firebase thành công!');

      // Wait for Web platform to emit authStateChanges event (increased to 1s for reliability)
      await Future.delayed(const Duration(milliseconds: 1000));

      if (mounted) {
        print('📲 Mounted, hiển thị snackbar');
        // Điều hướng sẽ được xử lý tự động bởi AuthWrapper
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Đăng nhập thành công!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      print('❌ Lỗi đăng nhập: $e');
      if (mounted) {
        _showErrorDialog(e.toString());
      }
    } finally {
      print('🏁 Finally block - reset loading state');
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (BuildContext context) => AlertDialog(
        title: const Text('Lỗi'),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              const Color(0xFF1B3B8B),
              const Color(0xFF1B3B8B).withOpacity(0.8),
              const Color(0xFFF15A24).withOpacity(0.9),
              const Color(0xFFF15A24),
            ],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: FadeTransition(
              opacity: _fadeAnimation,
              child: Column(
                children: [
                  const SizedBox(height: 40),
                  _buildLogo(),
                  const SizedBox(height: 40),
                  _buildWelcomeText(),
                  const SizedBox(height: 40),
                  _buildLoginForm(),
                  const SizedBox(height: 20),
                  _buildLoginOptions(),
                  const SizedBox(height: 30),
                  _buildLoginButton(),
                  const SizedBox(height: 20),
                  _buildSocialLogin(),
                  const SizedBox(height: 20),
                  _buildRegisterPrompt(context),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLogo() {
    return Hero(
      tag: 'app_logo',
      child: Container(
        height: 120,
        width: 120,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(color: Colors.white, width: 2),
        ),
        child: ClipOval(
          child: Image.asset(
            'assets/Hinh_Logo_DaiNam_XoaPhong.png',
            fit: BoxFit.cover,
          ),
        ),
      ),
    );
  }

  Widget _buildWelcomeText() {
    return Column(
      children: [
        Text(
          "Chào mừng trở lại!",
          style: TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.bold,
            color: Colors.white,
            shadows: [
              Shadow(
                color: Colors.black.withOpacity(0.3),
                offset: const Offset(0, 2),
                blurRadius: 4,
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        Text(
          "Đăng nhập để tiếp tục sử dụng dịch vụ",
          style: TextStyle(fontSize: 16, color: Colors.white.withOpacity(0.9)),
        ),
      ],
    );
  }

  Widget _buildLoginForm() {
    return Column(
      children: [
        _buildTextField(
          controller: _emailController,
          hint: "Email của bạn",
          icon: Icons.email_outlined,
          keyboardType: TextInputType.emailAddress,
        ),
        const SizedBox(height: 16),
        _buildTextField(
          controller: _passwordController,
          hint: "Mật khẩu",
          icon: Icons.lock_outline,
          isPassword: true,
          isPasswordVisible: _isPasswordVisible,
          onTogglePassword: () {
            setState(() => _isPasswordVisible = !_isPasswordVisible);
          },
        ),
      ],
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    bool isPassword = false,
    bool? isPasswordVisible,
    VoidCallback? onTogglePassword,
    TextInputType? keyboardType,
  }) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: TextField(
        controller: controller,
        obscureText: isPassword && !(isPasswordVisible ?? false),
        keyboardType: keyboardType,
        style: const TextStyle(color: Colors.white),
        decoration: InputDecoration(
          prefixIcon: Icon(icon, color: Colors.white70),
          suffixIcon: isPassword
              ? IconButton(
                  icon: Icon(
                    isPasswordVisible ?? false
                        ? Icons.visibility_off
                        : Icons.visibility,
                    color: Colors.white70,
                  ),
                  onPressed: onTogglePassword,
                )
              : null,
          hintText: hint,
          hintStyle: TextStyle(color: Colors.white.withOpacity(0.7)),
          filled: true,
          fillColor: Colors.white.withOpacity(0.2),
          contentPadding: const EdgeInsets.symmetric(
            vertical: 16,
            horizontal: 20,
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(15),
            borderSide: BorderSide.none,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(15),
            borderSide: BorderSide.none,
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(15),
            borderSide: const BorderSide(color: Colors.white, width: 1.5),
          ),
        ),
      ),
    );
  }

  Widget _buildLoginOptions() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            SizedBox(
              height: 24,
              width: 24,
              child: Checkbox(
                value: _rememberMe,
                onChanged: (value) => setState(() => _rememberMe = value!),
                fillColor: MaterialStateProperty.resolveWith(
                  (states) => states.contains(MaterialState.selected)
                      ? const Color(0xFFF15A24)
                      : Colors.white,
                ),
              ),
            ),
            const SizedBox(width: 8),
            Text(
              "Ghi nhớ đăng nhập",
              style: TextStyle(color: Colors.white.withOpacity(0.9)),
            ),
          ],
        ),
        // Tìm phần TextButton "Quên mật khẩu" và sửa lại như sau:
        TextButton(
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const ForgotPasswordScreen(),
              ),
            );
          },
          child: const Text(
            "Quên mật khẩu?",
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
          ),
        ),
      ],
    );
  }

  Widget _buildLoginButton() {
    return Container(
      width: double.infinity,
      height: 55,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(15),
        gradient: const LinearGradient(
          colors: [Color(0xFFF15A24), Color(0xFFFF8C00)],
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFF15A24).withOpacity(0.5),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: ElevatedButton(
        onPressed: _isLoading ? null : _handleLogin,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.transparent,
          shadowColor: Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15),
          ),
        ),
        child: _isLoading
            ? const SizedBox(
                height: 20,
                width: 20,
                child: CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  strokeWidth: 2,
                ),
              )
            : const Text(
                "ĐĂNG NHẬP",
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
      ),
    );
  }

  Widget _buildSocialLogin() {
    return Column(
      children: [
        Text(
          "Hoặc đăng nhập với",
          style: TextStyle(color: Colors.white.withOpacity(0.8)),
        ),
        const SizedBox(height: 20),
        // Social login buttons disabled - assets not available
        // Row(
        //   mainAxisAlignment: MainAxisAlignment.center,
        //   children: [
        //     _buildSocialButton(
        //       'assets/google_logo.png',
        //       "Google",
        //           () {
        //         // Handle Google login
        //       },
        //     ),
        //     const SizedBox(width: 20),
        //     _buildSocialButton(
        //       'assets/facebook_logo.png',
        //       "Facebook",
        //           () {
        //         // Handle Facebook login
        //       },
        //     ),
        //   ],
        // ),
      ],
    );
  }

  // Disabled - assets not available
  // Widget _buildSocialButton(
  //     String iconPath,
  //     String label,
  //     VoidCallback onPressed,
  //     ) {
  //   return Container(
  //     decoration: BoxDecoration(
  //       borderRadius: BorderRadius.circular(12),
  //       color: Colors.white,
  //       boxShadow: [
  //         BoxShadow(
  //           color: Colors.black.withOpacity(0.1),
  //           blurRadius: 10,
  //           offset: const Offset(0, 4),
  //         ),
  //       ],
  //     ),
  //     child: Material(
  //       color: Colors.transparent,
  //       child: InkWell(
  //         onTap: onPressed,
  //         borderRadius: BorderRadius.circular(12),
  //         child: Padding(
  //           padding: const EdgeInsets.symmetric(
  //             vertical: 12,
  //             horizontal: 20,
  //           ),
  //           child: Row(
  //             mainAxisSize: MainAxisSize.min,
  //             children: [
  //               Image.asset(iconPath, height: 24),
  //               const SizedBox(width: 10),
  //               Text(
  //                 label,
  //                 style: const TextStyle(
  //                   color: Colors.black87,
  //                   fontWeight: FontWeight.w600,
  //                 ),
  //               ),
  //             ],
  //           ),
  //         ),
  //       ),
  //     ),
  //   );
  // }

  Widget _buildRegisterPrompt(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          "Chưa có tài khoản? ",
          style: TextStyle(color: Colors.white.withOpacity(0.8)),
        ),
        TextButton(
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const RegisterScreen()),
            );
          },
          child: const Text(
            "Đăng ký ngay",
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
          ),
        ),
      ],
    );
  }
}
