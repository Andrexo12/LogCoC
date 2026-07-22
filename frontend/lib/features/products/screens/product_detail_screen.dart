import '../../../widgets/glass_effect.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../core/api_service.dart';
import 'package:logw_front/core/theme/app_colors.dart';

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

  void _shareProduct() {
    // Dynamic link matching the browser URL format: origin + /#/product/qrId
    final String shareUrl = '${Uri.base.origin}/#/product/${Uri.encodeComponent(widget.qrId)}';
    Clipboard.setData(ClipboardData(text: shareUrl));
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        content: Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.12),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: Colors.white.withOpacity(0.2),
              width: 1,
            ),
            boxShadow: const [
              BoxShadow(
                color: Colors.black26,
                blurRadius: 10,
                offset: Offset(0, 5),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: GlassEffect(
              sigmaX: 8,
              sigmaY: 8,
              child: const Row(
                children: [
                  Icon(Icons.check_circle_outline, color: AppColors.tertiary, size: 24),
                  SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      '¡Enlace copiado al portapapeles!',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
        duration: const Duration(seconds: 3),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Text(
          'Detalle de Producto',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            letterSpacing: 1.1,
          ),
        ),
        backgroundColor: AppColors.background.withOpacity(0.7),
        elevation: 0,
        centerTitle: true,
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
        flexibleSpace: ClipRect(
          child: GlassEffect(
            child: Container(color: Colors.transparent),
          ),
        ),
        actions: [
          if (_product != null)
            IconButton(
              icon: const Icon(Icons.share_outlined, color: Colors.white),
              tooltip: 'Compartir producto',
              onPressed: _shareProduct,
            ),
        ],
      ),
      body: Stack(
        children: [
          _bg(),
          _isLoading
              ? const Center(
                  child: CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                )
              : _error != null
                  ? _buildErrorView()
                  : _buildProductView(),
        ],
      ),
      floatingActionButton: _product != null
          ? Container(
              margin: const EdgeInsets.only(bottom: 16),
              child: FloatingActionButton.extended(
                onPressed: () {
                  Navigator.pushNamed(
                    context,
                    '/chatbot',
                    arguments: {
                      'qrId': widget.qrId,
                      'name': _product!['name'] ?? 'Producto',
                    },
                  );
                },
                backgroundColor: Colors.white.withOpacity(0.12),
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                  side: BorderSide(
                    color: Colors.white.withOpacity(0.2),
                    width: 1.2,
                  ),
                ),
                label: const Text(
                  'Asesor AI',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 1.1,
                  ),
                ),
                icon: const Icon(Icons.smart_toy_outlined, color: Colors.white),
              ),
            )
          : null,
    );
  }

  Widget _buildErrorView() {
    return Center(
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 24),
        padding: const EdgeInsets.all(32),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.06),
          borderRadius: BorderRadius.circular(30),
          border: Border.all(color: Colors.white.withOpacity(0.15), width: 1.5),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(30),
          child: GlassEffect(
            sigmaX: 12,
            sigmaY: 12,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline_rounded, size: 80, color: AppColors.error),
                const SizedBox(height: 20),
                Text(
                  _error ?? 'Producto no encontrado',
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 18, color: Colors.white, fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: () {
                    if (Navigator.canPop(context)) {
                      Navigator.pop(context);
                    } else {
                      Navigator.pushReplacementNamed(context, '/');
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: AppColors.background,
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  child: const Text(
                    'Volver',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                  ),
                )
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildProductView() {
    final name = _product!['name'] ?? 'Producto Sin Nombre';
    final category = _product!['category'] ?? 'Sin Categoría';
    final productType = _product!['product_type'] ?? 'Electro';
    final description = _product!['description'] ?? 'No hay descripción disponible para este producto en este momento.';
    final double price = (_product!['price'] is num) ? (_product!['price'] as num).toDouble() : 0.0;
    final double roundedPrice = (_product!['rounded_price'] is num) 
        ? (_product!['rounded_price'] as num).toDouble() 
        : (price * 2).ceilToDouble() / 2;
    final int stock = (_product!['stock'] is num) ? (_product!['stock'] as num).toInt() : 0;
    final bool isAr = _product!['is_ar_visible'] == 1;

    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 220,
                height: 220,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.06),
                  borderRadius: BorderRadius.circular(28),
                  border: Border.all(
                    color: Colors.white.withOpacity(0.2),
                    width: 1.5,
                  ),
                ),
                child: (_product!['image_url'] != null && _product!['image_url'].toString().isNotEmpty)
                    ? ClipRRect(
                        borderRadius: BorderRadius.circular(20),
                        child: Image.network(
                          _product!['image_url'],
                          fit: BoxFit.contain,
                          errorBuilder: (context, error, stackTrace) => const Icon(
                            Icons.inventory_2_outlined,
                            size: 72,
                            color: Colors.white,
                          ),
                          loadingBuilder: (context, child, loadingProgress) {
                            if (loadingProgress == null) return child;
                            return const Center(child: CircularProgressIndicator());
                          },
                        ),
                      )
                    : const Icon(
                        Icons.inventory_2_outlined,
                        size: 72,
                        color: Colors.white,
                      ),
              ),
            ),
            const SizedBox(height: 32),
            
            // Badges Row
            Row(
              children: [
                _badge(category, Colors.white12),
                const SizedBox(width: 8),
                _badge(productType.toUpperCase(), Colors.white12),
                if (isAr) ...[
                  const SizedBox(width: 8),
                  _badge('AR COMPATIBLE', AppColors.primary.withOpacity(0.3)),
                ]
              ],
            ),
            const SizedBox(height: 16),

            // Product Name
            Text(
              name,
              style: const TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.bold,
                color: Colors.white,
                letterSpacing: -0.5,
              ),
            ),
            const SizedBox(height: 10),

            // Stock Indicator
            Row(
              children: [
                Container(
                  width: 10,
                  height: 10,
                  decoration: BoxDecoration(
                    color: stock > 0 ? AppColors.tertiary : AppColors.error,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  stock > 0 ? 'Stock Disponible: $stock unidades' : 'Sin Stock',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.7),
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 28),

            // Glassmorphic Prices Card
            _priceCard(price, roundedPrice),
            const SizedBox(height: 32),

            // Description Header
            const Text(
              'Descripción del Producto',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.white,
                letterSpacing: 0.5,
              ),
            ),
            const SizedBox(height: 12),

            // Description Body
            Text(
              description,
              style: TextStyle(
                fontSize: 15,
                color: Colors.white.withOpacity(0.7),
                height: 1.6,
              ),
            ),
            
            const SizedBox(height: 100), // Spacing for FAB
          ],
        ),
      ),
    );
  }

  Widget _badge(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: Colors.white.withOpacity(0.12),
          width: 1,
        ),
      ),
      child: Text(
        text,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 11,
          fontWeight: FontWeight.bold,
          letterSpacing: 1.1,
        ),
      ),
    );
  }

  Widget _priceCard(double price, double roundedPrice) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.06),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: Colors.white.withOpacity(0.15),
          width: 1.2,
        ),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: GlassEffect(
          sigmaX: 12,
          sigmaY: 12,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'PRECIO DE LISTA',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.5),
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.2,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      '\$${price.toStringAsFixed(2)}',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.6),
                        fontSize: 18,
                        decoration: TextDecoration.lineThrough,
                      ),
                    ),
                  ],
                ),
                Container(
                  width: 1,
                  height: 48,
                  color: Colors.white.withOpacity(0.15),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    const Text(
                      'PRECIO INNOVA CENTER',
                      style: TextStyle(
                        color: AppColors.primary,
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.2,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      '\$${roundedPrice.toStringAsFixed(2)}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 26,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ],
            ),
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
