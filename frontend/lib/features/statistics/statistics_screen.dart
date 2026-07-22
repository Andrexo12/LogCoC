import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../core/api_service.dart';
import '../products/screens/product_detail_screen.dart';
import 'package:logw_front/core/theme/app_colors.dart';

class StatisticsScreen extends StatefulWidget {
  const StatisticsScreen({super.key});

  @override
  State<StatisticsScreen> createState() => _StatisticsScreenState();
}

class _StatisticsScreenState extends State<StatisticsScreen> {
  final ApiService _apiService = ApiService();
  bool _isLoading = true;
  Map<String, dynamic>? _data;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    
    final result = await _apiService.getStatisticsDashboard();
    
    if (result['success']) {
      setState(() {
        _data = result['data'];
        _isLoading = false;
      });
    } else {
      setState(() {
        _errorMessage = result['message'];
        _isLoading = false;
      });
    }
  }

  void _goToProductDetail(String? qrId) {
    if (qrId == null || qrId.isEmpty) return;
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ProductDetailScreen(qrId: qrId),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: const Text('Dashboard de Estadísticas'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadData,
          ),
        ],
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    
    if (_errorMessage != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, color: Colors.red, size: 48),
            const SizedBox(height: 16),
            Text('Error: $_errorMessage'),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _loadData,
              child: const Text('Reintentar'),
            ),
          ],
        ),
      );
    }

    if (_data == null) {
      return const Center(child: Text('No hay datos disponibles.'));
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildStockKPIs(),
          const SizedBox(height: 24),
          _buildFrequentQuestions(),
          const SizedBox(height: 24),
          _buildMostSearchedChart(),
          const SizedBox(height: 24),
          _buildCriticalStockList(),
        ],
      ),
    );
  }

  Widget _buildStockKPIs() {
    final stockStatus = _data!['stock_status'];
    return Row(
      children: [
        Expanded(child: _buildKPICard('Total Productos', stockStatus['total'].toString(), Colors.blue, Icons.inventory)),
        const SizedBox(width: 8),
        Expanded(child: _buildKPICard('Stock Bajo', stockStatus['low_stock'].toString(), Colors.orange, Icons.warning_amber_rounded)),
        const SizedBox(width: 8),
        Expanded(child: _buildKPICard('Agotados', stockStatus['out_of_stock'].toString(), Colors.red, Icons.cancel_outlined)),
      ],
    );
  }

  Widget _buildKPICard(String title, String value, Color color, IconData icon) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 16.0, horizontal: 8.0),
        child: Column(
          children: [
            Icon(icon, color: color, size: 32),
            const SizedBox(height: 8),
            Text(value, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
            const SizedBox(height: 4),
            Text(title, textAlign: TextAlign.center, style: TextStyle(color: Colors.grey[600], fontSize: 12)),
          ],
        ),
      ),
    );
  }

  Widget _buildFrequentQuestions() {
    final questions = List<dynamic>.from(_data!['frequent_questions']);
    
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Preguntas Frecuentes (Chatbot)', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            if (questions.isEmpty)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 24.0),
                child: Center(child: Text('Aún no hay interacciones con el chatbot.', style: TextStyle(color: Colors.grey))),
              )
            else
              ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: questions.length,
                separatorBuilder: (context, index) => const Divider(),
                itemBuilder: (context, index) {
                  final item = questions[index];
                  return ListTile(
                    leading: const Icon(Icons.chat_bubble_outline, color: Colors.blue),
                    title: Text(item['intent'].toString().toUpperCase()),
                    trailing: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.blue.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        '${item['count']} veces',
                        style: const TextStyle(color: Colors.blue, fontWeight: FontWeight.bold),
                      ),
                    ),
                    onTap: () => _showChatbotLogs(item['intent'].toString()),
                  );
                },
              )
          ],
        ),
      ),
    );
  }

  void _showChatbotLogs(String intent) {
    showDialog(
      context: context,
      builder: (context) => _ChatbotLogsDialog(intent: intent),
    );
  }

  Widget _buildMostSearchedChart() {
    final mostSearched = List<dynamic>.from(_data!['most_searched']);

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Productos Más Buscados', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            if (mostSearched.isEmpty)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 24.0),
                child: Center(child: Text('Aún no hay búsquedas registradas.', style: TextStyle(color: Colors.grey))),
              )
            else ...[
              SizedBox(
              height: 250,
              child: BarChart(
                BarChartData(
                  alignment: BarChartAlignment.spaceAround,
                  maxY: _getMaxViews(mostSearched).toDouble() * 1.2,
                  barTouchData: BarTouchData(enabled: true),
                  titlesData: FlTitlesData(
                    show: true,
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        getTitlesWidget: (double value, TitleMeta meta) {
                          if (value.toInt() >= mostSearched.length) return const SizedBox.shrink();
                          final name = mostSearched[value.toInt()]['name'].toString();
                          final shortName = name.length > 10 ? '${name.substring(0, 8)}...' : name;
                          return Padding(
                            padding: const EdgeInsets.only(top: 8.0),
                            child: Text(shortName, style: const TextStyle(fontSize: 10)),
                          );
                        },
                      ),
                    ),
                    leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  ),
                  gridData: const FlGridData(show: false),
                  borderData: FlBorderData(show: false),
                  barGroups: mostSearched.asMap().entries.map((entry) {
                    return BarChartGroupData(
                      x: entry.key,
                      barRods: [
                        BarChartRodData(
                          toY: entry.value['views'].toDouble(),
                          color: AppColors.info,
                          width: 16,
                          borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
                        )
                      ],
                    );
                  }).toList(),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 8,
              runSpacing: 4,
              children: mostSearched.map((product) {
                return InkWell(
                  onTap: () => _goToProductDetail(product['qr_id']),
                  borderRadius: BorderRadius.circular(4),
                  child: Padding(
                    padding: const EdgeInsets.all(4.0),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.search, size: 14, color: AppColors.info),
                        const SizedBox(width: 4),
                        Text(product['name'].toString().length > 15 
                          ? '${product['name'].toString().substring(0, 15)}...' 
                          : product['name'].toString(), 
                          style: const TextStyle(fontSize: 12, decoration: TextDecoration.underline)),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
            ],
          ],
        ),
      ),
    );
  }


  Widget _buildCriticalStockList() {
    final stockStatus = _data!['stock_status'];
    final criticalProducts = List<dynamic>.from(stockStatus['critical_products']);
    
    if (criticalProducts.isEmpty) {
      return const Card(
        child: Padding(
          padding: EdgeInsets.all(16.0),
          child: Text('✅ No hay productos con stock crítico.', style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold)),
        ),
      );
    }

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.warning, color: Colors.orange),
                SizedBox(width: 8),
                Text('Atención: Stock Crítico', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              ],
            ),
            const SizedBox(height: 16),
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: criticalProducts.length,
              separatorBuilder: (context, index) => const Divider(),
              itemBuilder: (context, index) {
                final product = criticalProducts[index];
                return ListTile(
                  contentPadding: EdgeInsets.zero,
                  onTap: () => _goToProductDetail(product['qr_id']),
                  leading: product['image_url'] != null
                      ? ClipRRect(
                          borderRadius: BorderRadius.circular(4),
                          child: Image.network(product['image_url'], width: 40, height: 40, fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => const Icon(Icons.image_not_supported)),
                        )
                      : const Icon(Icons.inventory_2),
                  title: Text(product['name']),
                  trailing: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: product['stock'] == 0 ? Colors.red[100] : Colors.orange[100],
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      'Stock: ${product['stock']}',
                      style: TextStyle(
                        color: product['stock'] == 0 ? Colors.red[900] : Colors.orange[900],
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  int _getMaxViews(List<dynamic> mostSearched) {
    if (mostSearched.isEmpty) return 0;
    int max = 0;
    for (var item in mostSearched) {
      if (item['views'] > max) max = item['views'];
    }
    return max;
  }
}

class _ChatbotLogsDialog extends StatefulWidget {
  final String intent;
  const _ChatbotLogsDialog({required this.intent});

  @override
  State<_ChatbotLogsDialog> createState() => _ChatbotLogsDialogState();
}

class _ChatbotLogsDialogState extends State<_ChatbotLogsDialog> {
  final ApiService _apiService = ApiService();
  bool _isLoading = true;
  List<dynamic> _logs = [];
  int _total = 0;
  int _offset = 0;
  final int _limit = 5;

  @override
  void initState() {
    super.initState();
    _loadLogs();
  }

  Future<void> _loadLogs() async {
    setState(() => _isLoading = true);
    try {
      final data = await _apiService.getChatbotLogsByIntent(widget.intent, limit: _limit, offset: _offset);
      setState(() {
        _logs.addAll(data['logs']);
        _total = data['total'];
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  void _loadMore() {
    setState(() {
      _offset += _limit;
    });
    _loadLogs();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: AppColors.surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: Text('Consultas para: ${widget.intent.toUpperCase()}', style: const TextStyle(color: Colors.white)),
      content: SizedBox(
        width: double.maxFinite,
        height: 300,
        child: _isLoading && _logs.isEmpty
            ? const Center(child: CircularProgressIndicator())
            : ListView.builder(
                itemCount: _logs.length + (_logs.length < _total ? 1 : 0),
                itemBuilder: (context, index) {
                  if (index == _logs.length) {
                    return _isLoading
                        ? const Center(child: CircularProgressIndicator())
                        : TextButton(
                            onPressed: _loadMore,
                            child: const Text('Cargar más', style: TextStyle(color: AppColors.tertiary)),
                          );
                  }
                  final log = _logs[index];
                  return ListTile(
                    title: Text('"${log['query_text']}"', style: const TextStyle(color: AppColors.textSecondary)),
                    subtitle: Text(log['timestamp'].toString().substring(0, 16).replaceFirst('T', ' '), style: const TextStyle(color: Colors.white38, fontSize: 12)),
                  );
                },
              ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cerrar', style: TextStyle(color: AppColors.textSecondary)),
        ),
      ],
    );
  }
}
