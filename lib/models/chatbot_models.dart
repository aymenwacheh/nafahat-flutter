// lib/models/chatbot_models.dart
class ChatMessage {
  final String text;
  final bool isUser;
  final DateTime timestamp;
  final bool isError;
  final String? category;
  final bool isLoading;

  ChatMessage({
    required this.text,
    required this.isUser,
    required this.timestamp,
    this.isError = false,
    this.category,
    this.isLoading = false,
  });

  factory ChatMessage.user(String text) {
    return ChatMessage(text: text, isUser: true, timestamp: DateTime.now());
  }

  factory ChatMessage.bot(String text, {String? category}) {
    return ChatMessage(
      text: text,
      isUser: false,
      timestamp: DateTime.now(),
      category: category,
    );
  }

  factory ChatMessage.loading() {
    return ChatMessage(
      text: '...',
      isUser: false,
      timestamp: DateTime.now(),
      isLoading: true,
    );
  }

  factory ChatMessage.error(String text) {
    return ChatMessage(
      text: text,
      isUser: false,
      timestamp: DateTime.now(),
      isError: true,
    );
  }
}

class ChatCategory {
  final int id;
  final String nomFr;
  final String nomAr;
  final bool active;

  ChatCategory({
    required this.id,
    required this.nomFr,
    required this.nomAr,
    required this.active,
  });

  factory ChatCategory.fromJson(Map<String, dynamic> json) {
    return ChatCategory(
      id: json['id'],
      nomFr: json['nom_fr'] ?? '',
      nomAr: json['nom_ar'] ?? '',
      active: json['active'] == 1 || json['active'] == true,
    );
  }
}
