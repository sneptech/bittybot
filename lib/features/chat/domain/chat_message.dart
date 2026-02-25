import 'package:flutter/foundation.dart';

/// Domain value object representing a single message within a chat session.
///
/// Decoupled from Drift-generated types — callers never need to import
/// `app_database.dart` to work with messages.
@immutable
class ChatMessage {
  final int id;
  final int sessionId;

  /// 'user' or 'assistant'
  final String role;

  final String content;

  /// True when the user stopped generation before the model finished.
  final bool isTruncated;

  final DateTime createdAt;

  const ChatMessage({
    required this.id,
    required this.sessionId,
    required this.role,
    required this.content,
    this.isTruncated = false,
    required this.createdAt,
  });

  /// Creates a copy with updated content (used during streaming to append tokens).
  ChatMessage copyWith({String? content, bool? isTruncated}) {
    return ChatMessage(
      id: id,
      sessionId: sessionId,
      role: role,
      content: content ?? this.content,
      isTruncated: isTruncated ?? this.isTruncated,
      createdAt: createdAt,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is ChatMessage &&
          other.id == id &&
          other.sessionId == sessionId &&
          other.role == role &&
          other.content == content &&
          other.isTruncated == isTruncated &&
          other.createdAt == createdAt);

  @override
  int get hashCode =>
      Object.hash(id, sessionId, role, content, isTruncated, createdAt);

  @override
  String toString() =>
      'ChatMessage(id: $id, sessionId: $sessionId, role: $role, '
      'isTruncated: $isTruncated, createdAt: $createdAt)';
}
