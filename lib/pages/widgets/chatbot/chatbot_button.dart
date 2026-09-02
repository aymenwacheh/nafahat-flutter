// lib/widgets/chatbot/chatbot_button.dart
import 'package:flutter/material.dart';

enum ChatbotButtonStyle {
  chat, // Icône chat classique
  bubble, // Bulle de discussion
  robot, // Robot
  assistant, // Assistant
  support, // Support client
  emoji, // Emoji 🤖
  forum, // Forum
  message, // Message avec badge
}

class ChatbotButton extends StatelessWidget {
  final bool isOpen;
  final VoidCallback onTap;
  final double size;
  final Color primaryColor;
  final ChatbotButtonStyle style;
  final int notificationCount;
  final bool showPulsingAnimation;
  final bool enableBounceEffect;

  const ChatbotButton({
    super.key,
    required this.isOpen,
    required this.onTap,
    this.size = 60,
    this.primaryColor = Colors.blue,
    this.style = ChatbotButtonStyle.chat,
    this.notificationCount = 0,
    this.showPulsingAnimation = true,
    this.enableBounceEffect = true,
  });

  Widget _getIcon(bool isOpen) {
    if (isOpen) {
      return const Icon(Icons.close, color: Colors.white, size: 30);
    }

    switch (style) {
      case ChatbotButtonStyle.chat:
        return _buildIconWithBadge(
          const Icon(Icons.chat, color: Colors.white, size: 30),
        );

      case ChatbotButtonStyle.bubble:
        return _buildIconWithBadge(
          const Icon(Icons.chat_bubble_outline, color: Colors.white, size: 30),
        );

      case ChatbotButtonStyle.robot:
        return _buildIconWithBadge(
          const Icon(Icons.smart_toy, color: Colors.white, size: 30),
        );

      case ChatbotButtonStyle.assistant:
        return _buildIconWithBadge(
          const Icon(Icons.assistant, color: Colors.white, size: 30),
        );

      case ChatbotButtonStyle.support:
        return _buildIconWithBadge(
          const Icon(Icons.headset_mic, color: Colors.white, size: 30),
        );

      case ChatbotButtonStyle.emoji:
        return const Text('🤖', style: TextStyle(fontSize: 30));

      case ChatbotButtonStyle.forum:
        return _buildIconWithBadge(
          const Icon(Icons.forum, color: Colors.white, size: 30),
        );

      case ChatbotButtonStyle.message:
        return _buildIconWithBadge(
          const Icon(Icons.message, color: Colors.white, size: 30),
        );

      default:
        return _buildIconWithBadge(
          const Icon(Icons.chat, color: Colors.white, size: 30),
        );
    }
  }

  Widget _buildIconWithBadge(Widget icon) {
    if (notificationCount == 0) {
      return icon;
    }

    return Stack(
      alignment: Alignment.center,
      children: [
        icon,
        Positioned(
          top: 8,
          right: 8,
          child: Container(
            width: notificationCount > 9 ? 18 : 14,
            height: notificationCount > 9 ? 18 : 14,
            decoration: const BoxDecoration(
              color: Colors.red,
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                notificationCount > 99 ? '99+' : '$notificationCount',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 8,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  // ✅ CORRIGÉ : Opacité clampée entre 0 et 1
  Widget _buildPulsingAnimation() {
    if (!showPulsingAnimation || isOpen || notificationCount == 0) {
      return const SizedBox.shrink();
    }

    return TweenAnimationBuilder(
      tween: Tween<double>(begin: 1.0, end: 1.3),
      duration: const Duration(seconds: 2),
      builder: (context, value, child) {
        // ✅ Clamp pour éviter les valeurs hors limites
        final clampedValue = value.clamp(0.0, 1.3);
        return Container(
          width: size * clampedValue,
          height: size * clampedValue,
          decoration: BoxDecoration(
            color: primaryColor.withOpacity(0.2),
            shape: BoxShape.circle,
          ),
        );
      },
    );
  }

  // ✅ CORRIGÉ : Animation avec opacité clampée
  Widget _buildBouncingIconWithBadge() {
    final icon = _getIcon(isOpen);

    if (!enableBounceEffect || isOpen) {
      return icon;
    }

    return TweenAnimationBuilder(
      tween: Tween<double>(begin: 0.0, end: 1.0),
      duration: const Duration(milliseconds: 800),
      curve: Curves.elasticOut,
      builder: (context, value, child) {
        // ✅ Clamp pour éviter les valeurs hors limites
        final clampedValue = value.clamp(0.0, 1.0);
        final opacityValue = (0.3 + clampedValue * 0.7).clamp(0.0, 1.0);
        final scaleValue = (0.5 + clampedValue * 0.5).clamp(0.0, 1.0);
        final translateValue = ((1 - clampedValue) * 20).clamp(0.0, 20.0);

        return Transform.scale(
          scale: scaleValue,
          child: Transform.translate(
            offset: Offset(0, -translateValue),
            child: Opacity(
              opacity: opacityValue, // ✅ Opacité toujours entre 0 et 1
              child: child,
            ),
          ),
        );
      },
      child: icon,
    );
  }

  // ✅ CORRIGÉ : Animation avec opacité clampée
  Widget _buildBounceIcon(Widget icon) {
    if (!enableBounceEffect) {
      return icon;
    }

    return TweenAnimationBuilder(
      tween: Tween<double>(begin: 0.0, end: 1.0),
      duration: const Duration(milliseconds: 800),
      curve: Curves.elasticOut,
      builder: (context, value, child) {
        // ✅ Clamp pour éviter les valeurs hors limites
        final clampedValue = value.clamp(0.0, 1.0);
        final opacityValue = (0.3 + clampedValue * 0.7).clamp(0.0, 1.0);
        final scaleValue = (1 + (1 - clampedValue) * 0.2).clamp(0.0, 1.2);
        final translateValue = ((1 - clampedValue) * 15).clamp(0.0, 15.0);

        return Transform.scale(
          scale: scaleValue,
          child: Transform.translate(
            offset: Offset(0, -translateValue),
            child: Opacity(
              opacity: opacityValue, // ✅ Opacité toujours entre 0 et 1
              child: child,
            ),
          ),
        );
      },
      child: icon,
    );
  }

  // ✅ CORRIGÉ : Animation de rebond avec opacité clampée
  Widget _buildBouncingIcon(Widget icon) {
    if (!enableBounceEffect) {
      return icon;
    }

    return TweenAnimationBuilder(
      tween: Tween<double>(begin: 0.0, end: 1.0),
      duration: const Duration(milliseconds: 1000),
      curve: Curves.elasticOut,
      builder: (context, value, child) {
        // ✅ Clamp pour éviter les valeurs hors limites
        final clampedValue = value.clamp(0.0, 1.0);
        final opacityValue = clampedValue.clamp(0.0, 1.0);
        final scaleValue = (1.0 + (1.0 - clampedValue) * 0.2).clamp(0.8, 1.2);
        final translateValue = ((1.0 - clampedValue) * 15).clamp(0.0, 15.0);

        return Transform.scale(
          scale: scaleValue,
          child: Transform.translate(
            offset: Offset(0, -translateValue),
            child: Opacity(
              opacity: opacityValue, // ✅ Opacité toujours entre 0 et 1
              child: child,
            ),
          ),
        );
      },
      child: icon,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.center,
      children: [
        _buildPulsingAnimation(),
        Material(
          elevation: isOpen ? 12 : 8,
          shape: const CircleBorder(),
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(size / 2),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              width: isOpen ? size * 1.1 : size,
              height: isOpen ? size * 1.1 : size,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    isOpen ? primaryColor.withOpacity(0.9) : primaryColor,
                    primaryColor.withOpacity(isOpen ? 0.6 : 0.7),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: primaryColor.withOpacity(0.4),
                    blurRadius: isOpen ? 20 : 15,
                    spreadRadius: isOpen ? 8 : 5,
                    offset: const Offset(0, 5),
                  ),
                ],
              ),
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 300),
                transitionBuilder: (Widget child, Animation<double> animation) {
                  return ScaleTransition(scale: animation, child: child);
                },
                child: _buildBouncingIconWithBadge(),
              ),
            ),
          ),
        ),
      ],
    );
  }
}