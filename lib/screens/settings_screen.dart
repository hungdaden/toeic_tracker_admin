import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../widgets/dynamic_island_notification.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final _supportZaloController = TextEditingController();
  final _appVersionController = TextEditingController();
  final _aiModelController = TextEditingController();
  final _aiPromptController = TextEditingController();
  final _geminiApiKeyController = TextEditingController();
  bool _isMaintenanceMode = false;
  bool _isLoading = true;

  // --- BẢO VỆ KHU VỰC MUN AI ---
  bool _isAIUnlocked = false;
  final _apiUsernameController = TextEditingController();
  final _apiPasswordController = TextEditingController();
  bool _isAuthenticating = false;
  String? _authError;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  @override
  void dispose() {
    _supportZaloController.dispose();
    _appVersionController.dispose();
    _aiModelController.dispose();
    _aiPromptController.dispose();
    _geminiApiKeyController.dispose();
    _apiUsernameController.dispose();
    _apiPasswordController.dispose();
    super.dispose();
  }

  Future<void> _loadSettings() async {
    final systemDoc = await FirebaseFirestore.instanceFor(app: Firebase.app('AdminApp')).collection('config').doc('system').get();
    
    if (systemDoc.exists) {
      final data = systemDoc.data()!;
      setState(() {
        _supportZaloController.text = data['supportZalo'] ?? '';
        _appVersionController.text = data['appVersion'] ?? '1.0.0';
        _isMaintenanceMode = data['maintenanceMode'] ?? false;
      });
    }

    // CHỈ tải dữ liệu AI khi đã xác thực (sẽ gọi riêng sau)
    setState(() => _isLoading = false);
  }

  Future<void> _loadAISettings() async {
    final systemDoc = await FirebaseFirestore.instanceFor(app: Firebase.app('AdminApp')).collection('config').doc('system').get();
    final secretsDoc = await FirebaseFirestore.instanceFor(app: Firebase.app('AdminApp')).collection('config').doc('secrets').get();
    
    if (systemDoc.exists) {
      final data = systemDoc.data()!;
      setState(() {
        _aiModelController.text = data['aiModel'] ?? 'gemini-2.0-flash';
        _aiPromptController.text = data['aiSystemPrompt'] ?? 'Bạn là Mun AI, trợ lý học tập TOEIC...';
      });
    }

    if (secretsDoc.exists) {
      setState(() {
        _geminiApiKeyController.text = secretsDoc.data()?['geminiApiKey'] ?? '';
      });
    }
  }

  void _authenticateAPI() async {
    final username = _apiUsernameController.text.trim();
    final password = _apiPasswordController.text.trim();

    setState(() {
      _isAuthenticating = true;
      _authError = null;
    });

    try {
      // Lấy credentials từ Firestore (config/secrets), không lưu trong code
      final secretsDoc = await FirebaseFirestore.instanceFor(app: Firebase.app('AdminApp')).collection('config').doc('secrets').get();
      final storedUsername = (secretsDoc.data()?['apiAdminUsername'] ?? '').toString().trim();
      final storedPassword = (secretsDoc.data()?['apiAdminPassword'] ?? '').toString().trim();

      if (username == storedUsername && password == storedPassword) {
        setState(() {
          _isAIUnlocked = true;
          _isAuthenticating = false;
        });
        _loadAISettings();
        _apiUsernameController.clear();
        _apiPasswordController.clear();
        if (!mounted) return;
        DynamicIslandNotification.show(
          context,
          title: 'Đã xác thực',
          message: 'Khu vực cấu hình Mun AI đã được mở khóa.',
          type: NotificationType.success,
        );
      } else {
        setState(() {
          _isAuthenticating = false;
          _authError = 'Sai tài khoản hoặc mật khẩu API.';
        });
      }
    } catch (e) {
      setState(() {
        _isAuthenticating = false;
        _authError = 'Không thể xác thực. Kiểm tra kết nối mạng.';
      });
    }
  }

  void _lockAISection() {
    setState(() {
      _isAIUnlocked = false;
      _aiModelController.clear();
      _aiPromptController.clear();
      _geminiApiKeyController.clear();
      _authError = null;
    });
  }

  Future<void> _toggleMaintenanceMode(bool value) async {
    final passwordController = TextEditingController();
    bool isVerifying = false;

    // Hiện Dialog xác nhận
    final confirmed = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          backgroundColor: const Color(0xFF1E293B),
          title: Text(
            value ? 'Kích hoạt Bảo trì?' : 'Tắt chế độ Bảo trì?',
            style: const TextStyle(color: Colors.white),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                value 
                  ? 'Tất cả học viên sẽ bị ngắt kết nối và không thể sử dụng App cho đến khi bạn tắt chế độ này.' 
                  : 'Học viên sẽ có thể truy cập lại vào App ngay lập tức.',
                style: const TextStyle(color: Colors.white70, fontSize: 14),
              ),
              const SizedBox(height: 20),
              TextField(
                controller: passwordController,
                obscureText: true,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  labelText: 'Nhập mật khẩu Admin để xác nhận',
                  labelStyle: const TextStyle(color: Colors.white38),
                  filled: true,
                  fillColor: const Color(0xFF0F172A),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('HỦY', style: TextStyle(color: Colors.grey)),
            ),
            ElevatedButton(
              onPressed: isVerifying ? null : () async {
                if (passwordController.text.isEmpty) return;
                
                setDialogState(() => isVerifying = true);
                try {
                  // PHẢI dùng đúng instance 'AdminApp' mới tìm thấy user
                  final adminApp = Firebase.app('AdminApp');
                  final user = FirebaseAuth.instanceFor(app: adminApp).currentUser;
                  
                  if (user != null && user.email != null) {
                    AuthCredential credential = EmailAuthProvider.credential(
                      email: user.email!,
                      password: passwordController.text,
                    );
                    await user.reauthenticateWithCredential(credential);
                    if (context.mounted) Navigator.pop(context, true);
                  } else {
                    throw 'Không tìm thấy thông tin Admin';
                  }
                } catch (e) {
                  setDialogState(() => isVerifying = false);
                  String errorMsg = 'Đã xảy ra lỗi không xác định.';
                  
                  if (e is FirebaseAuthException) {
                    switch (e.code) {
                      case 'wrong-password':
                      case 'invalid-credential':
                        errorMsg = 'Mật khẩu không chính xác. Vui lòng thử lại.';
                        break;
                      case 'too-many-requests':
                        errorMsg = 'Quá nhiều lần thử sai. Vui lòng đợi một lát.';
                        break;
                      default:
                        errorMsg = 'Lỗi xác thực: ${e.message}';
                    }
                  } else {
                    errorMsg = e.toString();
                  }

                  if (context.mounted) {
                    DynamicIslandNotification.show(
                      context,
                      title: 'Xác thực thất bại',
                      message: errorMsg,
                      type: NotificationType.error,
                    );
                  }
                }
              },
              style: ElevatedButton.styleFrom(backgroundColor: value ? Colors.redAccent : Colors.green),
              child: isVerifying 
                ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                : Text(value ? 'BẬT BẢO TRÌ' : 'TẮT BẢO TRÌ'),
            ),
          ],
        ),
      ),
    );

    if (confirmed != true) {
      setState(() => _isMaintenanceMode = !value); // Reset switch nếu hủy
      return;
    }

    setState(() => _isMaintenanceMode = value);
    
    try {
      await FirebaseFirestore.instanceFor(app: Firebase.app('AdminApp'))
          .collection('config')
          .doc('system')
          .update({
        'maintenanceMode': value,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      if (mounted) {
        DynamicIslandNotification.show(
          context,
          title: value ? 'Đã bật bảo trì' : 'Đã tắt bảo trì',
          message: value 
            ? 'Hệ thống đã chuyển sang chế độ bảo trì.' 
            : 'Hệ thống đã hoạt động trở lại bình thường.',
          type: value ? NotificationType.warning : NotificationType.success,
        );
      }
    } catch (e) {
      setState(() => _isMaintenanceMode = !value);
      if (mounted) {
        DynamicIslandNotification.show(
          context,
          title: 'Lỗi cập nhật',
          message: e.toString(),
          type: NotificationType.error,
        );
      }
    }
  }

  Future<void> _saveSettings() async {
    setState(() => _isLoading = true);
    try {
      // Lưu thông tin công khai
      final systemUpdate = <String, dynamic>{
        'supportZalo': _supportZaloController.text.trim(),
        'appVersion': _appVersionController.text.trim(),
        'maintenanceMode': _isMaintenanceMode,
        'updatedAt': FieldValue.serverTimestamp(),
        'geminiApiKey': FieldValue.delete(), // Xóa bỏ hoàn toàn khỏi document công khai
      };

      // Nếu khu vực AI đã mở khóa, lưu luôn thông tin AI
      if (_isAIUnlocked) {
        systemUpdate['aiModel'] = _aiModelController.text.trim();
        systemUpdate['aiSystemPrompt'] = _aiPromptController.text.trim();
      }

      await FirebaseFirestore.instanceFor(app: Firebase.app('AdminApp')).collection('config').doc('system').update(systemUpdate);

      // Lưu thông tin nhạy cảm (chỉ khi đã mở khóa)
      if (_isAIUnlocked && _geminiApiKeyController.text.trim().isNotEmpty) {
        await FirebaseFirestore.instanceFor(app: Firebase.app('AdminApp')).collection('config').doc('secrets').set({
          'geminiApiKey': _geminiApiKeyController.text.trim(),
          'updatedAt': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));
      }
      
      if (mounted) {
        DynamicIslandNotification.show(
          context,
          title: 'Thành công',
          message: 'Cài đặt đã được lưu an toàn!',
          type: NotificationType.success,
        );
      }
    } catch (e) {
      print('Lỗi lưu cài đặt: $e');
      if (mounted) {
        DynamicIslandNotification.show(
          context,
          title: 'Lỗi hệ thống',
          message: e.toString(),
          type: NotificationType.error,
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) return const Center(child: CircularProgressIndicator());

    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('CÀI ĐẶT HỆ THỐNG', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white)),
            const SizedBox(height: 32),
            
            _buildSection(
              title: 'Cấu hình App Chính',
              icon: Icons.app_settings_alt_rounded,
              children: [
                _buildTextField('Số Zalo hỗ trợ', _supportZaloController, 'Hiện trong màn hình trợ giúp'),
                const SizedBox(height: 20),
                _buildTextField('Phiên bản hiện tại', _appVersionController, 'Ví dụ: 1.0.5'),
                const SizedBox(height: 32),
                _buildSwitchTile(
                  'Chế độ bảo trì', 
                  'Khi bật, học viên sẽ không thể vào app và thấy thông báo bảo trì.',
                  _isMaintenanceMode,
                  _toggleMaintenanceMode, // Gọi hàm lưu tức thì
                ),
              ],
            ),
            
            const SizedBox(height: 32),
            
            // KHU VỰC MUN AI - CÓ BẢO VỆ
            _isAIUnlocked ? _buildUnlockedAISection() : _buildLockedAISection(),
            
            const SizedBox(height: 48),
            
            SizedBox(
              width: 200,
              height: 50,
              child: ElevatedButton(
                onPressed: _saveSettings,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF4F46E5),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: const Text('LƯU CÀI ĐẶT', style: TextStyle(fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // --- KHU VỰC BỊ KHÓA: Hiện form đăng nhập ---
  Widget _buildLockedAISection() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.lock_rounded, color: Colors.amber, size: 22),
              const SizedBox(width: 12),
              const Text(
                'Cấu hình Trí tuệ nhân tạo (Mun AI)',
                style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.amber.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Text(
                  'ĐÃ KHÓA',
                  style: TextStyle(color: Colors.amber, fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 1),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.amber.withOpacity(0.05),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.amber.withOpacity(0.2)),
            ),
            child: Row(
              children: [
                Icon(Icons.shield_rounded, color: Colors.amber.withOpacity(0.7), size: 20),
                const SizedBox(width: 12),
                const Expanded(
                  child: Text(
                    'Khu vực này chứa thông tin nhạy cảm (API Key, Model, Prompt). Vui lòng xác thực để truy cập.',
                    style: TextStyle(color: Colors.white60, fontSize: 13),
                  ),
                ),
              ],
            ),
          ),
          
          const SizedBox(height: 24),
          
          // Form đăng nhập
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _apiUsernameController,
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    labelText: 'Tài khoản API',
                    labelStyle: const TextStyle(color: Colors.white38),
                    prefixIcon: const Icon(Icons.person_outline, color: Colors.white38),
                    filled: true,
                    fillColor: const Color(0xFF0F172A),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                    errorText: _authError != null ? '' : null,
                  ),
                  onSubmitted: (_) => _authenticateAPI(),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: TextField(
                  controller: _apiPasswordController,
                  obscureText: true,
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    labelText: 'Mật khẩu API',
                    labelStyle: const TextStyle(color: Colors.white38),
                    prefixIcon: const Icon(Icons.key_rounded, color: Colors.white38),
                    filled: true,
                    fillColor: const Color(0xFF0F172A),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                    errorText: _authError,
                    errorStyle: const TextStyle(color: Colors.redAccent),
                  ),
                  onSubmitted: (_) => _authenticateAPI(),
                ),
              ),
              const SizedBox(width: 16),
              SizedBox(
                height: 56,
                child: ElevatedButton.icon(
                  onPressed: _isAuthenticating ? null : _authenticateAPI,
                  icon: _isAuthenticating
                      ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                      : const Icon(Icons.lock_open_rounded, size: 18),
                  label: Text(_isAuthenticating ? 'Đang xác thực...' : 'MỞ KHÓA'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.amber.shade800,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // --- KHU VỰC ĐÃ MỞ KHÓA: Hiện đầy đủ cấu hình ---
  Widget _buildUnlockedAISection() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.greenAccent.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.psychology_rounded, color: Colors.greenAccent),
              const SizedBox(width: 12),
              const Text(
                'Cấu hình Trí tuệ nhân tạo (Mun AI)',
                style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const Spacer(),
              TextButton.icon(
                onPressed: _lockAISection,
                icon: const Icon(Icons.lock_rounded, size: 16, color: Colors.redAccent),
                label: const Text('KHÓA LẠI', style: TextStyle(color: Colors.redAccent, fontSize: 12, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
          const SizedBox(height: 24),
          _buildTextField('Model Name', _aiModelController, 'Ví dụ: gemini-2.0-flash'),
          const SizedBox(height: 20),
          _buildTextField('Gemini API Key', _geminiApiKeyController, 'Dán API Key của bạn vào đây'),
          const SizedBox(height: 20),
          _buildTextField('System Prompt (Tính cách AI)', _aiPromptController, 'Dạy AI cách xưng hô và trả lời...', maxLines: 5),
        ],
      ),
    );
  }

  Widget _buildSection({required String title, required IconData icon, required List<Widget> children}) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: Colors.indigoAccent),
              const SizedBox(width: 12),
              Text(title, style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
            ],
          ),
          const SizedBox(height: 24),
          ...children,
        ],
      ),
    );
  }

  Widget _buildTextField(String label, TextEditingController controller, String hint, {int maxLines = 1}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(color: Colors.grey, fontSize: 14)),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          maxLines: maxLines,
          style: const TextStyle(color: Colors.white),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: const TextStyle(color: Colors.white24),
            filled: true,
            fillColor: const Color(0xFF0F172A),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
          ),
        ),
      ],
    );
  }


  Widget _buildSwitchTile(String title, String subtitle, bool value, Function(bool) onChanged) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF0F172A),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                const SizedBox(height: 4),
                Text(subtitle, style: const TextStyle(color: Colors.grey, fontSize: 12)),
              ],
            ),
          ),
          Switch(
            value: value,
            onChanged: onChanged,
            activeColor: Colors.redAccent,
          ),
        ],
      ),
    );
  }
}
