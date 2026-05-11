import 'dart:async';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import '../widgets/dynamic_island_notification.dart';

class NotificationManagementScreen extends StatefulWidget {
  const NotificationManagementScreen({super.key});

  @override
  State<NotificationManagementScreen> createState() => _NotificationManagementScreenState();
}

class _NotificationManagementScreenState extends State<NotificationManagementScreen> {
  final _titleController = TextEditingController();
  final _bodyController = TextEditingController();
  bool _isSending = false;
  String _targetGroup = 'all';

  // --- TRẠNG THÁI XEM TRƯỚC (PREVIEW) ---
  String _previewTitle = '';
  String _previewBody = '';
  Timer? _debounceTimer;

  @override
  void initState() {
    super.initState();
    _titleController.addListener(_onTextChanged);
    _bodyController.addListener(_onTextChanged);
  }

  @override
  void dispose() {
    _titleController.dispose();
    _bodyController.dispose();
    _debounceTimer?.cancel();
    super.dispose();
  }

  void _onTextChanged() {
    if (_debounceTimer?.isActive ?? false) _debounceTimer?.cancel();
    _debounceTimer = Timer(const Duration(milliseconds: 1500), () {
      if (mounted) {
        setState(() {
          _previewTitle = _titleController.text;
          _previewBody = _bodyController.text;
        });
      }
    });
  }

  void _sendNotification() async {
    if (_titleController.text.isEmpty || _bodyController.text.isEmpty) {
      DynamicIslandNotification.show(
        context,
        title: 'Thiếu dữ liệu',
        message: 'Vui lòng nhập đầy đủ tiêu đề và nội dung',
        type: NotificationType.warning,
      );
      return;
    }

    setState(() => _isSending = true);

    try {
      await FirebaseFirestore.instanceFor(app: Firebase.app('AdminApp')).collection('notifications').add({
        'title': _titleController.text.trim(),
        'body': _bodyController.text.trim(),
        'targetGroup': _targetGroup,
        'sentAt': FieldValue.serverTimestamp(),
        'status': 'pending',
      });

      if (mounted) {
        setState(() {
          _isSending = false;
          _titleController.clear();
          _bodyController.clear();
          _previewTitle = '';
          _previewBody = '';
        });
        
        DynamicIslandNotification.show(
          context,
          title: 'Đã xếp hàng gửi',
          message: 'Thông báo đang được hệ thống đẩy đi...',
          type: NotificationType.success,
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isSending = false);
        String errorMsg = e.toString();
        
        if (e is FirebaseException) {
          switch (e.code) {
            case 'permission-denied':
              errorMsg = 'Bạn không có quyền thực hiện thao tác này.';
              break;
            case 'unavailable':
              errorMsg = 'Mất kết nối với máy chủ. Vui lòng kiểm tra Internet.';
              break;
            default:
              errorMsg = 'Lỗi hệ thống: ${e.message}';
          }
        }

        DynamicIslandNotification.show(
          context,
          title: 'Lỗi gửi tin',
          message: errorMsg,
          type: NotificationType.error,
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool isMobile = MediaQuery.of(context).size.width < 900;

    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(isMobile ? 16.0 : 24.0),
        child: isMobile 
          ? Column(
              children: [
                _buildFormSection(),
                const SizedBox(height: 24),
                _buildPreviewSection(true),
              ],
            )
          : Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(flex: 2, child: _buildFormSection()),
                const SizedBox(width: 32),
                Expanded(child: _buildPreviewSection(false)),
              ],
            ),
      ),
    );
  }

  Widget _buildFormSection() {
    return Container(
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('GỬI THÔNG BÁO MỚI', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white)),
          const SizedBox(height: 32),
          const Text('Đối tượng nhận', style: TextStyle(color: Colors.grey, fontSize: 14)),
          const SizedBox(height: 12),
          Row(
            children: [
              _buildTargetOption('Tất cả', 'all', Icons.groups_rounded),
              const SizedBox(width: 16),
              _buildTargetOption('Mất streak', 'inactive', Icons.timer_off_rounded),
            ],
          ),
          const SizedBox(height: 32),
          TextField(
            controller: _titleController,
            style: const TextStyle(color: Colors.white),
            decoration: InputDecoration(
              labelText: 'Tiêu đề thông báo',
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
          const SizedBox(height: 24),
          TextField(
            controller: _bodyController,
            maxLines: 5,
            style: const TextStyle(color: Colors.white),
            decoration: InputDecoration(
              labelText: 'Nội dung thông báo',
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
          const SizedBox(height: 40),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _isSending ? null : _sendNotification,
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 20),
                backgroundColor: const Color(0xFF4F46E5),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: _isSending 
                ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                : const Text('GỬI THÔNG BÁO NGAY', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
            ),
          ),
          const SizedBox(height: 48),
          const Divider(color: Colors.white10),
          const SizedBox(height: 24),
          const Text('LỊCH SỬ GỬI GẦN ĐÂY', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.grey)),
          const SizedBox(height: 16),
          _buildSentHistory(),
        ],
      ),
    );
  }

  Widget _buildPreviewSection(bool isSmall) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('XEM TRƯỚC TRÊN MOBILE', style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold)),
        const SizedBox(height: 16),
        Container(
          width: isSmall ? double.infinity : 400,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.black,
            borderRadius: BorderRadius.circular(30),
            border: Border.all(color: Colors.white24, width: 8),
          ),
          child: Column(
            children: [
              const SizedBox(height: 10),
              Container(width: 60, height: 4, decoration: BoxDecoration(color: Colors.white24, borderRadius: BorderRadius.circular(2))),
              const SizedBox(height: 30),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(color: const Color(0xFF1E293B), borderRadius: BorderRadius.circular(16)),
                child: Row(
                  children: [
                    const Icon(Icons.notifications_active_rounded, color: Colors.amber, size: 32),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(_previewTitle.isEmpty ? 'Tiêu đề' : _previewTitle, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13)),
                          Text(_previewBody.isEmpty ? 'Nội dung thông báo sẽ hiện ở đây...' : _previewBody, style: const TextStyle(color: Colors.white70, fontSize: 11), maxLines: 2, overflow: TextOverflow.ellipsis),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 100),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSentHistory() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instanceFor(app: Firebase.app('AdminApp'))
          .collection('notifications')
          .orderBy('sentAt', descending: true)
          .limit(10)
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const SizedBox();
        final docs = snapshot.data!.docs;
        if (docs.isEmpty) return const Text('Chưa có lịch sử gửi.', style: TextStyle(color: Colors.grey, fontSize: 12));

        return ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: docs.length,
          itemBuilder: (context, index) {
            final data = docs[index].data() as Map<String, dynamic>;
            final sentAt = (data['sentAt'] as Timestamp?)?.toDate() ?? DateTime.now();
            return Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.03),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  const Icon(Icons.history_edu_rounded, color: Colors.grey, size: 18),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(data['title'] ?? '', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13)),
                        Text(data['body'] ?? '', style: const TextStyle(color: Colors.white60, fontSize: 11), maxLines: 1, overflow: TextOverflow.ellipsis),
                      ],
                    ),
                  ),
                  Text(
                    '${sentAt.hour}:${sentAt.minute.toString().padLeft(2, '0')}',
                    style: const TextStyle(color: Colors.grey, fontSize: 10),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildTargetOption(String label, String value, IconData icon) {
    bool isSelected = _targetGroup == value;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _targetGroup = value),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 16),
          decoration: BoxDecoration(
            color: isSelected ? const Color(0xFF4F46E5).withOpacity(0.1) : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: isSelected ? const Color(0xFF4F46E5) : Colors.white12),
          ),
          child: Column(
            children: [
              Icon(icon, color: isSelected ? const Color(0xFF4F46E5) : Colors.grey),
              const SizedBox(height: 8),
              Text(label, style: TextStyle(color: isSelected ? Colors.white : Colors.grey, fontSize: 12)),
            ],
          ),
        ),
      ),
    );
  }
}
