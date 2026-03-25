import 'package:hive/hive.dart';
import 'package:mongo_dart/mongo_dart.dart' show ObjectId;

part 'log_models.g.dart';

@HiveType(typeId: 0)
class LogModel {
  @HiveField(0)
  final String? id;

  @HiveField(1)
  final String title;

  @HiveField(2)
  final String description;

  @HiveField(3)
  final String category;

  @HiveField(4)
  final String date;

  @HiveField(5)
  final String authorId;

  @HiveField(6)
  final String teamId;

  @HiveField(7)
  final bool isPublic;

  LogModel({
    this.id,
    required this.title,
    required this.description,
    required this.category,
    required this.date,
    required this.authorId,
    required this.teamId,
    this.isPublic = false,
  });

  Map<String, dynamic> toMap() {
    return {
      '_id': id,
      'title': title,
      'description': description,
      'category': category,
      'date': date,
      'authorId': authorId,
      'teamId': teamId,
      'isPublic': isPublic,
    };
  }

  factory LogModel.fromMap(Map<String, dynamic> map) {
    String? extractId(dynamic raw) {
      if (raw == null) return null;
      if (raw is ObjectId) return raw.oid;      
      final str = raw.toString();
      final match = RegExp(r'ObjectId\("([a-f0-9]{24})"\)').firstMatch(str);
      if (match != null) return match.group(1);
      return str;
    }

    return LogModel(
      id: extractId(map['_id']),
      title: map['title'] as String? ?? '',
      description: map['description'] as String? ?? '',
      category: map['category'] as String? ?? 'Mechanical',
      date: map['date'] as String? ?? DateTime.now().toIso8601String(),
      authorId: map['authorId'] as String? ?? 'unknown_user',
      teamId: map['teamId'] as String? ?? 'no_team',
      isPublic: map['isPublic'] as bool? ?? false,
    );
  }
}