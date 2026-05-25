import 'dart:ui';
import '../../../widgets/glass_effect.dart';
import 'package:flutter/material.dart';
import '../../../core/api_service.dart';

class AITrainingScreen extends StatefulWidget {
  const AITrainingScreen({super.key});

  @override
  State<AITrainingScreen> createState() => _AITrainingScreenState();
}

class _AITrainingScreenState extends State<AITrainingScreen> {
  final ApiService _apiService = ApiService();
  final _promoNameController = TextEditingController();
  final _promoDetailsController = TextEditingController();
  final _contextController = TextEditingController();
  final _percentController = TextEditingController();
  
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
    _promoNameController.dispose();
    _promoDetailsController.dispose();
    _contextController.dispose();
    _percentController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    final data = await _apiService.getAITraining();
    setState(() {
      _trainingData = data;
      
      // Cargar contexto general
      final contextItems = data.where((item) => item['category'] == 'general_context').toList();
      if (contextItems.isNotEmpty) {
        _generalContextItem = contextItems.first;
        _contextController.text = _generalContextItem!['answer'] ?? '';
      } else {
        _generalContextItem = null;
        _contextController.clear();
      }
      
      // Cargar porcentaje de descuento de campaña
      final percentItems = data.where((item) => item['category'] == 'campaign_percentage').toList();
      if (percentItems.isNotEmpty) {
        _percentController.text = percentItems.first['answer'] ?? '';
      } else {
        _percentController.clear();
      }
      
      _isLoading = false;
    });
  }

  Future<void> _savePromoContext() async {
    final text = _contextController.text.trim();
    final percent = _percentController.text.trim();
    
    if (text.isEmpty) {
      _showMsg('El contexto de la promoción no puede estar vacío');
      return;
    }

    setState(() => _isLoading = true);
    
    final res = await _apiService.addAITraining(
      'Campaña Promocional y Contexto Activo',
      text,
      category: 'general_context',
    );
    
    // Guardar porcentaje si está provisto, si no, se puede borrar o dejar vacío
    await _apiService.addAITraining(
      'Porcentaje de Descuento de Campaña',
      percent,
      category: 'campaign_percentage',
    );
    
    setState(() => _isLoading = false);

    _showToast(res['message']);
    _loadData();
  }

  Future<void> _savePromoFAQ() async {
    final q = _promoNameController.text.trim();
    final a = _promoDetailsController.text.trim();

    if (q.isEmpty || a.isEmpty) {
      _showMsg('Por favor complete ambos campos de la promoción');
      return;
    }

    setState(() => _isLoading = true);
    final res = await _apiService.addAITraining(q, a, category: 'faq');
    setState(() => _isLoading = false);

    _showToast(res['message']);
    if (res['success']) {
      _promoNameController.clear();
      _promoDetailsController.clear();
      _loadData();
    }
  }

  Future<void> _deleteItem(int id) async {
    setState(() => _isLoading = true);
    final res = await _apiService.deleteAITraining(id);
    setState(() => _isLoading = false);
    _showToast(res['message']);
    _loadData();
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
              const Icon(Icons.check_circle_outline, color: Colors.cyanAccent, size: 24),
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
    // Campaign FAQs excluding the general context
    final promoFAQs = _trainingData.where((item) => item['category'] != 'general_context').toList();

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor: const Color(0xFF0B1222),
        appBar: AppBar(
          title: const Text(
            'Entrenamiento de Campañas IA',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
          ),
          centerTitle: true,
          backgroundColor: const Color(0xFF0B1222),
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white),
            onPressed: () => Navigator.pop(context),
          ),
          bottom: PreferredSize(
            preferredSize: const Size.fromHeight(60),
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.06),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.white.withOpacity(0.12)),
              ),
              child: TabBar(
                dividerColor: Colors.transparent,
                dividerHeight: 0.0,
                labelColor: Colors.cyanAccent,
                unselectedLabelColor: Colors.white70,
                indicatorSize: TabBarIndicatorSize.tab,
                indicator: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  color: Colors.cyanAccent.withOpacity(0.15),
                ),
                tabs: const [
                  Tab(icon: Icon(Icons.campaign_outlined), text: 'Contexto'),
                  Tab(icon: Icon(Icons.percent_outlined), text: 'Ofertas'),
                ],
              ),
            ),
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
                Color(0xFF0B1222),
                Color(0xFF131D31),
                Color(0xFF1B2A47),
              ],
            ),
          ),
          child: _isLoading
              ? const Center(
                  child: CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                )
              : TabBarView(
                  children: [
                    _buildContextTab(),
                    _buildPromoFAQsTab(promoFAQs),
                  ],
                ),
        ),
      ),
    );
  }

  Widget _buildContextTab() {
    return SingleChildScrollView(
      physics: const ClampingScrollPhysics(),
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Promociones y Campañas Activas',
            style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(
            'Define aquí la campaña principal del mes o semana. El Asesor AI recordará y priorizará recomendar estas ofertas de forma proactiva a los clientes.',
            style: TextStyle(color: Colors.white.withOpacity(0.6), fontSize: 13, height: 1.4),
          ),
          const SizedBox(height: 24),
          
          // Campo de Porcentaje de Descuento
          const Text(
            'Porcentaje de Descuento de Campaña',
            style: TextStyle(color: Colors.white70, fontSize: 14, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Container(
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.05),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: Colors.white.withOpacity(0.12), width: 1.2),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(14),
              child: GlassEffect(
                child: TextField(
                  controller: _percentController,
                  style: const TextStyle(color: Colors.white, fontSize: 15),
                  decoration: InputDecoration(
                    labelText: 'Descuento de la campaña (%)',
                    labelStyle: const TextStyle(color: Colors.white70, fontSize: 13),
                    hintText: 'Ej: 15% o 20%',
                    hintStyle: TextStyle(color: Colors.white.withOpacity(0.25)),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                    border: InputBorder.none,
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 20),
          
          // Campo de Contexto/Descripción de Campaña
          const Text(
            'Descripción y Contexto de la Campaña',
            style: TextStyle(color: Colors.white70, fontSize: 14, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Container(
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.05),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: Colors.white.withOpacity(0.12), width: 1.2),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(24),
              child: GlassEffect(
                child: TextField(
                  controller: _contextController,
                  maxLines: 10,
                  style: const TextStyle(color: Colors.white, fontSize: 15, height: 1.5),
                  decoration: InputDecoration(
                    labelText: 'Detalles de la promoción',
                    labelStyle: const TextStyle(color: Colors.white70, fontSize: 13),
                    hintText: 'Ej: ¡Campaña de Aniversario de Innova Center activa! \n- 15% de descuento en electrodomésticos y toda la Línea Blanca.\n- Envío gratis en Orinokia Mall y zonas aledañas.\n- Combo Especial: Por la compra de una nevera y lavadora, llévate una licuadora gratis.\n- Métodos de pago aceptados: Pago Móvil, Zelle y divisas.',
                    hintStyle: TextStyle(color: Colors.white.withOpacity(0.25)),
                    contentPadding: const EdgeInsets.all(20),
                    border: InputBorder.none,
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 24),
          
          // Save Button
          SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: const Color(0xFF0F172A),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                elevation: 0,
              ),
              onPressed: _savePromoContext,
              icon: const Icon(Icons.save_outlined, color: Color(0xFF0F172A)),
              label: const Text(
                'Guardar Campaña Activa',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPromoFAQsTab(List<dynamic> list) {
    return Column(
      children: [
        // Form to add promotion Q&A
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
          child: Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.05),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: Colors.white.withOpacity(0.12), width: 1.2),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(24),
              child: GlassEffect(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Text(
                      'Agregar Regla de Oferta / Pregunta Directa',
                      style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: _promoNameController,
                      style: const TextStyle(color: Colors.white),
                      decoration: InputDecoration(
                        labelText: 'Pregunta del cliente o activador',
                        labelStyle: const TextStyle(color: Colors.white70, fontSize: 13),
                        hintText: 'Ej: ¿Qué promociones hay en cafeteras?',
                        hintStyle: TextStyle(color: Colors.white.withOpacity(0.3)),
                        filled: true,
                        fillColor: Colors.white.withOpacity(0.04),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _promoDetailsController,
                      style: const TextStyle(color: Colors.white),
                      maxLines: 2,
                      decoration: InputDecoration(
                        labelText: 'Respuesta u oferta detallada',
                        labelStyle: const TextStyle(color: Colors.white70, fontSize: 13),
                        hintText: 'Ej: Cafetera Espresso Barista Pro tiene 10% de descuento directo y viene con un juego de tazas de regalo.',
                        hintStyle: TextStyle(color: Colors.white.withOpacity(0.3)),
                        filled: true,
                        fillColor: Colors.white.withOpacity(0.04),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Align(
                      alignment: Alignment.centerRight,
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.indigoAccent,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                        onPressed: _savePromoFAQ,
                        icon: const Icon(Icons.add, size: 18),
                        label: const Text('Agregar Regla', style: TextStyle(fontWeight: FontWeight.bold)),
                      ),
                    )
                  ],
                ),
              ),
            ),
          ),
        ),
        
        // List of rules
        Expanded(
          child: list.isEmpty
              ? Center(
                  child: Text(
                    'No hay reglas específicas de ofertas registradas.',
                    style: TextStyle(color: Colors.white.withOpacity(0.4), fontSize: 14),
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                  itemCount: list.length,
                  itemBuilder: (context, index) {
                    final item = list[index];
                    return Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.03),
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(color: Colors.white.withOpacity(0.08)),
                      ),
                      child: ListTile(
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        title: Text(
                          item['question'] ?? '',
                          style: const TextStyle(color: Colors.cyanAccent, fontWeight: FontWeight.bold, fontSize: 15),
                        ),
                        subtitle: Padding(
                          padding: const EdgeInsets.only(top: 6.0),
                          child: Text(
                            item['answer'] ?? '',
                            style: TextStyle(color: Colors.white.withOpacity(0.7), fontSize: 13),
                          ),
                        ),
                        trailing: IconButton(
                          icon: const Icon(Icons.delete_outline_rounded, color: Colors.redAccent),
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

  Widget _bg() => Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFF0B1222),
              Color(0xFF131D31),
              Color(0xFF1B2A47),
            ],
          ),
        ),
      );
}
