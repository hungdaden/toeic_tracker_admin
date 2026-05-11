class MunAIChatMessage {
  final String role; // 'user' or 'model'
  final String text;

  MunAIChatMessage({required this.role, required this.text});

  Map<String, dynamic> toJson() => {
    'role': role,
    'text': text,
  };

  factory MunAIChatMessage.fromJson(Map<String, dynamic> json) => MunAIChatMessage(
    role: json['role'] ?? 'user',
    text: json['text'] ?? '',
  );
}

class MunAIChatSession {
  final String id;
  String title;
  final DateTime createdAt;
  List<MunAIChatMessage> messages;

  MunAIChatSession({
    String? id,
    this.title = 'New Chat',
    DateTime? createdAt,
    List<MunAIChatMessage>? messages,
  })  : id = id ?? DateTime.now().millisecondsSinceEpoch.toString(),
        createdAt = createdAt ?? DateTime.now(),
        messages = messages ?? [];

  Map<String, dynamic> toJson() => {
    'id': id,
    'title': title,
    'createdAt': createdAt.toIso8601String(),
    'messages': messages.map((m) => m.toJson()).toList(),
  };

  factory MunAIChatSession.fromJson(Map<String, dynamic> json) => MunAIChatSession(
    id: json['id'],
    title: json['title'] ?? 'New Chat',
    createdAt: json['createdAt'] != null ? DateTime.parse(json['createdAt']) : DateTime.now(),
    messages: (json['messages'] as List<dynamic>?)
        ?.map((m) => MunAIChatMessage.fromJson(m as Map<String, dynamic>))
        .toList() ?? [],
  );
}
