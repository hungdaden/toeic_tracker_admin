import 'toeic_score.dart';
import 'mun_ai_chat.dart';

class UserModel {
  final String id;
  String? authUid; 
  String name;
  DateTime dateOfBirth;
  int targetScore;
  String? avatarUrl;
  bool isFourSkills;
  List<ToeicScore> scores;
  List<MunAIChatSession> chatHistory;
  String? groupId;
  String? groupRole;
  String? pendingGroupId;
  bool isDisabled; 
  bool isAdmin; // Thêm trường isAdmin chính thức

  UserModel({
    required this.id,
    this.authUid,
    required this.name,
    required this.dateOfBirth,
    this.targetScore = 500,
    this.avatarUrl,
    this.isFourSkills = false,
    this.groupId,
    this.groupRole,
    this.pendingGroupId,
    this.isDisabled = false,
    this.isAdmin = false,
    List<ToeicScore>? scores,
    List<MunAIChatSession>? chatHistory,
  })  : scores = scores ?? [],
        chatHistory = chatHistory ?? [];

  int get currentStreak {
    if (scores.isEmpty) return 0;

    // Lấy danh sách các ngày học duy nhất (không tính giờ phút giây)
    final uniqueDates = scores
        .map((s) => DateTime.utc(s.date.year, s.date.month, s.date.day))
        .toSet()
        .toList();
    uniqueDates.sort((a, b) => b.compareTo(a)); // Sắp xếp từ mới nhất đến cũ nhất

    final now = DateTime.now();
    final today = DateTime.utc(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));

    // Nếu ngày học gần nhất không phải hôm nay VÀ cũng không phải hôm qua 
    // -> Nghĩa là đã bỏ lỡ việc học -> Streak = 0
    if (uniqueDates[0].isBefore(yesterday)) {
      return 0;
    }

    int streak = 1;
    for (int i = 0; i < uniqueDates.length - 1; i++) {
      final diff = uniqueDates[i].difference(uniqueDates[i + 1]).inDays;
      if (diff == 1) {
        streak++;
      } else {
        // Gặp một khoảng ngắt quãng -> Dừng đếm
        break;
      }
    }
    return streak;
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'authUid': authUid,
    'name': name,
    'dateOfBirth': dateOfBirth.toIso8601String(),
    'targetScore': targetScore,
    'avatarUrl': avatarUrl,
    'isFourSkills': isFourSkills,
    'groupId': groupId,
    'groupRole': groupRole,
    'pendingGroupId': pendingGroupId,
    'isDisabled': isDisabled,
    'isAdmin': isAdmin,
    'scores': scores.map((x) => x.toJson()).toList(),
    'chatHistory': chatHistory.map((x) => x.toJson()).toList(),
  };

  factory UserModel.fromJson(Map<String, dynamic> json) => UserModel(
    id: json['id'],
    authUid: json['authUid'],
    name: json['name'],
    dateOfBirth: DateTime.parse(json['dateOfBirth']),
    targetScore: json['targetScore'] ?? 500,
    avatarUrl: json['avatarUrl'],
    isFourSkills: json['isFourSkills'] ?? false,
    groupId: json['groupId'],
    groupRole: json['groupRole'],
    pendingGroupId: json['pendingGroupId'],
    isDisabled: json['isDisabled'] ?? false,
    isAdmin: json['isAdmin'] ?? false,
    scores: (json['scores'] as List<dynamic>?)
            ?.map((x) => ToeicScore.fromJson(x))
            .toList() ?? [],
    chatHistory: (json['chatHistory'] as List<dynamic>?)
            ?.map((x) => MunAIChatSession.fromJson(x as Map<String, dynamic>))
            .toList() ?? [],
  );
}
