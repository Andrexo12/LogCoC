import '../../../widgets/glass_effect.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../core/api_service.dart';
import 'package:logw_front/core/theme/app_colors.dart';

class QrGeneratorScreen extends StatefulWidget {
  const QrGeneratorScreen({super.key});

  @override
  State<QrGeneratorScreen> createState() => _QrGeneratorScreenState();
}

class _QrGeneratorScreenState extends State<QrGeneratorScreen> {
  final ApiService _apiService = ApiService();
  
  // Selection state
  String _selectedTargetType = 'Producto'; // Producto, Catalogo, Chatbot, Personalizado
  List<dynamic> _products = [];
  Map<String, dynamic>? _selectedProduct;
  
  String _selectedCatalogCategory = 'Todos';
  final _customUrlController = TextEditingController();
  
  bool _isLoadingProducts = false;
  String _generatedLink = '';
  
  final List<String> _categories = ['Todos', 'Linea Blanca', 'Linea Gris', 'Electrodomésticos'];

  @override
  void initState() {
    super.initState();
    _loadProducts();
    _updateGeneratedLink();
    _customUrlController.addListener(_updateGeneratedLink);
  }

  @override
  void dispose() {
    _customUrlController.dispose();
    super.dispose();
  }

  Future<void> _loadProducts() async {
    setState(() => _isLoadingProducts = true);
    try {
      final products = await _apiService.getProducts();
      // If API returns no products, use some mock entries for the dropdown
      if (products.isEmpty) {
        _products = _mockProducts;
      } else {
        _products = products;
      }
      
      if (_products.isNotEmpty) {
        _selectedProduct = _products.first;
      }
    } catch (e) {
      _products = _mockProducts;
      if (_products.isNotEmpty) {
        _selectedProduct = _products.first;
      }
    } finally {
      if (mounted) {
        setState(() => _isLoadingProducts = false);
        _updateGeneratedLink();
      }
    }
  }

  void _updateGeneratedLink() {
    final origin = Uri.base.origin;
    String link = '';

    switch (_selectedTargetType) {
      case 'Producto':
        if (_selectedProduct != null) {
          final qrId = _selectedProduct!['qr_id'] ?? '';
          link = '$origin/#/product/$qrId';
        } else {
          link = '$origin/#/product/placeholder';
        }
        break;
      case 'Catalogo':
        link = '$origin/#/catalog?category=${Uri.encodeComponent(_selectedCatalogCategory)}';
        break;
      case 'Chatbot':
        link = '$origin/#/chatbot';
        break;
      case 'Personalizado':
        link = _customUrlController.text.trim();
        if (link.isEmpty) {
          link = 'https://innovacenter.com';
        }
        break;
    }

    setState(() {
      _generatedLink = link;
    });
  }

  void _copyToClipboard(String text, String message) {
    Clipboard.setData(ClipboardData(text: text));
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
                      message,
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
    final qrImageUrl = 'https://api.qrserver.com/v1/create-qr-code/?size=250x250&data=${Uri.encodeComponent(_generatedLink)}';
    
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: const Text(
          'Generador de Códigos QR',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        backgroundColor: AppColors.background.withOpacity(0.7),
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
        flexibleSpace: ClipRect(
          child: GlassEffect(
            child: Container(color: Colors.transparent),
          ),
        ),
      ),
      body: Stack(
        children: [
          _bg(),
          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Form Card
                  _sectionCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Destino del Código QR',
                          style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 20),
                        
                        // Target Type Dropdown
                        const Text('Tipo de Destino', style: TextStyle(color: AppColors.textSecondary, fontSize: 13)),
                        const SizedBox(height: 8),
                        _dropdownContainer(
                          child: DropdownButtonHideUnderline(
                            child: DropdownButton<String>(
                              value: _selectedTargetType,
                              dropdownColor: const Color(0xFF151F36),
                              icon: const Icon(Icons.arrow_drop_down, color: AppColors.textSecondary),
                              style: const TextStyle(color: Colors.white, fontSize: 15),
                              isExpanded: true,
                              items: const [
                                DropdownMenuItem(value: 'Producto', child: Text('Producto Específico')),
                                DropdownMenuItem(value: 'Catalogo', child: Text('Categoría del Catálogo')),
                                DropdownMenuItem(value: 'Chatbot', child: Text('Asistente AI Chatbot')),
                                DropdownMenuItem(value: 'Personalizado', child: Text('Enlace Personalizado')),
                              ],
                              onChanged: (String? val) {
                                if (val != null) {
                                  setState(() {
                                    _selectedTargetType = val;
                                  });
                                  _updateGeneratedLink();
                                }
                              },
                            ),
                          ),
                        ),
                        const SizedBox(height: 20),

                        // Sub-options based on Target Type
                        if (_selectedTargetType == 'Producto') ...[
                          const Text('Seleccionar Producto', style: TextStyle(color: AppColors.textSecondary, fontSize: 13)),
                          const SizedBox(height: 8),
                          _isLoadingProducts
                              ? const Center(child: Padding(padding: EdgeInsets.all(8.0), child: CircularProgressIndicator(color: Colors.white)))
                              : _dropdownContainer(
                                  child: DropdownButtonHideUnderline(
                                    child: DropdownButton<Map<String, dynamic>>(
                                      value: _selectedProduct,
                                      dropdownColor: const Color(0xFF151F36),
                                      icon: const Icon(Icons.arrow_drop_down, color: AppColors.textSecondary),
                                      style: const TextStyle(color: Colors.white, fontSize: 15),
                                      isExpanded: true,
                                      items: _products.map<DropdownMenuItem<Map<String, dynamic>>>((prod) {
                                        return DropdownMenuItem<Map<String, dynamic>>(
                                          value: prod,
                                          child: Text('${prod['name']} (${prod['qr_id']})'),
                                        );
                                      }).toList(),
                                      onChanged: (Map<String, dynamic>? val) {
                                        if (val != null) {
                                          setState(() {
                                            _selectedProduct = val;
                                          });
                                          _updateGeneratedLink();
                                        }
                                      },
                                    ),
                                  ),
                                ),
                        ] else if (_selectedTargetType == 'Catalogo') ...[
                          const Text('Seleccionar Categoría', style: TextStyle(color: AppColors.textSecondary, fontSize: 13)),
                          const SizedBox(height: 8),
                          _dropdownContainer(
                            child: DropdownButtonHideUnderline(
                              child: DropdownButton<String>(
                                value: _selectedCatalogCategory,
                                dropdownColor: const Color(0xFF151F36),
                                icon: const Icon(Icons.arrow_drop_down, color: AppColors.textSecondary),
                                style: const TextStyle(color: Colors.white, fontSize: 15),
                                isExpanded: true,
                                items: _categories.map<DropdownMenuItem<String>>((String value) {
                                  return DropdownMenuItem<String>(
                                    value: value,
                                    child: Text(value),
                                  );
                                }).toList(),
                                onChanged: (String? val) {
                                  if (val != null) {
                                    setState(() {
                                      _selectedCatalogCategory = val;
                                    });
                                    _updateGeneratedLink();
                                  }
                                },
                              ),
                            ),
                          ),
                        ] else if (_selectedTargetType == 'Personalizado') ...[
                          const Text('Enlace URL Completo', style: TextStyle(color: AppColors.textSecondary, fontSize: 13)),
                          const SizedBox(height: 8),
                          TextField(
                            controller: _customUrlController,
                            style: const TextStyle(color: Colors.white),
                            decoration: InputDecoration(
                              hintText: 'https://ejemplo.com/ruta',
                              hintStyle: TextStyle(color: Colors.white.withOpacity(0.3)),
                              filled: true,
                              fillColor: Colors.white.withOpacity(0.06),
                              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(14),
                                borderSide: BorderSide(color: Colors.white.withOpacity(0.15)),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(14),
                                borderSide: BorderSide(color: Colors.white.withOpacity(0.15)),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(14),
                                borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  
                  // QR Result Card
                  _sectionCard(
                    child: Column(
                      children: [
                        const Text(
                          'Código QR Generado',
                          style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Apunta a: $_generatedLink',
                          textAlign: TextAlign.center,
                          style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 12),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        if (_generatedLink.contains('localhost') || _generatedLink.contains('127.0.0.1')) ...[
                          const SizedBox(height: 12),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                            decoration: BoxDecoration(
                              color: Colors.amber.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: Colors.amber.withOpacity(0.3)),
                            ),
                            child: const Row(
                              children: [
                                Icon(Icons.warning_amber_rounded, color: Colors.amberAccent, size: 20),
                                SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    'Aviso: Estás usando localhost. Para escanear desde tu iPhone, abre esta página en tu PC usando la IP de tu red (ej. http://192.168.1.XX:5000) para que el QR apunte correctamente.',
                                    style: TextStyle(color: Colors.amberAccent, fontSize: 10, height: 1.3),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                        const SizedBox(height: 24),
                        
                        // QR Image Render
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(20),
                            boxShadow: const [
                              BoxShadow(color: Colors.black26, blurRadius: 16, offset: Offset(0, 8))
                            ]
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(10),
                            child: Image.network(
                              qrImageUrl,
                              width: 200,
                              height: 200,
                              fit: BoxFit.contain,
                              loadingBuilder: (context, child, loadingProgress) {
                                if (loadingProgress == null) return child;
                                return const SizedBox(
                                  width: 200,
                                  height: 200,
                                  child: Center(
                                    child: CircularProgressIndicator(color: Colors.indigo),
                                  ),
                                );
                              },
                              errorBuilder: (context, error, stackTrace) {
                                return Container(
                                  width: 200,
                                  height: 200,
                                  color: Colors.grey[200],
                                  child: const Center(
                                    child: Icon(Icons.qr_code_2_rounded, size: 80, color: Colors.grey),
                                  ),
                                );
                              },
                            ),
                          ),
                        ),
                        const SizedBox(height: 24),

                        // Action Buttons
                        Row(
                          children: [
                            Expanded(
                              child: OutlinedButton.icon(
                                onPressed: () => _copyToClipboard(_generatedLink, '¡Enlace de destino copiado!'),
                                icon: const Icon(Icons.link_rounded),
                                label: const Text('Copiar Destino'),
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: Colors.white,
                                  side: BorderSide(color: Colors.white.withOpacity(0.2)),
                                  padding: const EdgeInsets.symmetric(vertical: 14),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: ElevatedButton.icon(
                                onPressed: () => _copyToClipboard(qrImageUrl, '¡Enlace del código QR copiado!'),
                                icon: const Icon(Icons.download_rounded),
                                label: const Text('Copiar QR Img'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.white,
                                  foregroundColor: AppColors.background,
                                  padding: const EdgeInsets.symmetric(vertical: 14),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'Nota: Abre el enlace del QR Img en tu navegador para imprimirlo o descargarlo.',
                          textAlign: TextAlign.center,
                          style: TextStyle(color: Colors.white.withOpacity(0.4), fontSize: 10),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          )
        ],
      ),
    );
  }

  Widget _sectionCard({required Widget child}) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white.withOpacity(0.12), width: 1.2),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: GlassEffect(
          child: child,
        ),
      ),
    );
  }

  Widget _dropdownContainer({required Widget child}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.06),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white.withOpacity(0.15)),
      ),
      child: child,
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

  final List<Map<String, dynamic>> _mockProducts = [
    {'name': 'Refrigeradora French Door 26"', 'qr_id': 'PROD_REF_01'},
    {'name': 'Lavadora Carga Frontal 20kg', 'qr_id': 'PROD_LAV_02'},
    {'name': 'Smart TV QLED 4K 65" Ultra', 'qr_id': 'PROD_TV_03'},
    {'name': 'Horno Microondas Grill 1.2 cft', 'qr_id': 'PROD_MIC_04'},
    {'name': 'Cafetera Espresso Barista Pro', 'qr_id': 'PROD_CAF_05'},
  ];
}
