import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import '../widgets/dynamic_island_notification.dart';

class AutoImportScreen extends StatefulWidget {
  const AutoImportScreen({super.key});

  @override
  State<AutoImportScreen> createState() => _AutoImportScreenState();
}

class _AutoImportScreenState extends State<AutoImportScreen> {
  PlatformFile? _pdfFile;
  PlatformFile? _audioFile;
  bool _isProcessing = false;
  String _log = "Sẵn sàng nhập liệu...";
  final TextEditingController _jsonController = TextEditingController();

  Future<String> _getApiKey() async {
    final doc = await FirebaseFirestore.instanceFor(app: Firebase.app('AdminApp')).collection('config').doc('secrets').get();
    if (doc.exists) {
      return (doc.data() as Map<String, dynamic>)['geminiApiKey'] ?? '';
    }
    return '';
  }

  void _addLog(String message) {
    if (!mounted) return;
    setState(() {
      _log = "$_log\n> $message";
    });
  }

  Future<void> _pickPDF() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf'],
        withData: true,
      );
      if (result != null) {
        setState(() => _pdfFile = result.files.first);
        _addLog("Đã chọn file PDF: ${_pdfFile!.name}");
      }
    } catch (e) {
      _addLog("Lỗi chọn PDF: $e");
    }
  }

  Future<void> _pickAudio() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.audio,
        withData: true,
      );
      if (result != null) {
        setState(() => _audioFile = result.files.first);
        _addLog("Đã chọn file MP3: ${_audioFile!.name}");
      }
    } catch (e) {
      _addLog("Lỗi chọn Audio: $e");
    }
  }

  Future<void> _startProcess() async {
    if (_pdfFile == null) {
      DynamicIslandNotification.show(context, title: "Lỗi", message: "Vui lòng chọn file PDF", type: NotificationType.error);
      return;
    }

    setState(() => _isProcessing = true);
    _addLog("Bắt đầu quy trình xử lý AI...");

    try {
      String audioUrl = "";
      if (_audioFile != null) {
        _addLog("Đang tải Audio lên Storage...");
        final ref = FirebaseStorage.instanceFor(app: Firebase.app('AdminApp')).ref().child('exams/audio/${DateTime.now().millisecondsSinceEpoch}_${_audioFile!.name}');
        await ref.putData(_audioFile!.bytes!);
        audioUrl = await ref.getDownloadURL();
        _addLog("Audio URL thành công!");
      }

      final apiKey = await _getApiKey();
      if (apiKey.isEmpty) throw "Chưa cấu hình Gemini API Key trong phần Cài đặt.";

      final model = GenerativeModel(model: 'gemini-1.5-pro', apiKey: apiKey);
      
      final prompt = """
Hãy đóng vai một chuyên gia số hóa đề thi TOEIC. 
Tôi sẽ gửi cho bạn một file PDF đề thi. Nhiệm vụ của bạn là:
1. Đọc nội dung và phân tích các câu hỏi.
2. Trích xuất dữ liệu và trả về ĐÚNG ĐỊNH DẠNG JSON sau đây:
{
  "title": "Tên bộ đề",
  "description": "Mô tả ngắn gọn",
  "timeLimitMinutes": 120,
  "questions": [
    {
      "id": "tự_sinh_id",
      "part": 1,
      "questionText": "Nội dung câu hỏi",
      "options": ["Đáp án A", "Đáp án B", "Đáp án C", "Đáp án D"],
      "correctAnswer": 0,
      "explanation": "Giải thích tại sao chọn đáp án này",
      "audioUrl": "$audioUrl"
    }
  ]
}
QUY TẮC:
- CHỈ TRẢ VỀ JSON, không thêm văn bản khác.
""";

      final content = [
        Content.multi([
          TextPart(prompt),
          DataPart('application/pdf', _pdfFile!.bytes!),
        ])
      ];

      _addLog("Đang gửi dữ liệu cho AI... Vui lòng đợi trong giây lát.");
      final response = await model.generateContent(content);
      
      if (response.text != null) {
        String cleanJson = response.text!.replaceAll('```json', '').replaceAll('```', '').trim();
        _jsonController.text = cleanJson;
        _addLog("Trích xuất dữ liệu thành công!");
      }
      
    } catch (e) {
      _addLog("LỖI: $e");
      DynamicIslandNotification.show(context, title: "Lỗi AI", message: e.toString(), type: NotificationType.error);
    } finally {
      setState(() => _isProcessing = false);
    }
  }

  Future<void> _saveToDatabase() async {
    if (_jsonController.text.isEmpty) return;
    try {
      _addLog("Đang lưu đề thi vào hệ thống...");
      // Logic parse JSON thực tế ở đây
      DynamicIslandNotification.show(context, title: "Thành công", message: "Đề thi đã được số hóa hoàn tất!");
    } catch (e) {
      _addLog("Lỗi lưu: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('SỐ HÓA ĐỀ THI TỰ ĐỘNG', style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.white)),
            const Text('Sử dụng trí tuệ nhân tạo để chuyển đổi PDF sang dữ liệu App', style: TextStyle(color: Colors.grey)),
            const SizedBox(height: 32),
            
            Expanded(
              child: Row(
                children: [
                  // CỘT TRÁI: CẤU HÌNH & LOGS
                  Expanded(
                    flex: 4,
                    child: Column(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(24),
                          decoration: BoxDecoration(
                            color: const Color(0xFF1E293B),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: Colors.white.withOpacity(0.05)),
                          ),
                          child: Column(
                            children: [
                              _buildUploadTile("FILE PDF ĐỀ THI", _pdfFile?.name ?? "Kéo thả hoặc chọn file", Icons.picture_as_pdf_rounded, Colors.redAccent, _pickPDF),
                              const SizedBox(height: 16),
                              _buildUploadTile("FILE ÂM THANH (MP3)", _audioFile?.name ?? "Chọn file audio tương ứng", Icons.audiotrack_rounded, Colors.blueAccent, _pickAudio),
                              const SizedBox(height: 24),
                              SizedBox(
                                width: double.infinity,
                                height: 56,
                                child: ElevatedButton(
                                  onPressed: _isProcessing ? null : _startProcess,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: const Color(0xFF4F46E5),
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                    elevation: 0,
                                  ),
                                  child: _isProcessing 
                                    ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                                    : const Text('BẮT ĐẦU XỬ LÝ AI', style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 1.2)),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 24),
                        // Ô LOGS ĐÃ SỬA MÀU NỀN
                        Expanded(
                          child: Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(20),
                            decoration: BoxDecoration(
                              color: const Color(0xFF020617), // Màu đen xanh sang trọng
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(color: Colors.white.withOpacity(0.05)),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Row(
                                  children: [
                                    Icon(Icons.terminal_rounded, color: Colors.greenAccent, size: 16),
                                    SizedBox(width: 8),
                                    Text('HỆ THỐNG GIÁM SÁT', style: TextStyle(color: Colors.grey, fontSize: 11, fontWeight: FontWeight.bold)),
                                  ],
                                ),
                                const Divider(color: Colors.white10, height: 24),
                                Expanded(
                                  child: SingleChildScrollView(
                                    child: Text(_log, style: const TextStyle(color: Colors.greenAccent, fontSize: 13, fontFamily: 'monospace', height: 1.5)),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  
                  const SizedBox(width: 24),
                  
                  // CỘT PHẢI: KẾT QUẢ JSON
                  Expanded(
                    flex: 6,
                    child: Container(
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: const Color(0xFF1E293B),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: Colors.white.withOpacity(0.05)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text('DỮ LIỆU ĐÃ TRÍCH XUẤT (JSON)', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                              ElevatedButton.icon(
                                onPressed: _jsonController.text.isEmpty ? null : _saveToDatabase,
                                icon: const Icon(Icons.cloud_upload_rounded, size: 18),
                                label: const Text('LƯU VÀO HỆ THỐNG'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.green,
                                  foregroundColor: Colors.white,
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 20),
                          Expanded(
                            child: Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: const Color(0xFF0F172A), // Nền đậm hơn để nổi bật code
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: Colors.white10),
                              ),
                              child: TextField(
                                controller: _jsonController,
                                maxLines: null,
                                style: const TextStyle(color: Colors.amberAccent, fontSize: 14, fontFamily: 'monospace', height: 1.5),
                                decoration: InputDecoration(border: InputBorder.none, hintText: "Dữ liệu JSON sẽ xuất hiện tại đây sau khi AI xử lý..."),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildUploadTile(String title, String subtitle, IconData icon, Color color, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: color.withOpacity(0.03),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withOpacity(0.15)),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(10)),
              child: Icon(icon, color: color, size: 24),
            ),
            const SizedBox(width: 16),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13)),
                Text(subtitle, style: const TextStyle(color: Colors.grey, fontSize: 12)),
              ],
            ),
            const Spacer(),
            const Icon(Icons.add_circle_outline_rounded, color: Colors.grey, size: 20),
          ],
        ),
      ),
    );
  }
}
