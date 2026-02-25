import 'package:flutter/foundation.dart';

/// Domain value object representing a chat session.
///
/// Decoupled from Drift-generated types — callers never need to import
/// `app_database.dart` to work with sessions.
@immutable
class ChatSession {
  final int id;

  /// Null means auto-derived from first message content by ChatNotifier.
  final String? title;

  /// 'chat' or 'translation'
  final String mode;

  final DateTime createdAt;
  final DateTime updatedAt;

  const ChatSession({
    required this.id,
    this.title,
    required this.mode,
    required this.createdAt,
    required this.updatedAt,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is ChatSession &&
          other.id == id &&
          other.title == title &&
          other.mode == mode &&
          other.createdAt == createdAt &&
          other.updatedAt == updatedAt);

  @override
  int get hashCode => Object.hash(id, title, mode, createdAt, updatedAt);

  @override
  String toString() =>
      'ChatSession(id: $id, title: $title, mode: $mode, '
      'createdAt: $createdAt, updatedAt: $updatedAt)';
}
