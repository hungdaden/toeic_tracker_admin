import 'dart:convert';

class ToeicExam {
  final String id;
  final String title;
  final String? description;
  final List<ToeicQuestion> questions;
  final int timeLimitMinutes;

  ToeicExam({
    required this.id,
    required this.title,
    this.description,
    required this.questions,
    this.timeLimitMinutes = 120,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'title': title,
    'description': description,
    'timeLimitMinutes': timeLimitMinutes,
    'questions': questions.map((x) => x.toJson()).toList(),
  };

  factory ToeicExam.fromJson(Map<String, dynamic> json) => ToeicExam(
    id: json['id'],
    title: json['title'],
    description: json['description'],
    timeLimitMinutes: json['timeLimitMinutes'] ?? 120,
    questions: (json['questions'] as List<dynamic>?)
        ?.map((x) => ToeicQuestion.fromJson(x))
        .toList() ?? [],
  );
}

enum QuestionPart { part1, part2, part3, part4, part5, part6, part7 }

class ToeicQuestion {
  final int number;
  final QuestionPart part;
  final String? questionText;
  final List<String> options;
  final int correctOptionIndex; 
  final String? imageUrl;
  final String? audioUrl;
  final String? passage; 

  ToeicQuestion({
    required this.number,
    required this.part,
    this.questionText,
    required this.options,
    required this.correctOptionIndex,
    this.imageUrl,
    this.audioUrl,
    this.passage,
  });

  Map<String, dynamic> toJson() => {
    'number': number,
    'part': part.index,
    'questionText': questionText,
    'options': options,
    'correctOptionIndex': correctOptionIndex,
    'imageUrl': imageUrl,
    'audioUrl': audioUrl,
    'passage': passage,
  };

  factory ToeicQuestion.fromJson(Map<String, dynamic> json) => ToeicQuestion(
    number: json['number'],
    part: QuestionPart.values[json['part']],
    questionText: json['questionText'],
    options: List<String>.from(json['options']),
    correctOptionIndex: json['correctOptionIndex'],
    imageUrl: json['imageUrl'],
    audioUrl: json['audioUrl'],
    passage: json['passage'],
  );
}
