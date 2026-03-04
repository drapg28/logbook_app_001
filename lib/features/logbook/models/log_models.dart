import 'package:mongo_dart/mongo_dart.dart';

class LogModel {
  final ObjectId? id; 
  final String title;
  final String date;
  final String description;
  final String category; // Category aman, nggak ketinggalan lagi!

  LogModel({
    this.id, 
    required this.title, 
    required this.date, 
    required this.description, 
    required this.category,
  });

  // factory fromMap: Buat bongkar data dari MongoDB Atlas (BSON -> Object)
  factory LogModel.fromMap(Map<String, dynamic> map) {
    return LogModel(
      id: map['_id'] as ObjectId?, // Ambil ID asli dari MongoDB
      title: map['title'] ?? '',
      date: map['date'] ?? '',
      description: map['description'] ?? '',
      category: map['category'] ?? "Umum", // Default "Umum" kalau datanya kosong
    );
  }

  Map<String, dynamic> toMap() {
    return {
      '_id': id ?? ObjectId(),
      'title': title,
      'date': date,
      'description': description,
      'category': category,
    };
  }
}