import 'dart:convert';
import 'package:flutter/material.dart';
import '../models/exam_model.dart';
import '../services/exam_service.dart';
import 'package:firebase_core/firebase_core.dart';
import '../widgets/dynamic_island_notification.dart';

class AddExamScreen extends StatefulWidget {
  const AddExamScreen({super.key});

  @override
  State<AddExamScreen> createState() => _AddExamScreenState();
}

class _AddExamScreenState extends State<AddExamScreen> {
  final _jsonController = TextEditingController();
  final _examService = ExamService();
  bool _isProcessing = false;
  ToeicExam? _previewExam;

  void _parseJson() {
    try {
      final String jsonStr = _jsonController.text.trim();
      if (jsonStr.isEmpty) return;

      final Map<String, dynamic> data = jsonDecode(jsonStr);
      setState(() {
        _previewExam = ToeicExam.fromJson(data);
      });
      
      DynamicIslandNotification.show(
        context,
        title: 'Thành công',
        message: 'Phân tích JSON thành công! Hãy kiểm tra dữ liệu bên dưới.',
        type: NotificationType.success,
      );
    } catch (e) {
      DynamicIslandNotification.show(
        context,
        title: 'Lỗi JSON',
        message: 'Lỗi định dạng JSON: $e',
        type: NotificationType.error,
      );
    }
  }

  Future<void> _saveExam() async {
    if (_previewExam == null) return;

    setState(() => _isProcessing = true);
    try {
      await _examService.addExam(_previewExam!);
      if (mounted) {
        DynamicIslandNotification.show(
          context,
          title: 'Đã lưu đề thi',
          message: 'Đề thi đã được lưu thành công lên Cloud!',
          type: NotificationType.success,
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        String errorMsg = e.toString();
        if (e is FirebaseException) {
          switch (e.code) {
            case 'permission-denied':
              errorMsg = 'Bạn không có quyền lưu đề thi vào hệ thống.';
              break;
            case 'unavailable':
              errorMsg = 'Máy chủ bận hoặc mất kết nối. Thử lại sau.';
              break;
            default:
              errorMsg = 'Lỗi Cloud: ${e.message}';
          }
        }
        DynamicIslandNotification.show(
          context,
          title: 'Lỗi lưu đề',
          message: errorMsg,
          type: NotificationType.error,
        );
      }
    } finally {
      if (mounted) setState(() => _isProcessing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool isMobile = MediaQuery.of(context).size.width < 900;

    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      appBar: AppBar(
        title: const Text('Nạp đề thi mới'),
        backgroundColor: const Color(0xFF1E293B),
      ),
      body: isMobile 
          ? SingleChildScrollView(
              child: Column(
                children: [
                  _buildJsonInputSection(300),
                  const Divider(color: Colors.white10),
                  _buildPreviewSection(true),
                ],
              ),
            )
          : Row(
              children: [
                Expanded(flex: 2, child: _buildJsonInputSection(double.infinity)),
                const VerticalDivider(width: 1, color: Colors.white10),
                Expanded(flex: 3, child: _buildPreviewSection(false)),
              ],
            ),
    );
  }

  Widget _buildJsonInputSection(double height) {
    return Container(
      height: height == double.infinity ? null : height,
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text(
            'Dán dữ liệu JSON',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
          ),
          const SizedBox(height: 12),
          Expanded(
            child: TextField(
              controller: _jsonController,
              maxLines: null,
              expands: true,
              style: const TextStyle(fontFamily: 'monospace', fontSize: 12, color: Color(0xFF818CF8)),
              decoration: InputDecoration(
                hintText: '{\n  "id": "ets_2024_test1",\n  "title": "ETS 2024 Test 1",\n  "questions": [...]\n}',
                fillColor: const Color(0xFF1E293B),
                filled: true,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ),
          const SizedBox(height: 20),
          ElevatedButton(
            onPressed: _parseJson,
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.all(20),
              backgroundColor: Colors.blueGrey,
            ),
            child: const Text('KIỂM TRA DỮ LIỆU (PARSE)'),
          ),
        ],
      ),
    );
  }

  Widget _buildPreviewSection(bool isScrollable) {
    if (_previewExam == null) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(40.0),
          child: Text('Hãy dán JSON và nhấn Kiểm tra để xem trước', style: TextStyle(color: Colors.grey)),
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: isScrollable ? MainAxisSize.min : MainAxisSize.max,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Xem trước', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white)),
              ElevatedButton.icon(
                onPressed: _isProcessing ? null : _saveExam,
                icon: _isProcessing ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2)) : const Icon(Icons.cloud_upload_rounded),
                label: const Text('ĐẨY LÊN CLOUD'),
                style: ElevatedButton.styleFrom(backgroundColor: Colors.green, foregroundColor: Colors.white),
              ),
            ],
          ),
          const SizedBox(height: 20),
          _buildPreviewInfo(),
          const SizedBox(height: 20),
          if (isScrollable)
            ..._buildQuestionItems()
          else
            Expanded(child: ListView(children: _buildQuestionItems())),
        ],
      ),
    );
  }

  Widget _buildPreviewInfo() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: Colors.white.withOpacity(0.05), borderRadius: BorderRadius.circular(12)),
      child: Column(
        children: [
          _infoRow('Tiêu đề:', _previewExam!.title),
          _infoRow('ID đề thi:', _previewExam!.id),
          _infoRow('Số câu hỏi:', '${_previewExam!.questions.length} câu'),
          _infoRow('Thời gian:', '${_previewExam!.timeLimitMinutes} phút'),
        ],
      ),
    );
  }

  Widget _infoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          SizedBox(
            width: 100,
            child: Text(label, style: const TextStyle(color: Colors.grey)),
          ),
          Expanded(child: Text(value, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold))),
        ],
      ),
    );
  }

  List<Widget> _buildQuestionItems() {
    return _previewExam!.questions.map((q) {
      return Card(
        color: const Color(0xFF1E293B),
        margin: const EdgeInsets.only(bottom: 8),
        child: ListTile(
          leading: CircleAvatar(child: Text(q.number.toString())),
          title: Text(q.questionText ?? 'Câu hỏi trắc nghiệm', maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: Colors.white, fontSize: 13)),
          subtitle: Text('Part: ${q.part.name.toUpperCase()} | Đáp án: ${String.fromCharCode(65 + q.correctOptionIndex)}', style: const TextStyle(color: Colors.grey, fontSize: 11)),
          trailing: q.imageUrl != null ? const Icon(Icons.image, color: Colors.blue, size: 18) : null,
        ),
      );
    }).toList();
  }
}
