// lib/widgets/chatbot/chatbot_button.dart
import 'package:flutter/material.dart';

class ChatbotButton extends StatelessWidget {
  final bool isOpen;
  final VoidCallback onTap;
  final double size;
  final Color primaryColor;

  const ChatbotButton({
    super.key,
    required this.isOpen,
    required this.onTap,
    this.size = 60,
    this.primaryColor = Colors.blue,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      elevation: 8,
      shape: const CircleBorder(),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(size / 2),
        child: Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [primaryColor, primaryColor.withOpacity(0.7)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: primaryColor.withOpacity(0.4),
                blurRadius: 15,
                spreadRadius: 5,
                offset: const Offset(0, 5),
              ),
            ],
          ),
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 300),
            child:
                isOpen
                    ? const Icon(Icons.close, color: Colors.white, size: 30)
                    : Stack(
                      alignment: Alignment.center,
                      children: [
                        const Icon(Icons.chat, color: Colors.white, size: 30),
                        Positioned(
                          top: 8,
                          right: 8,
                          child: Container(
                            width: 12,
                            height: 12,
                            decoration: const BoxDecoration(
                              color: Colors.red,
                              shape: BoxShape.circle,
                            ),
                            child: const Center(
                              child: Text(
                                '1',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 8,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
          ),
        ),
      ),
    );
  }
}
