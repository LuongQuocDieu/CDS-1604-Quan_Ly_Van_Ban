import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'firebase_options.dart';
import 'services/auth_service.dart';
import 'services/file_upload_service.dart';
import 'screens/user_page.dart';
import 'screens/scan_screen.dart';
import 'screens/document_screen.dart';
import 'screens/login_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Firebase
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
    ),
  );
  runApp(const MyApp());
}

// Update the MaterialApp theme
class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Quản Lý Văn Bản',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        visualDensity: VisualDensity.adaptivePlatformDensity,
        scaffoldBackgroundColor: Colors.transparent, // Add this
      ),
      home: const AuthWrapper(),
    );
  }
}

// AuthWrapper để kiểm tra trạng thái đăng nhập
class AuthWrapper extends StatefulWidget {
  const AuthWrapper({super.key});

  @override
  State<AuthWrapper> createState() => _AuthWrapperState();
}

class _AuthWrapperState extends State<AuthWrapper> {
  String _lastKnownUid = ''; // Track last known logged-in user
  late Stream<User?> _authStream; // Cache stream in state

  @override
  void initState() {
    super.initState();
    print('🔄 [AuthWrapper] Initializing');
    // Create stream ONCE and keep it (but it will emit fresh events from Firebase)
    _authStream = AuthService().authStateChanges
        .where((user) {
          final uid = user?.uid ?? '';
          final isNull = user == null;
          
          // Print for debugging
          if (isNull && _lastKnownUid.isNotEmpty) {
            print('⚠️  [AuthWrapper] Filtering: Ignoring null event (was logged in as $_lastKnownUid)');
            return false; // Filter out this null event
          }
          
          if (uid.isNotEmpty && uid != _lastKnownUid) {
            _lastKnownUid = uid;
            print('✅ [AuthWrapper] Stream event: User UID changed to $uid');
          }
          
          return true; // Emit the event
        });
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: _authStream, // Use filtered stream
      builder: (context, snapshot) {
        print('🔍 [AuthWrapper] ConnectionState: ${snapshot.connectionState}');
        print('🔍 [AuthWrapper] HasData: ${snapshot.hasData}');
        print('🔍 [AuthWrapper] Data: ${snapshot.data?.email ?? "null"}');
        
        if (snapshot.connectionState == ConnectionState.waiting) {
          print('⏳ [AuthWrapper] Waiting for auth state...');
          
          // On Web, check currentUser immediately while waiting
          final currentUser = FirebaseAuth.instance.currentUser;
          if (currentUser != null) {
            print('🚀 [AuthWrapper] FAST PATH: currentUser detected immediately - ${currentUser.email}');
            return const HomeScreen();
          }
          
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        // Check stream data
        if (snapshot.hasData && snapshot.data != null) {
          print('✅ [AuthWrapper] User đã đăng nhập: ${snapshot.data!.email}');
          return const HomeScreen();
        }
        
        // Check currentUser as backup
        final currentUser = FirebaseAuth.instance.currentUser;
        if (currentUser != null) {
          print('✅ [AuthWrapper] User đã đăng nhập (backup currentUser): ${currentUser.email}');
          return const HomeScreen();
        }
        
        // User is logged out
        _lastKnownUid = '';
        print('❌ [AuthWrapper] User chưa đăng nhập');
        return const LoginScreen();
      },
    );
  }
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen>
    with SingleTickerProviderStateMixin {
  int _selectedIndex = 0;
  bool _showChat = false;
  final List<Map<String, dynamic>> _messages = [];
  final TextEditingController _controller = TextEditingController();

  final _fileUploadService = FileUploadService();

  late AnimationController _animationController;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    _animationController.dispose();
    super.dispose();
  }

  void _toggleChat() {
    setState(() {
      _showChat = !_showChat;
      if (_showChat) {
        _animationController.forward();
      } else {
        _animationController.reverse();
      }
    });
  }

  void _sendMessage() {
    if (_controller.text.isEmpty) return;

    setState(() {
      _messages.add({
        'text': _controller.text,
        'isUser': true,
        'time': DateTime.now(),
      });

      // Simulate bot response
      Future.delayed(const Duration(seconds: 1), () {
        if (mounted) {
          setState(() {
            _messages.add({
              'text': 'Tôi đã nhận được tin nhắn của bạn: ${_controller.text}',
              'isUser': false,
              'time': DateTime.now(),
            });
          });
        }
      });
    });

    _controller.clear();
  }

  void _handleUploadFile() async {
    try {
      Map<String, dynamic>? fileInfo = await _fileUploadService
          .pickAndUploadFile();

      if (fileInfo != null && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Upload file thành công!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Lỗi: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
      if (_showChat) _toggleChat();
    });
  }

  // Update the main build method in _HomeScreenState
  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Color(0xFF1B3B8B),
            Color(0xFF1B3B8B),
            Color(0xFFF15A24),
            Color(0xFFF15A24),
          ],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
      ),
      child: Scaffold(
        backgroundColor: Colors.transparent,
        extendBody: true,
        body: Stack(
          children: [
            IndexedStack(
              index: _selectedIndex,
              children: [
                _homePage(),
                const DocumentScreen(),
                const ScanScreen(),
                _toolsPage(),
                const UserPage(),
              ],
            ),
            if (_showChat) _chatPopup(),
          ],
        ),
        floatingActionButton: FloatingActionButton(
          onPressed: _toggleChat,
          backgroundColor: const Color(0xFF1B3B8B),
          child: Icon(
            _showChat ? Icons.close : Icons.chat_bubble_outline,
            color: Colors.white,
          ),
        ),
        bottomNavigationBar: Container(
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF1B3B8B), Color(0xFFF15A24)],
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 10,
                offset: const Offset(0, -5),
              ),
            ],
          ),
          child: BottomNavigationBar(
            backgroundColor: Colors.transparent,
            elevation: 0,
            items: [
              _navItem(Icons.home_outlined, "Trang chủ"),
              _navItem(Icons.description_outlined, "Tài liệu"),
              _navItem(Icons.document_scanner_outlined, "Quét"),
              _navItem(Icons.build_outlined, "Công cụ"),
              _navItem(Icons.person_outline, "Tôi"),
            ],
            currentIndex: _selectedIndex,
            selectedItemColor: Colors.white,
            unselectedItemColor: Colors.white.withOpacity(0.6),
            showUnselectedLabels: true,
            type: BottomNavigationBarType.fixed,
            onTap: _onItemTapped,
          ),
        ),
      ),
    );
  }

  BottomNavigationBarItem _navItem(IconData icon, String label) {
    return BottomNavigationBarItem(
      icon: Icon(icon),
      activeIcon: Icon(icon, color: const Color(0xFF1B3B8B)),
      label: label,
    );
  }

  Widget _homePage() {
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
      child: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: const [
                      CircleAvatar(
                        radius: 22,
                        backgroundColor: Colors.white,
                        child: Icon(Icons.person, color: Color(0xFF1B3B8B)),
                      ),
                      SizedBox(width: 12),
                      Text(
                        "Phần mềm QUẢN LÝ VĂN BẢN",
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                  Row(
                    children: [
                      IconButton(
                        onPressed: () {},
                        icon: const Icon(Icons.search, color: Colors.white),
                      ),
                      IconButton(
                        onPressed: () {},
                        icon: const Icon(
                          Icons.notifications_none,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 24),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: Colors.white30, width: 1.2),
                ),
                child: Column(
                  children: [
                    const Text(
                      "Phần mềm",
                      style: TextStyle(color: Colors.white70, fontSize: 16),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      "QUẢN LÝ VĂN BẢN",
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 20),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _iconAction(Icons.history, "Lịch sử", onTap: () {}),
                        _iconAction(
                          Icons.upload,
                          "Tải lên",
                          onTap: _handleUploadFile,
                        ),
                        _iconAction(Icons.sd_storage, "Bộ nhớ", onTap: () {}),
                        _iconAction(Icons.transform, "Đổi dạng", onTap: () {}),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              const Text(
                "Tính năng nổi bật",
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 12),
              GridView.count(
                crossAxisCount: 2,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                childAspectRatio: 3.2,
                children: [
                  _actionItem(Icons.image, "Nhập ảnh"),
                  _actionItem(Icons.credit_card, "Thẻ ID"),
                ],
              ),
              const SizedBox(height: 28),
              const Text(
                "Gần đây",
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 16),
              SizedBox(
                height: 130,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  children: [
                    _promoCard("BaoCaoThang10.pdf", Colors.orange),
                    _promoCard("BienBanHop.docx", Colors.blue),
                    _promoCard("AnhVanBan.png", Colors.lightBlueAccent),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _toolsPage() {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Color(0xFF1B3B8B),
            Color(0xFF1B3B8B),
            Color(0xFFF15A24),
            Color(0xFFF15A24),
          ],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
      ),
      child: const Center(
        child: Text(
          "🧰 Trang Công cụ",
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
      ),
    );
  }

  Widget _chatPopup() {
    return Positioned(
      bottom: 0,
      left: 0,
      right: 0,
      child: Container(
        height: 330,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          boxShadow: [
            BoxShadow(
              color: Colors.black26,
              blurRadius: 8,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  "💬 Trợ lý AI",
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                IconButton(
                  onPressed: _toggleChat,
                  icon: const Icon(Icons.close),
                ),
              ],
            ),
            const Divider(),
            Expanded(
              child: ListView.builder(
                itemCount: _messages.length,
                itemBuilder: (context, index) {
                  final msg = _messages[index];
                  return _buildMessageBubble(msg);
                },
              ),
            ),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _controller,
                    decoration: InputDecoration(
                      hintText: "Nhập tin nhắn...",
                      fillColor: Colors.grey[100],
                      filled: true,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(30),
                        borderSide: BorderSide.none,
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                    ),
                    onSubmitted: (_) => _sendMessage(),
                  ),
                ),
                const SizedBox(width: 8),
                CircleAvatar(
                  backgroundColor: const Color(0xFF1B3B8B),
                  child: IconButton(
                    icon: const Icon(Icons.send, color: Colors.white),
                    onPressed: _sendMessage,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMessageBubble(Map<String, dynamic> message) {
    final isUser = message['isUser'] as bool;
    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: isUser
              ? const Color(0xFF1B3B8B).withOpacity(0.15)
              : Colors.grey.shade200,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Text(message['text'] as String),
      ),
    );
  }

  static Widget _iconAction(
    IconData icon,
    String label, {
    VoidCallback? onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white24,
            ),
            padding: const EdgeInsets.all(10),
            child: Icon(icon, color: Colors.white),
          ),
          const SizedBox(height: 8),
          Text(label, style: const TextStyle(color: Colors.white)),
        ],
      ),
    );
  }

  static Widget _actionItem(IconData icon, String text) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.orange.withOpacity(0.2),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: const Color(0xFF1B3B8B)),
          const SizedBox(width: 8),
          Text(text, style: const TextStyle(fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }

  static Widget _promoCard(String text, Color color) {
    return Container(
      width: 220,
      margin: const EdgeInsets.only(right: 12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.85),
        borderRadius: BorderRadius.circular(16),
      ),
      padding: const EdgeInsets.all(16),
      alignment: Alignment.bottomLeft,
      child: Text(
        text,
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.bold,
          fontSize: 16,
        ),
      ),
    );
  }
}
