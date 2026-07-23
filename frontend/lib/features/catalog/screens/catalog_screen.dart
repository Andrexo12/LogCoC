import '../../../widgets/glass_effect.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../core/api_service.dart';
import 'package:logw_front/core/theme/app_colors.dart';

class CatalogScreen extends StatefulWidget {
  final String? initialCategory;
  const CatalogScreen({super.key, this.initialCategory});

  @override
  State<CatalogScreen> createState() => _CatalogScreenState();
}

class _CatalogScreenState extends State<CatalogScreen> {
  final ApiService _apiService = ApiService();
  String selectedType = 'Todos';
  String searchQuery = '';
  List<dynamic> _products = [];
  bool _isLoading = true;

  final List<String> _categories = ['Todos', 'Linea Blanca', 'Linea Gris', 'Electrodomésticos'];

  @override
  void initState() {
    super.initState();
    // Use initial category if provided and matches our available categories (case-insensitive check)
    if (widget.initialCategory != null) {
      final matched = _categories.firstWhere(
        (cat) => cat.toLowerCase() == widget.initialCategory!.toLowerCase(),
        orElse: () => 'Todos',
      );
      selectedType = matched;
    }
    _loadProducts();
  }

  Future<void> _loadProducts() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final products = await _apiService.getProducts();
      if (mounted) {
        setState(() {
          _products = products;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  // Fallback mock list if API yields no products
  List<dynamic> get _displayProducts {
    List<dynamic> listToFilter = _products;
    if (listToFilter.isEmpty) {
      listToFilter = _mockProducts;
    }

    return listToFilter.where((prod) {
      final name = (prod['name'] ?? '').toString().toLowerCase();
      final description = (prod['description'] ?? '').toString().toLowerCase();
      final type = (prod['product_type'] ?? '').toString().toLowerCase();
      final category = (prod['category'] ?? '').toString().toLowerCase();
      final searchLower = searchQuery.toLowerCase();

      final matchesSearch = name.contains(searchLower) || description.contains(searchLower) || category.contains(searchLower);
      
      if (selectedType == 'Todos') {
        return matchesSearch;
      } else {
        // Map database product_type categories
        final typeLower = selectedType.toLowerCase();
        final matchesType = type == typeLower || category.contains(typeLower);
        return matchesSearch && matchesType;
      }
    }).toList();
  }

  void _shareCatalog() {
    // Generate a deep link including the currently selected category
    final String shareUrl = '${Uri.base.origin}/#/catalog?category=${Uri.encodeComponent(selectedType)}';
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
              child: Row(
                children: [
                  const Icon(Icons.check_circle_outline, color: AppColors.tertiary, size: 24),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      '¡Enlace del catálogo ($selectedType) copiado!',
                      style: const TextStyle(
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
    final size = MediaQuery.of(context).size;
    final isDesktop = size.width > 768;
    
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Text(
          'Catálogo Premium',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            letterSpacing: 1.1,
          ),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        leading: Navigator.canPop(context)
            ? IconButton(
                icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white),
                onPressed: () => Navigator.pop(context),
              )
            : null,
        actions: [
          IconButton(
            icon: const Icon(Icons.share_outlined, color: Colors.white),
            tooltip: 'Compartir catálogo',
            onPressed: _shareCatalog,
          ),
          IconButton(
            icon: const Icon(Icons.refresh_rounded, color: Colors.white),
            tooltip: 'Recargar',
            onPressed: _loadProducts,
          ),
        ],
      ),
      body: Stack(
        children: [
          _bg(),
          SafeArea(
            child: Column(
              children: [
                _buildSearchAndFilters(),
                Expanded(
                  child: _isLoading
                      ? const Center(
                          child: CircularProgressIndicator(
                            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        )
                      : _buildProductsGrid(isDesktop),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchAndFilters() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        children: [
          // Search Input
          Container(
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.06),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: Colors.white.withOpacity(0.12),
                width: 1.2,
              ),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: GlassEffect(
                child: TextField(
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    hintText: 'Buscar por nombre, tipo o marca...',
                    hintStyle: TextStyle(color: Colors.white.withOpacity(0.4)),
                    prefixIcon: const Icon(Icons.search, color: AppColors.textMuted),
                    suffixIcon: searchQuery.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear, color: AppColors.textMuted),
                            onPressed: () {
                              setState(() {
                                searchQuery = '';
                              });
                            },
                          )
                        : null,
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                  ),
                  onChanged: (value) => setState(() => searchQuery = value),
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),
          // Category Chips
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: _categories.map((type) {
                final isSelected = selectedType == type;
                return Padding(
                  padding: const EdgeInsets.only(right: 10.0),
                  child: ChoiceChip(
                    label: Text(type),
                    selected: isSelected,
                    onSelected: (selected) {
                      setState(() {
                        selectedType = type;
                      });
                    },
                    selectedColor: Colors.white.withOpacity(0.9),
                    backgroundColor: Colors.white.withOpacity(0.06),
                    labelStyle: TextStyle(
                      color: isSelected ? AppColors.background : AppColors.textSecondary,
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                      side: BorderSide(
                        color: isSelected ? Colors.white : Colors.white.withOpacity(0.12),
                        width: 1,
                      ),
                    ),
                    elevation: 0,
                    pressElevation: 0,
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProductsGrid(bool isDesktop) {
    final filtered = _displayProducts;
    
    if (filtered.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.inventory_2_outlined, size: 64, color: Colors.white.withOpacity(0.3)),
            const SizedBox(height: 16),
            Text(
              'No se encontraron productos',
              style: TextStyle(color: Colors.white.withOpacity(0.6), fontSize: 16, fontWeight: FontWeight.bold),
            ),
          ],
        ),
      );
    }

    return GridView.builder(
      padding: const EdgeInsets.all(16),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: isDesktop ? 3 : 2,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
        childAspectRatio: 0.76,
      ),
      itemCount: filtered.length,
      itemBuilder: (context, index) {
        final prod = filtered[index];
        return _productCard(prod);
      },
    );
  }

  Widget _productCard(Map<String, dynamic> prod) {
    final name = prod['name'] ?? 'Producto';
    final category = prod['category'] ?? 'General';
    final double price = (prod['price'] is num) ? (prod['price'] as num).toDouble() : 0.0;
    final double roundedPrice = (prod['rounded_price'] is num) 
        ? (prod['rounded_price'] as num).toDouble() 
        : (price * 2).ceilToDouble() / 2;
    final int stock = (prod['stock'] is num) ? (prod['stock'] as num).toInt() : 0;
    final String qrId = prod['qr_id'] ?? '';
    final bool isAr = prod['is_ar_visible'] == 1;

    final bool isPerfume = name.toLowerCase().contains('perfume') || name.toLowerCase().contains('fragancia') || category.toLowerCase().contains('perfume');
    
    final double displayDivisas = isPerfume ? roundedPrice / 2 : roundedPrice;
    final double displayBs = isPerfume ? roundedPrice : roundedPrice * 1.85;

    return GestureDetector(
      onTap: () {
        if (qrId.isNotEmpty) {
          Navigator.pushNamed(context, '/product/${Uri.encodeComponent(qrId)}');
        }
      },
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.05),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: Colors.white.withOpacity(0.12),
            width: 1.2,
          ),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(24),
          child: GlassEffect(
            sigmaX: 8,
            sigmaY: 8,
            child: Padding(
              padding: const EdgeInsets.all(14.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Image representation
                  Expanded(
                    child: Center(
                      child: Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.04),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: Colors.white.withOpacity(0.06),
                            width: 1.0,
                          ),
                        ),
                        child: (prod['image_url'] != null && prod['image_url'].toString().isNotEmpty)
                            ? ClipRRect(
                                borderRadius: BorderRadius.circular(12),
                                child: Image.network(
                                  prod['image_url'],
                                  width: 80,
                                  height: 80,
                                  fit: BoxFit.contain,
                                  errorBuilder: (context, error, stackTrace) => const Icon(
                                    Icons.inventory_2_outlined,
                                    size: 38,
                                    color: AppColors.textSecondary,
                                  ),
                                  loadingBuilder: (context, child, loadingProgress) {
                                    if (loadingProgress == null) return child;
                                    return const SizedBox(
                                      width: 80,
                                      height: 80,
                                      child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
                                    );
                                  },
                                ),
                              )
                            : const Icon(
                                Icons.inventory_2_outlined,
                                size: 38,
                                color: AppColors.textSecondary,
                              ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  
                  // Tags Row
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          category,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(color: AppColors.textSecondary, fontSize: 9, fontWeight: FontWeight.bold),
                        ),
                      ),
                      if (isAr) ...[
                        const SizedBox(width: 4),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 3),
                          decoration: BoxDecoration(
                            color: AppColors.primary.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: const Text(
                            'AR',
                            style: TextStyle(color: AppColors.primary, fontSize: 9, fontWeight: FontWeight.bold),
                          ),
                        ),
                      ]
                    ],
                  ),
                  const SizedBox(height: 8),
                  
                  // Product Name
                  Text(
                    name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  
                  // Stock pill
                  Row(
                    children: [
                      Container(
                        width: 6,
                        height: 6,
                        decoration: BoxDecoration(
                          color: stock > 0 ? AppColors.tertiary : AppColors.error,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        stock > 0 ? '$stock disp.' : 'Agotado',
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.5),
                          fontSize: 10,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  
                  // Price row
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Divisas: \$${displayDivisas.toStringAsFixed(2)}',
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.8),
                          fontSize: 12,
                        ),
                      ),
                      Text(
                        'Precio: ${displayBs.toStringAsFixed(2)}',
                        style: const TextStyle(
                          color: AppColors.tertiary,
                          fontSize: 15,
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

  // Mock Products fallback to ensure the UI is gorgeous even if backend is empty/offline
  final List<Map<String, dynamic>> _mockProducts = [
    {
      'id': 101,
      'qr_id': 'PROD_REF_01',
      'name': 'Refrigeradora French Door 26"',
      'description': 'Refrigeradora premium con tecnología inverter, panel táctil digital, iluminación LED envolvente y dispensador exterior de agua y hielo. Acabado en acero inoxidable antihuellas.',
      'price': 1299.99,
      'rounded_price': 1300.00,
      'stock': 12,
      'category': 'Refrigeración',
      'product_type': 'Linea Blanca',
      'is_ar_visible': 1,
    },
    {
      'id': 102,
      'qr_id': 'PROD_LAV_02',
      'name': 'Lavadora Carga Frontal 20kg',
      'description': 'Lavadora inteligente de alta eficiencia con 14 ciclos de lavado regulables, dosificación automática de detergente y control WiFi a través de la app del hogar.',
      'price': 849.49,
      'rounded_price': 850.00,
      'stock': 8,
      'category': 'Lavado',
      'product_type': 'Linea Blanca',
      'is_ar_visible': 1,
    },
    {
      'id': 103,
      'qr_id': 'PROD_TV_03',
      'name': 'Smart TV QLED 4K 65" Ultra',
      'description': 'Televisor inteligente de última generación con mil millones de tonos de color y procesador Quantum 4K. Audio Dolby Atmos integrado y modo de juego fluido de 120Hz.',
      'price': 1099.00,
      'rounded_price': 1099.00,
      'stock': 15,
      'category': 'Televisión',
      'product_type': 'Linea Gris',
      'is_ar_visible': 0,
    },
    {
      'id': 104,
      'qr_id': 'PROD_MIC_04',
      'name': 'Horno Microondas Grill 1.2 cft',
      'description': 'Horno microondas con función grill y convección. Menús automáticos para cocción saludable, descongelación rápida por peso y panel de control táctil de espejo templado.',
      'price': 229.89,
      'rounded_price': 230.00,
      'stock': 24,
      'category': 'Cocina',
      'product_type': 'Electrodomésticos',
      'is_ar_visible': 1,
    },
    {
      'id': 105,
      'qr_id': 'PROD_CAF_05',
      'name': 'Cafetera Espresso Barista Pro',
      'description': 'Cafetera espresso de bomba italiana de 15 bares con molino de café integrado y espumador de leche profesional. Prepara café espresso, capuchino y café latte auténtico.',
      'price': 449.99,
      'rounded_price': 450.00,
      'stock': 5,
      'category': 'Cafeteras',
      'product_type': 'Electrodomésticos',
      'is_ar_visible': 1,
    },
    {
      'id': 106,
      'qr_id': 'PROD_AC_06',
      'name': 'Aire Acondicionado Split 12k BTU',
      'description': 'Minisplit inverter frío/calor con filtro purificador de alta densidad. Operación súper silenciosa y reinicio automático tras corte de energía.',
      'price': 529.50,
      'rounded_price': 530.00,
      'stock': 0,
      'category': 'Climatización',
      'product_type': 'Linea Blanca',
      'is_ar_visible': 0,
    },
  ];
}
