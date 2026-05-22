import 'package:flutter/material.dart';
import '../../../core/api_service.dart';

class AITrainingScreen extends StatefulWidget {
  const AITrainingScreen({super.key});

  @override
  State<AITrainingScreen> createState() => _AITrainingScreenState();
}

class _AITrainingScreenState extends State<AITrainingScreen> {
  final ApiService _apiService = ApiService();
  final _questionController = TextEditingController();
  final _answerController = TextEditingController();
  final _contextController = TextEditingController();
  
  bool _isLoading = false;
  List<dynamic> _trainingData = [];
  Map<String, dynamic>? _generalContextItem;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  @override
  void dispose() {
    _questionController.dispose();
    _answerController.dispose();
    _contextController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    final data = await _apiService.getAITraining();
    setState(() {
      _trainingData = data;
      // Buscar el elemento de contexto general
      final contextItems = data.where((item) => item['category'] == 'general_context').toList();
      if (contextItems.isNotEmpty) {
        _generalContextItem = contextItems.first;
        _contextController.text = _generalContextItem!['answer'] ?? '';
      } else {
        _generalContextItem = null;
        _contextController.clear();
      }
      _isLoading = false;
    });
  }

  Future<void> _saveContext() async {
    final text = _contextController.text.trim();
    if (text.isEmpty) {
      _showMsg('El contexto no puede estar vacío');
      return;
    }

    setState(() => _isLoading = true);
    final res = await _apiService.addAITraining(
      'Información General del Negocio',
      text,
      category: 'general_context',
    );
    setState(() => _isLoading = false);

    _showMsg(res['message']);
    _loadData();
  }

  Future<void> _saveFAQ() async {
    final q = _questionController.text.trim();
    final a = _answerController.text.trim();

    if (q.isEmpty || a.isEmpty) {
      _showMsg('Por favor rellena ambos campos');
      return;
    }

    setState(() => _isLoading = true);
    final res = await _apiService.addAITraining(q, a, category: 'faq');
    setState(() => _isLoading = false);

    _showMsg(res['message']);
    if (res['success']) {
      _questionController.clear();
      _answerController.clear();
      _loadData();
    }
  }

  Future<void> _deleteItem(int id) async {
    setState(() => _isLoading = true);
    final res = await _apiService.deleteAITraining(id);
    setState(() => _isLoading = false);
    _showMsg(res['message']);
    _loadData();
  }

  void _showMsg(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), behavior: SnackBarBehavior.floating),
    );
  }

  @override
  Widget build(BuildContext context) {
    // FAQs excluyendo el contexto general
    final faqs = _trainingData.where((item) => item['category'] != 'general_context').toList();

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor: const Color(0xFF0F172A), // Slate 900
        appBar: AppBar(
          title: const Text('Entrenamiento de IA', style: TextStyle(fontWeight: FontWeight.bold)),
          backgroundColor: const Color(0xFF1E293B), // Slate 800
          foregroundColor: Colors.white,
          elevation: 2,
          bottom: const TabBar(
            labelColor: Colors.cyanAccent,
            unselectedLabelColor: Colors.white70,
            indicatorColor: Colors.cyanAccent,
            tabs: [
              Tab(icon: Icon(Icons.business), text: 'Contexto de Negocio'),
              Tab(icon: Icon(Icons.question_answer), text: 'FAQs (Preguntas Frecuentes)'),
            ],
          ),
        ),
        body: _isLoading
            ? const Center(child: CircularProgressIndicator(color: Colors.cyanAccent))
            : TabBarView(
                children: [
                  // Tab 1: Contexto de Negocio
                  _buildContextTab(),
                  // Tab 2: FAQs
                  _buildFAQsTab(faqs),
                ],
              ),
      ),
    );
  }

  Widget _buildContextTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Contexto e Instrucciones de la Tienda',
            style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 10),
          const Text(
            'Define aquí políticas de cambios, garantías, promociones vigentes, la descripción general de Innova Center Orinokia Mall o reglas que el Chatbot deba seguir al pie de la letra.',
            style: TextStyle(color: Colors.white70, fontSize: 14),
          ),
          const SizedBox(height: 20),
          Container(
            decoration: BoxDecoration(
              color: const Color(0xFF1E293B),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.white10),
            ),
            child: TextField(
              controller: _contextController,
              maxLines: 12,
              style: const TextStyle(color: Colors.white, fontSize: 15),
              decoration: const InputDecoration(
                hintText: 'Ej. Innova Center está ubicada en Orinokia Mall. Ofrecemos 1 año de garantía en todos los artículos. Aceptamos pagos por Zelle, Pago Móvil y efectivo. Si hay promociones de Xiaomi descríbelas aquí...',
                hintStyle: TextStyle(color: Colors.white30),
                contentPadding: EdgeInsets.all(16),
                border: InputBorder.none,
              ),
            ),
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.cyanAccent,
                foregroundColor: const Color(0xFF0F172A),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              onPressed: _saveContext,
              icon: const Icon(Icons.save),
              label: const Text('Actualizar Contexto de IA', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFAQsTab(List<dynamic> faqs) {
    return Column(
      children: [
        // Formulario de agregar FAQ
        Container(
          padding: const EdgeInsets.all(16),
          color: const Color(0xFF1E293B),
          child: Column(
            children: [
              TextField(
                controller: _questionController,
                style: const TextStyle(color: Colors.white),
                decoration: const InputDecoration(
                  labelText: 'Pregunta frecuente',
                  labelStyle: TextStyle(color: Colors.white70),
                  enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: Colors.white24)),
                  focusedBorder: UnderlineInputBorder(borderSide: BorderSide(color: Colors.cyanAccent)),
                ),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: _answerController,
                style: const TextStyle(color: Colors.white),
                maxLines: 2,
                decoration: const InputDecoration(
                  labelText: 'Respuesta predeterminada',
                  labelStyle: TextStyle(color: Colors.white70),
                  enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: Colors.white24)),
                  focusedBorder: UnderlineInputBorder(borderSide: BorderSide(color: Colors.cyanAccent)),
                ),
              ),
              const SizedBox(height: 16),
              Align(
                alignment: Alignment.centerRight,
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.indigoAccent,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  onPressed: _saveFAQ,
                  icon: const Icon(Icons.add),
                  label: const Text('Añadir FAQ'),
                ),
              )
            ],
          ),
        ),
        // Listado de FAQs
        Expanded(
          child: faqs.isEmpty
              ? const Center(
                  child: Text(
                    'No hay preguntas frecuentes registradas.',
                    style: TextStyle(color: Colors.white30, fontSize: 16),
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: faqs.length,
                  itemBuilder: (context, index) {
                    final item = faqs[index];
                    return Card(
                      color: const Color(0xFF1E293B),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                        side: const BorderSide(color: Colors.white10),
                      ),
                      margin: const EdgeInsets.only(bottom: 12),
                      child: ListTile(
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        title: Text(
                          item['question'] ?? '',
                          style: const TextStyle(color: Colors.cyanAccent, fontWeight: FontWeight.bold),
                        ),
                        subtitle: Padding(
                          padding: const EdgeInsets.only(top: 6.0),
                          child: Text(
                            item['answer'] ?? '',
                            style: const TextStyle(color: Colors.white),
                          ),
                        ),
                        trailing: IconButton(
                          icon: const Icon(Icons.delete, color: Colors.redAccent),
                          onPressed: () {
                            if (item['id'] != null) {
                              _deleteItem(item['id']);
                            }
                          },
                        ),
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }
}
