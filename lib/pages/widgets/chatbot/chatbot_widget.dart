// lib/widgets/chatbot/chatbot_widget.dart
import 'package:flutter/material.dart';
import '../../../models/chatbot_models.dart';
import '../../../services/chatbot_service.dart';
import '../../../config/api_config.dart';
import 'chatbot_button.dart';
import 'chatbot_window.dart';

class ChatbotWidget extends StatefulWidget {
  final String apiBaseUrl;
  final String langue;
  final bool showFloatingButton;
  final double? buttonSize;
  final Color? primaryColor;
  final Color? backgroundColor;

  const ChatbotWidget({
    super.key,
    this.apiBaseUrl = ApiConfig.baseUrl,
    this.langue = 'fr',
    this.showFloatingButton = true,
    this.buttonSize,
    this.primaryColor,
    this.backgroundColor,
  });

  @override
  State<ChatbotWidget> createState() => _ChatbotWidgetState();
}

class _ChatbotWidgetState extends State<ChatbotWidget>
    with SingleTickerProviderStateMixin {
  bool _isOpen = false;
  late ChatbotService _chatbotService;
  final List<ChatMessage> _messages = [];
  bool _isLoading = false;
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;

  // Suggestions rapides
  final List<String> _quickActions = [
    'Formations',
    'Prix',
    'Inscription',
    'Contact',
    'Formateurs',
    'Durée',
  ];

  @override
  void initState() {
    super.initState();

    // ✅ Le ChatbotService utilise maintenant TrainingService.apiBaseUrl en interne
    // On n'a plus besoin de passer baseUrl
    _chatbotService = ChatbotService(); // 👈 SIMPLIFIÉ

    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOutBack),
    );
    _addInitialMessage();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _addInitialMessage() {
    _messages.add(
      ChatMessage.bot(
        widget.langue == 'fr'
            ? '👋 Bonjour ! Je suis l\'assistant Nafahat.\n\n'
                'Posez-moi une question sur :\n'
                '• 📚 Nos formations\n'
                '• 💰 Les tarifs\n'
                '• 📝 Les inscriptions\n'
                '• 📞 Le contact\n'
                '• 👨‍🏫 Les formateurs'
            : '👋 مرحباً! أنا مساعد نفاحة.\n\n'
                'اسألني عن:\n'
                '• 📚 التكوينات\n'
                '• 💰 الأسعار\n'
                '• 📝 التسجيل\n'
                '• 📞 الاتصال\n'
                '• 👨‍🏫 المؤطرين',
      ),
    );
  }

  void _toggleChatbot() {
    setState(() {
      _isOpen = !_isOpen;
      if (_isOpen) {
        _animationController.forward();
      } else {
        _animationController.reverse();
      }
    });
  }

  Future<void> _sendMessage(String message) async {
    if (message.trim().isEmpty) return;

    // Ajouter le message de l'utilisateur
    setState(() {
      _messages.add(ChatMessage.user(message.trim()));
      _messages.add(ChatMessage.loading());
      _isLoading = true;
    });

    try {
      final result = await _chatbotService.askQuestion(
        message.trim(),
        langue: widget.langue,
      );

      setState(() {
        // Supprimer le message de chargement
        _messages.removeWhere((msg) => msg.isLoading);

        if (result['success'] == true) {
          final data = result['data'];
          _messages.add(
            ChatMessage.bot(data['reponse'], category: data['categorie']),
          );
        } else {
          _messages.add(
            ChatMessage.error(
              widget.langue == 'fr'
                  ? '❌ ${result['message'] ?? 'Erreur inconnue'}\nVeuillez réessayer.'
                  : '❌ ${result['message'] ?? 'خطأ غير معروف'}\nحاول مرة أخرى.',
            ),
          );
        }
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _messages.removeWhere((msg) => msg.isLoading);
        _messages.add(
          ChatMessage.error(
            widget.langue == 'fr'
                ? '❌ Erreur de connexion\nVeuillez vérifier votre connexion internet.'
                : '❌ خطأ في الاتصال\nيرجى التحقق من اتصالك بالإنترنت.',
          ),
        );
        _isLoading = false;
      });
    }
  }

  void _sendQuickAction(String action) {
    _sendMessage(action);
  }

  @override
  Widget build(BuildContext context) {
    final primaryColor = widget.primaryColor ?? Theme.of(context).primaryColor;

    return Stack(
      children: [
        // Bouton flottant
        if (widget.showFloatingButton)
          Positioned(
            bottom: 20,
            right: 20,
            child: ChatbotButton(
              isOpen: _isOpen,
              onTap: _toggleChatbot,
              size: widget.buttonSize ?? 60,
              primaryColor: primaryColor,
            ),
          ),

        // Fenêtre du chatbot
        if (_isOpen)
          Positioned(
            bottom: 90,
            right: 20,
            child: ScaleTransition(
              scale: _scaleAnimation,
              child: ChatbotWindow(
                messages: _messages,
                isLoading: _isLoading,
                quickActions: _quickActions,
                langue: widget.langue,
                primaryColor: primaryColor,
                backgroundColor: widget.backgroundColor ?? Colors.white,
                onSendMessage: _sendMessage,
                onQuickAction: _sendQuickAction,
                onClose: _toggleChatbot,
              ),
            ),
          ),
      ],
    );
  }
}
