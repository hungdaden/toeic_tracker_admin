import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import '../models/exam_model.dart';
import '../widgets/dynamic_island_notification.dart';

class QuestionBankScreen extends StatefulWidget {
  const QuestionBankScreen({super.key});

  @override
  State<QuestionBankScreen> createState() => _QuestionBankScreenState();
}

class _QuestionBankScreenState extends State<QuestionBankScreen> {
  String _searchQuery = '';
  QuestionPart? _selectedPart;
  final TextEditingController _searchController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      body: Column(
        children: [
          // THANH CÔNG CỤ TÌM KIẾM & LỌC
          Container(
            padding: const EdgeInsets.all(24),
            decoration: const BoxDecoration(
              color: Color(0xFF1E293B),
              border: Border(bottom: BorderSide(color: Colors.white10)),
            ),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _searchController,
                    style: const TextStyle(color: Colors.white),
                    onChanged: (v) => setState(() => _searchQuery = v),
                    decoration: InputDecoration(
                      hintText: 'Tìm kiếm câu hỏi...',
                      hintStyle: const TextStyle(color: Colors.grey),
                      prefixIcon: const Icon(Icons.search, color: Colors.grey),
                      filled: true,
                      fillColor: const Color(0xFF0F172A),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                DropdownButton<QuestionPart>(
                  value: _selectedPart,
                  dropdownColor: const Color(0xFF1E293B),
                  hint: const Text('Lọc theo Part', style: TextStyle(color: Colors.grey)),
                  style: const TextStyle(color: Colors.white),
                  underline: const SizedBox(),
                  onChanged: (v) => setState(() => _selectedPart = v),
                  items: [
                    const DropdownMenuItem(value: null, child: Text('Tất cả Part')),
                    ...QuestionPart.values.map((p) => DropdownMenuItem(
                      value: p,
                      child: Text('Part ${p.index + 1}'),
                    )),
                  ],
                ),
              ],
            ),
          ),
          
          // DANH SÁCH CÂU HỎI
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instanceFor(app: Firebase.app('AdminApp')).collection('questions').snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
                
                var docs = snapshot.data!.docs;
                
                // Lọc dữ liệu tại Client cho mượt
                var filteredDocs = docs.where((doc) {
                  final data = doc.data() as Map<String, dynamic>;
                  final text = (data['questionText'] ?? '').toString().toLowerCase();
                  final passage = (data['passage'] ?? '').toString().toLowerCase();
                  final partIndex = data['part'] as int;
                  
                  bool matchesSearch = text.contains(_searchQuery.toLowerCase()) || 
                                     passage.contains(_searchQuery.toLowerCase());
                  bool matchesPart = _selectedPart == null || partIndex == _selectedPart!.index;
                  
                  return matchesSearch && matchesPart;
                }).toList();

                if (filteredDocs.isEmpty) {
                  return const Center(child: Text('Không tìm thấy câu hỏi nào.', style: TextStyle(color: Colors.grey)));
                }

                return ListView.builder(
                  padding: const EdgeInsets.all(24),
                  itemCount: filteredDocs.length,
                  itemBuilder: (context, index) {
                    final data = filteredDocs[index].data() as Map<String, dynamic>;
                    final question = ToeicQuestion.fromJson(data);
                    return _buildQuestionCard(question, filteredDocs[index].id);
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuestionCard(ToeicQuestion q, String docId) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(color: Colors.indigoAccent.withOpacity(0.1), borderRadius: BorderRadius.circular(6)),
                child: Text('PART ${q.part.index + 1}', style: const TextStyle(color: Colors.indigoAccent, fontWeight: FontWeight.bold, fontSize: 12)),
              ),
              IconButton(
                icon: const Icon(Icons.edit_note_rounded, color: Colors.blueAccent),
                onPressed: () => _showEditDialog(q, docId),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (q.passage != null) ...[
            Text(q.passage!, style: const TextStyle(color: Colors.grey, fontSize: 13, fontStyle: FontStyle.italic), maxLines: 2, overflow: TextOverflow.ellipsis),
            const SizedBox(height: 8),
          ],
          Text(q.questionText ?? '(Không có đề bài - Hãy xem ảnh/audio)', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          Wrap(
            spacing: 12,
            runSpacing: 8,
            children: q.options.asMap().entries.map((e) {
              bool isCorrect = e.key == q.correctOptionIndex;
              return Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: isCorrect ? Colors.green.withOpacity(0.1) : Colors.white.withOpacity(0.05),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: isCorrect ? Colors.green : Colors.transparent),
                ),
                child: Text('${String.fromCharCode(65 + e.key)}. ${e.value}', style: TextStyle(color: isCorrect ? Colors.green : Colors.grey, fontSize: 13)),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  void _showEditDialog(ToeicQuestion q, String docId) {
    final titleController = TextEditingController(text: q.questionText);
    final passageController = TextEditingController(text: q.passage);
    final List<TextEditingController> optionControllers = 
        q.options.map((opt) => TextEditingController(text: opt)).toList();
    int correctIndex = q.correctOptionIndex;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          backgroundColor: const Color(0xFF1E293B),
          title: Text('SỬA CÂU HỎI - PART ${q.part.index + 1}', style: const TextStyle(color: Colors.white)),
          content: SingleChildScrollView(
            child: SizedBox(
              width: 600,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: passageController,
                    maxLines: 3,
                    style: const TextStyle(color: Colors.white),
                    decoration: const InputDecoration(labelText: 'Đoạn văn (Passage)', labelStyle: TextStyle(color: Colors.grey)),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: titleController,
                    maxLines: 2,
                    style: const TextStyle(color: Colors.white),
                    decoration: const InputDecoration(labelText: 'Câu hỏi', labelStyle: TextStyle(color: Colors.grey)),
                  ),
                  const SizedBox(height: 24),
                  const Text('CÁC ĐÁP ÁN (Chọn vòng tròn để đặt làm đáp án đúng)', style: TextStyle(color: Colors.grey, fontSize: 12)),
                  const SizedBox(height: 12),
                  ...List.generate(4, (index) => Padding(
                    padding: const EdgeInsets.only(bottom: 8.0),
                    child: Row(
                      children: [
                        Radio<int>(
                          value: index,
                          groupValue: correctIndex,
                          activeColor: Colors.green,
                          onChanged: (v) => setDialogState(() => correctIndex = v!),
                        ),
                        Expanded(
                          child: TextField(
                            controller: optionControllers[index],
                            style: const TextStyle(color: Colors.white),
                            decoration: InputDecoration(
                              hintText: 'Đáp án ${String.fromCharCode(65 + index)}',
                              filled: true,
                              fillColor: Colors.white.withOpacity(0.05),
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                            ),
                          ),
                        ),
                      ],
                    ),
                  )),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('HỦY', style: TextStyle(color: Colors.grey))),
            ElevatedButton(
              onPressed: () async {
                try {
                  await FirebaseFirestore.instanceFor(app: Firebase.app('AdminApp')).collection('questions').doc(docId).update({
                    'questionText': titleController.text.trim(),
                    'passage': passageController.text.trim(),
                    'correctOptionIndex': correctIndex,
                    'options': optionControllers.map((c) => c.text.trim()).toList(),
                  });
                  if (mounted) {
                    Navigator.pop(context);
                    DynamicIslandNotification.show(
                      context,
                      title: 'Đã cập nhật',
                      message: 'Nội dung câu hỏi đã được lưu!',
                    );
                  }
                } catch (e) {
                  String errorMsg = e.toString();
                  if (e is FirebaseException) {
                    errorMsg = 'Lỗi cập nhật: ${e.message}';
                  }
                  DynamicIslandNotification.show(
                    context,
                    title: 'Lỗi',
                    message: errorMsg,
                    type: NotificationType.error,
                  );
                }
              },
              style: ElevatedButton.styleFrom(backgroundColor: Colors.indigoAccent),
              child: const Text('LƯU THAY ĐỔI'),
            ),
          ],
        ),
      ),
    );
  }
}
