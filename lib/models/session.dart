import 'package:hive/hive.dart';

part 'session.g.dart';

@HiveType(typeId: 1)
class Session extends HiveObject {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final DateTime startTime;

  @HiveField(2)
  final int durationSeconds;

  @HiveField(3)
  final String? category;

  Session({
    required this.id,
    required this.startTime,
    required this.durationSeconds,
    this.category,
  });

  /// Factory constructor to create a Session from JSON (from Supabase)
  factory Session.fromJson(Map<String, dynamic> json) {
    return Session(
      id: json['id'] as String,
      startTime: DateTime.parse(json['start_time'] as String).toLocal(),
      durationSeconds: json['duration_seconds'] as int,
      category: json['category'] as String?,
    );
  }

  /// Convert this Session to JSON (to send to Supabase)
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'start_time': startTime.toUtc().toIso8601String(),
      'duration_seconds': durationSeconds,
      'category': category,
    };
  }
}
