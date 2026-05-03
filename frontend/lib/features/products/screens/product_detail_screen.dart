import 'package:flutter/material.dart';
import '../../../core/api_service.dart';
import '../../chatbot/screens/chat_screen.dart';

class ProductDetailScreen extends StatefulWidget {
  final String qrId;
  const ProductDetailScreen({super.key, required this.qrId});

  @override
  State<ProductDetailScreen> createState() => _ProductDetailScreenState();
}

class _ProductDetailScreenState extends State<ProductDetailScreen> {
  final ApiService _apiService = ApiService();
  Map<String, dynamic>? _product;
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _fetchProduct();
  }

  Future<void> _fetchProduct() async {
    final result = await _apiService.getProductByQr(widget.qrId);
    if (mounted) {
      setState(() {
        if (result['success']) {
          _product = result['data'];
        } else {
          _error = result['message'];
        }
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Detalle de Producto'),
        centerTitle: true,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? _buildErrorView()
              : _buildProductView(),
      floatingActionButton: _product != null 
          ? FloatingActionButton.extended(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => ChatScreen(
                      productContextId: widget.qrId,
                      productName: _product!['name'],
                    ),
                  ),
                );
              },
              label: const Text('Asesor IA'),
              icon: const Icon(Icons.smart_toy_outlined),
              backgroundColor: Colors.indigo,
              foregroundColor: Colors.white,
            )
          : null,
    );
  }

  Widget _buildErrorView() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline, size: 80, color: Colors.red),
          const SizedBox(height: 16),
          Text(_error!, style: const TextStyle(fontSize: 18)),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Volver a escanear'),
          )
        ],
      ),
    );
  }

  Widget _buildProductView() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              padding: const EdgeInsets.all(32),
              decoration: BoxDecoration(
                color: Colors.indigo.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.inventory_2, size: 100, color: Colors.indigo),
            ),
          ),
          const SizedBox(height: 32),
          Text(
            _product!['name'],
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: Colors.indigo,
                ),
          ),
          const SizedBox(height: 8),
          Text(
            _product!['category'] ?? 'Sin categoría',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: Colors.grey[600],
                ),
          ),
          const SizedBox(height: 24),
          _infoCard(),
          const SizedBox(height: 32),
          const Text(
            'Descripción',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(
            _product!['description'] ?? 'No hay descripción disponible para este producto.',
            style: const TextStyle(fontSize: 16, height: 1.5),
          ),
          const SizedBox(height: 40),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () {},
              icon: const Icon(Icons.add_shopping_cart),
              label: const Text('Añadir al Carrito'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.indigo,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _infoCard() {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _priceColumn('Precio Original', '\$${_product!['price'].toStringAsFixed(2)}', Colors.grey),
            Container(width: 1, height: 40, color: Colors.grey[300]),
            _priceColumn('Precio Final', '\$${_product!['rounded_price'].toStringAsFixed(2)}', Colors.indigo),
          ],
        ),
      ),
    );
  }

  Widget _priceColumn(String label, String value, Color color) {
    return Column(
      children: [
        Text(label, style: TextStyle(fontSize: 12, color: Colors.grey[600])),
        const SizedBox(height: 4),
        Text(value, style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: color)),
      ],
    );
  }
}
