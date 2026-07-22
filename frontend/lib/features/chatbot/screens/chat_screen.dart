import '../../../widgets/glass_effect.dart';
import 'package:flutter/material.dart';
import '../../../core/api_service.dart';
import 'package:logw_front/core/theme/app_colors.dart';

class ChatScreen extends StatefulWidget {
  final String? productContextId;
  final String? productName;
  const ChatScreen({super.key, this.productContextId, this.productName});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController _messageController = TextEditingController();
  final ApiService _apiService = ApiService();
  final List<Map<String, dynamic>> _messages = [];
  bool _isTyping = false;

  @override
  void initState() {
    super.initState();
    _messages.add({
      'text': '¡Hola! Soy tu asesor de Innova Center. ${widget.productName != null ? "Estoy listo para ayudarte con tus dudas sobre ${widget.productName}." : "¿En qué puedo ayudarte hoy?"}',
      'isMe': false,
    });
  }

  Future<void> _sendMessage() async {
    final text = _messageController.text.trim();
    if (text.isEmpty) return;

    setState(() {
      _messages.add({'text': text, 'isMe': true});
      _isTyping = true;
      _messageController.clear();
    });

    final response = await _apiService.askChatbot(text, qrId: widget.productContextId);

    if (mounted) {
      setState(() {
        _isTyping = false;
        _messages.add({
          'text': response['success'] ? response['reply'] : 'Lo siento, ocurrió un error: ${response['message']}',
          'isMe': false,
        });
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const Text(
              'Asesor Innova Bot',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
            ),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 8,
                  height: 8,
                  decoration: const BoxDecoration(
                    color: AppColors.success,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 6),
                const Text('En línea', style: TextStyle(fontSize: 11, color: AppColors.success, fontWeight: FontWeight.w500)),
              ],
            ),
          ],
        ),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white),
          onPressed: () {
            if (Navigator.canPop(context)) {
              Navigator.pop(context);
            } else {
              Navigator.pushReplacementNamed(context, '/');
            }
          },
        ),
      ),
      body: Stack(
        children: [
          _bg(),
          SafeArea(
            child: Column(
              children: [
                Expanded(
                  child: ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
                    itemCount: _messages.length,
                    itemBuilder: (context, index) {
                      final msg = _messages[index];
                      return _buildMessageBubble(msg['text'], msg['isMe']);
                    },
                  ),
                ),
                if (_isTyping)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.04),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.white.withOpacity(0.08)),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            SizedBox(
                              width: 14,
                              height: 14,
                              child: CircularProgressIndicator(
                                strokeWidth: 1.5,
                                valueColor: AlwaysStoppedAnimation<Color>(AppColors.secondary),
                              ),
                            ),
                            SizedBox(width: 10),
                            Text(
                              'El asesor está escribiendo...',
                              style: TextStyle(fontStyle: FontStyle.italic, color: AppColors.textMuted, fontSize: 12),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                _buildInputArea(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMessageBubble(String text, bool isMe) {
    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 6),
        decoration: BoxDecoration(
          color: isMe 
              ? AppColors.primary.withOpacity(0.2) 
              : Colors.white.withOpacity(0.06),
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(20),
            topRight: const Radius.circular(20),
            bottomLeft: Radius.circular(isMe ? 20 : 0),
            bottomRight: Radius.circular(isMe ? 0 : 20),
          ),
          border: Border.all(
            color: isMe 
                ? AppColors.primary.withOpacity(0.3) 
                : Colors.white.withOpacity(0.12),
            width: 1,
          ),
        ),
        constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.76),
        child: ClipRRect(
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(20),
            topRight: const Radius.circular(20),
            bottomLeft: Radius.circular(isMe ? 20 : 0),
            bottomRight: Radius.circular(isMe ? 0 : 20),
          ),
          child: GlassEffect(
            sigmaX: 8,
            sigmaY: 8,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
              child: Text(
                text,
                style: const TextStyle(color: Colors.white, fontSize: 14.5, height: 1.4),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildInputArea() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF0F172A).withOpacity(0.4),
        border: Border(top: BorderSide(color: Colors.white.withOpacity(0.08), width: 1)),
      ),
      child: ClipRRect(
        child: GlassEffect(
          child: Row(
            children: [
              Expanded(
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.05),
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(color: Colors.white.withOpacity(0.12), width: 1),
                  ),
                  child: TextField(
                    controller: _messageController,
                    style: const TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      hintText: 'Pregunta sobre garantías, stock, promos...',
                      hintStyle: TextStyle(color: Colors.white.withOpacity(0.3), fontSize: 13),
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                    ),
                    onSubmitted: (_) => _sendMessage(),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              CircleAvatar(
                backgroundColor: Colors.white,
                radius: 22,
                child: IconButton(
                  icon: const Icon(Icons.send_rounded, color: Color(0xFF0F172A), size: 18),
                  onPressed: _sendMessage,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _bg() => Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              AppColors.background,
              AppColors.surface,
              AppColors.surfaceLight,
            ],
          ),
        ),
      );
}
