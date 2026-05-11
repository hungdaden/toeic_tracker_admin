class ToeicScore {
  final String id;
  final DateTime date;
  final int listeningScore;
  final int readingScore;
  final int? speakingScore;
  final int? writingScore;

  ToeicScore({
    required this.id,
    required this.date,
    required this.listeningScore,
    required this.readingScore,
    this.speakingScore,
    this.writingScore,
  });

  int calculateTotal(bool isFourSkills) {
    if (isFourSkills) {
      return listeningScore + readingScore + (speakingScore ?? 0) + (writingScore ?? 0);
    }
    return listeningScore + readingScore;
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'date': date.toIso8601String(),
        'listeningScore': listeningScore,
        'readingScore': readingScore,
        'speakingScore': speakingScore,
        'writingScore': writingScore,
      };

  factory ToeicScore.fromJson(Map<String, dynamic> json) => ToeicScore(
        id: json['id'],
        date: DateTime.parse(json['date']),
        listeningScore: json['listeningScore'],
        readingScore: json['readingScore'],
        speakingScore: json['speakingScore'],
        writingScore: json['writingScore'],
      );
}
