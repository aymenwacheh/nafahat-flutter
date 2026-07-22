// lib/widgets/chatbot/chatbot_wrapper.dart
import 'package:flutter/material.dart';
import 'package:nafahat/config/api_config.dart' show ApiConfig;
import 'chatbot_widget.dart';

class ChatbotWrapper extends StatelessWidget {
  final Widget child;
  final String apiBaseUrl;
  final String langue;
  final bool showFloatingButton;
  final double? buttonSize;
  final Color? primaryColor;
  final Color? backgroundColor;

  const ChatbotWrapper({
    super.key,
    required this.child,
    this.apiBaseUrl = ApiConfig.baseUrlConst, // ✅ Utiliser baseUrlConst
    this.langue = 'fr',
    this.showFloatingButton = true,
    this.buttonSize,
    this.primaryColor,
    this.backgroundColor,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        child,
        ChatbotWidget(
          apiBaseUrl: apiBaseUrl, // 👈 On passe mais le widget ne l'utilise pas
          langue: langue,
          showFloatingButton: showFloatingButton,
          buttonSize: buttonSize,
          primaryColor: primaryColor,
          backgroundColor: backgroundColor,
        ),
      ],
    );
  }
}
