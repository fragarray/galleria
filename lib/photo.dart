import 'package:supabase_flutter/supabase_flutter.dart';


class Photo {
  final int id;
  final String filePath;
  final String? location;
  final String? author;
  final String? description;
  final DateTime createdAt;

  Photo({
    required this.id,
    required this.filePath,
    this.location,
    this.author,
    this.description,
    required this.createdAt,
  });

  String get publicUrl {
    final supabase = Supabase.instance.client;
    return supabase.storage.from('photos').getPublicUrl(filePath);
  }

  factory Photo.fromJson(Map<String, dynamic> json) {
    return Photo(
      id: json['id'],
      filePath: json['file_path'],
      location: json['location'],
      author: json['author'],
      description: json['description'],
      createdAt: DateTime.parse(json['created_at']),
    );
  }

  @override
  String toString() {
    return 'Photo{id: $id, filePath: $filePath, createdAt: $createdAt}';
  }
}
