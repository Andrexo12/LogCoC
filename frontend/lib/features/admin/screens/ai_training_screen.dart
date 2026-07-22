import '../../../widgets/glass_effect.dart';
import 'package:flutter/material.dart';
import '../../../core/api_service.dart';
import 'package:logw_front/core/theme/app_colors.dart';

class AITrainingScreen extends StatefulWidget {
  const AITrainingScreen({super.key});

  @override
  State<AITrainingScreen> createState() => _AITrainingScreenState();
}

class _AITrainingScreenState extends State<AITrainingScreen> {
  final ApiService _apiService = ApiService();
  final _instructionController = TextEditingController();
  final _newContextController = TextEditingController();
  
  bool _isLoading = false;
  List<dynamic> _contexts = [];
  final List<Map<String, String>> _chatHistory = [];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  @override
  void dispose() {
    _instructionController.dispose();
    _newContextController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    final data = await _apiService.getChatbotContexts();
    setState(() {
      _contexts = data;
      _isLoading = false;
    });
  }

  Future<void> _trainBotChat() async {
    final instruction = _instructionController.text.trim();
    if (instruction.isEmpty) {
      _showMsg('Escribe una instrucción para que el bot aprenda');
      return;
    }
    setState(() {
      _chatHistory.add({'sender': 'admin', 'text': instruction});
      _instructionController.clear();
      _isLoading = true;
    });
    
    final res = await _apiService.trainChatbot(instruction);
    
    setState(() {
      _isLoading = false;
      if (res['success']) {
        _chatHistory.add({'sender': 'bot', 'text': res['message'] ?? 'Instrucción procesada correctamente.'});
        _loadData();
      } else {
        _chatHistory.add({'sender': 'bot', 'text': 'Error: ${res['message']}'});
      }
    });
  }

  Future<void> _saveNewContext() async {
    final text = _newContextController.text.trim();
    
    if (text.isEmpty) {
      _showMsg('El contexto no puede estar vacío');
      return;
    }

    setState(() => _isLoading = true);
    
    final res = await _apiService.addChatbotContext(text);
    
    setState(() => _isLoading = false);

    _showToast(res['message']);
    if (res['success']) {
      _newContextController.clear();
      _loadData();
    }
  }

  Future<void> _deleteContext(int id) async {
    setState(() => _isLoading = true);
    final res = await _apiService.deleteChatbotContext(id);
    setState(() => _isLoading = false);
    _showToast(res['message']);
    _loadData();
  }

  Future<void> _editContext(int id, String currentText) async {
    final editController = TextEditingController(text: currentText);
    
    final result = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: AppColors.surface,
          title: const Text('Editar Contexto', style: TextStyle(color: Colors.white)),
          content: TextField(
            controller: editController,
            maxLines: 4,
            style: const TextStyle(color: Colors.white),
            decoration: const InputDecoration(
              filled: true,
              fillColor: AppColors.surfaceLight,
              border: OutlineInputBorder(),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancelar', style: TextStyle(color: Colors.white70)),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(context, true),
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.tertiary),
              child: const Text('Guardar'),
            ),
          ],
        );
      },
    );

    if (result == true) {
      final newText = editController.text.trim();
      if (newText.isNotEmpty && newText != currentText) {
        setState(() => _isLoading = true);
        final res = await _apiService.updateChatbotContext(id, newText);
        setState(() => _isLoading = false);
        _showToast(res['message']);
        _loadData();
      }
    }
  }

  void _showMsg(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), behavior: SnackBarBehavior.floating),
    );
  }

  void _showToast(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        content: Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.12),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.white.withOpacity(0.2), width: 1),
            boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 10, offset: Offset(0, 5))],
          ),
          child: Row(
            children: [
              const Icon(Icons.check_circle_outline, color: AppColors.secondary, size: 24),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  message,
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 14),
                ),
              ),
            ],
          ),
        ),
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: const Text(
          'Entrenamiento de IA',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        backgroundColor: AppColors.background,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white),
          onPressed: () {
            if (Navigator.canPop(context)) {
              Navigator.pop(context);
            } else {
              Navigator.pushReplacementNamed(context, '/admin');
            }
          },
        ),
      ),
      body: Container(
        width: double.infinity,
        height: double.infinity,
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
        child: _isLoading && _contexts.isEmpty && _chatHistory.isEmpty
            ? const Center(
                child: CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              )
            : SingleChildScrollView(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Entrenador AI (Chat Interface)
                    const Text(
                      'Entrenador AI (Chat)',
                      style: TextStyle(color: AppColors.textSecondary, fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 12),
                    Container(
                      height: 350,
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.05),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: AppColors.secondary.withOpacity(0.3), width: 1.2),
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(16),
                        child: GlassEffect(
                          child: Column(
                            children: [
                              // Chat history
                              Expanded(
                                child: _chatHistory.isEmpty
                                    ? Center(
                                        child: Text(
                                          'Envía instrucciones para que el bot aprenda.',
                                          style: TextStyle(color: Colors.white.withOpacity(0.3)),
                                        ),
                                      )
                                    : ListView.builder(
                                        padding: const EdgeInsets.all(16),
                                        itemCount: _chatHistory.length,
                                        itemBuilder: (context, index) {
                                          final msg = _chatHistory[index];
                                          final isAdmin = msg['sender'] == 'admin';
                                          return Align(
                                            alignment: isAdmin ? Alignment.centerRight : Alignment.centerLeft,
                                            child: Container(
                                              margin: const EdgeInsets.only(bottom: 12),
                                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                              decoration: BoxDecoration(
                                                color: isAdmin ? AppColors.secondary.withOpacity(0.2) : Colors.white.withOpacity(0.1),
                                                borderRadius: BorderRadius.only(
                                                  topLeft: const Radius.circular(16),
                                                  topRight: const Radius.circular(16),
                                                  bottomLeft: Radius.circular(isAdmin ? 16 : 0),
                                                  bottomRight: Radius.circular(isAdmin ? 0 : 16),
                                                ),
                                              ),
                                              child: Text(
                                                msg['text'] ?? '',
                                                style: TextStyle(
                                                  color: isAdmin ? AppColors.secondary : Colors.white,
                                                  fontSize: 14,
                                                ),
                                              ),
                                            ),
                                          );
                                        },
                                      ),
                              ),
                              // Input area
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                decoration: BoxDecoration(
                                  border: Border(top: BorderSide(color: Colors.white.withOpacity(0.1))),
                                ),
                                child: Row(
                                  children: [
                                    Expanded(
                                      child: TextField(
                                        controller: _instructionController,
                                        style: const TextStyle(color: Colors.white, fontSize: 14),
                                        decoration: InputDecoration(
                                          hintText: 'Ej: A partir de hoy calcula a 1.85',
                                          hintStyle: TextStyle(color: Colors.white.withOpacity(0.3)),
                                          border: InputBorder.none,
                                          isDense: true,
                                        ),
                                        onSubmitted: (_) => _trainBotChat(),
                                      ),
                                    ),
                                    IconButton(
                                      icon: const Icon(Icons.send_rounded, color: AppColors.secondary),
                                      onPressed: _trainBotChat,
                                    )
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    
                    const SizedBox(height: 40),
                    
                    // Lista de Contextos
                    const Text(
                      'Registro de Contextos',
                      style: TextStyle(color: AppColors.textSecondary, fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 12),
                    
                    // Añadir nuevo contexto
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.05),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: Colors.white.withOpacity(0.12)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          TextField(
                            controller: _newContextController,
                            maxLines: 3,
                            style: const TextStyle(color: Colors.white),
                            decoration: InputDecoration(
                              hintText: 'Añadir un nuevo contexto para el chatbot...',
                              hintStyle: TextStyle(color: Colors.white.withOpacity(0.3)),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide.none,
                              ),
                              filled: true,
                              fillColor: Colors.white.withOpacity(0.05),
                            ),
                          ),
                          const SizedBox(height: 12),
                          ElevatedButton.icon(
                            onPressed: _saveNewContext,
                            icon: const Icon(Icons.add),
                            label: const Text('Añadir Contexto'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.tertiary,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                          ),
                        ],
                      ),
                    ),
                    
                    const SizedBox(height: 24),
                    
                    // Contextos Guardados
                    if (_contexts.isEmpty)
                      const Center(
                        child: Padding(
                          padding: EdgeInsets.all(20.0),
                          child: Text('No hay contextos registrados', style: TextStyle(color: Colors.white54)),
                        ),
                      )
                    else
                      ListView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: _contexts.length,
                        itemBuilder: (context, index) {
                          final ctx = _contexts[index];
                          final date = DateTime.parse(ctx['created_at']).toLocal();
                          final dateStr = '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')} ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
                          return Container(
                            margin: const EdgeInsets.only(bottom: 12),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.03),
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(color: Colors.white.withOpacity(0.08)),
                            ),
                            child: ListTile(
                              contentPadding: const EdgeInsets.all(16),
                              title: Text(
                                ctx['context_text'] ?? '',
                                style: const TextStyle(color: Colors.white, fontSize: 14),
                              ),
                              subtitle: Padding(
                                padding: const EdgeInsets.only(top: 8.0),
                                child: Text(
                                  'Registrado por: ${ctx['created_by_name'] ?? 'Usuario'} el $dateStr',
                                  style: const TextStyle(color: AppColors.textMuted, fontSize: 12),
                                ),
                              ),
                              trailing: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  IconButton(
                                    icon: const Icon(Icons.edit_outlined, color: AppColors.info, size: 20),
                                    onPressed: () => _editContext(ctx['id'], ctx['context_text']),
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.delete_outline, color: AppColors.error, size: 20),
                                    onPressed: () => _deleteContext(ctx['id']),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                  ],
                ),
              ),
      ),
    );
  }
}
