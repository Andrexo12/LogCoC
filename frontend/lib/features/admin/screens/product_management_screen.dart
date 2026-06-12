import '../../../widgets/glass_effect.dart';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import '../../../core/api_service.dart';

class ProductManagementScreen extends StatefulWidget {
  const ProductManagementScreen({super.key});

  @override
  State<ProductManagementScreen> createState() => _ProductManagementScreenState();
}

class _ProductManagementScreenState extends State<ProductManagementScreen> {
  final ApiService _apiService = ApiService();
  List<dynamic> _products = [];
  bool _isLoading = true;
  bool _isImporting = false;
  bool _searchImages = true;
  String searchQuery = '';
  String? _error;
  final Set<int> _selectedProductIds = {};

  @override
  void initState() {
    super.initState();
    _loadProducts();
  }

  Future<void> _loadProducts() async {
    setState(() {
      _isLoading = true;
      _error = null;
      _selectedProductIds.clear();
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
          _error = 'Error de red al cargar el inventario';
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _showImportConfirmationDialog() async {
    bool localSearchImages = _searchImages;
    await showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              backgroundColor: const Color(0xFF131D31),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
                side: BorderSide(color: Colors.white.withOpacity(0.1), width: 1.2),
              ),
              title: Row(
                children: [
                  const Icon(Icons.upload_file_rounded, color: Colors.tealAccent),
                  const SizedBox(width: 10),
                  Text(
                    'Importar Productos',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.9), 
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                    ),
                  ),
                ],
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Sube un archivo Excel (.xlsx, .xls), factura en PDF o imagen para importar productos automáticamente.',
                    style: TextStyle(color: Colors.white70, fontSize: 13, height: 1.4),
                  ),
                  const SizedBox(height: 20),
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Buscar imágenes',
                              style: TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w600),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Busca automáticamente imágenes de productos en internet (DuckDuckGo) en segundo plano.',
                              style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 10, height: 1.2),
                            ),
                          ],
                        ),
                      ),
                      Switch(
                        value: localSearchImages,
                        activeColor: Colors.tealAccent,
                        onChanged: (val) {
                          setDialogState(() {
                            localSearchImages = val;
                          });
                          setState(() {
                            _searchImages = val;
                          });
                        },
                      ),
                    ],
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancelar', style: TextStyle(color: Colors.white70)),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.tealAccent,
                    foregroundColor: const Color(0xFF0B1222),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  onPressed: () {
                    Navigator.pop(context);
                    _importProducts();
                  },
                  child: const Text('Seleccionar Archivo', style: TextStyle(fontWeight: FontWeight.bold)),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<void> _importProducts() async {
    try {
      final FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['xlsx', 'xls', 'pdf', 'png', 'jpg', 'jpeg'],
        withData: true,
      );

      if (result != null && result.files.isNotEmpty) {
        final file = result.files.first;
        final fileBytes = file.bytes;
        final filename = file.name;

        if (fileBytes == null) {
          _showErrorToast('No se pudieron leer los bytes del archivo');
          return;
        }

        setState(() => _isImporting = true);
        
        // Mostrar modal de carga
        if (!mounted) return;
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) => const Dialog(
            backgroundColor: Colors.transparent,
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CircularProgressIndicator(valueColor: AlwaysStoppedAnimation<Color>(Colors.white)),
                  SizedBox(height: 16),
                  Text(
                    'Procesando archivo...',
                    style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ),
          ),
        );

        final importResult = await _apiService.importProductsFile(
          fileBytes, 
          filename,
          searchImages: _searchImages,
        );
        
        if (mounted) {
          Navigator.pop(context); // Cerrar modal de carga
          setState(() => _isImporting = false);
        }

        if (importResult['success']) {
          final count = importResult['data']['imported_count'] ?? 0;
          _showToast('¡Importación completada! Se agregaron $count productos.');
          _loadProducts();
        } else {
          _showErrorToast(importResult['message'] ?? 'Error durante la importación');
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isImporting = false);
      }
      _showErrorToast('Error al seleccionar o subir el archivo: $e');
    }
  }

  List<dynamic> get _filteredProducts {
    if (searchQuery.isEmpty) return _products;
    return _products.where((p) {
      final name = (p['name'] ?? '').toString().toLowerCase();
      final qrId = (p['qr_id'] ?? '').toString().toLowerCase();
      final category = (p['category'] ?? '').toString().toLowerCase();
      final searchLower = searchQuery.toLowerCase();
      return name.contains(searchLower) || qrId.contains(searchLower) || category.contains(searchLower);
    }).toList();
  }

  void _showFormDialog({Map<String, dynamic>? product}) {
    final isEditing = product != null;
    final formKey = GlobalKey<FormState>();

    // Form fields controllers
    final qrIdController = TextEditingController(text: product?['qr_id'] ?? '');
    final nameController = TextEditingController(text: product?['name'] ?? '');
    final descriptionController = TextEditingController(text: product?['description'] ?? '');
    final priceController = TextEditingController(text: product != null ? product['price'].toString() : '');
    final stockController = TextEditingController(text: product != null ? product['stock'].toString() : '');
    final categoryController = TextEditingController(text: product?['category'] ?? '');
    final imageUrlController = TextEditingController(text: product?['image_url'] ?? '');
    
    String selectedProductType = product?['product_type'] ?? 'Linea Blanca';
    bool isArVisible = (product?['is_ar_visible'] ?? 1) == 1;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return Dialog(
              backgroundColor: Colors.transparent,
              child: Container(
                width: 550,
                constraints: const BoxConstraints(maxWidth: 550),
                decoration: BoxDecoration(
                  color: const Color.fromRGBO(21, 31, 54, 0.95),
                  borderRadius: BorderRadius.circular(30),
                  border: Border.all(
                    color: Colors.white.withOpacity(0.18),
                    width: 1.5,
                  ),
                  boxShadow: const [
                    BoxShadow(
                      color: Colors.black54,
                      blurRadius: 24,
                      offset: Offset(0, 10),
                    )
                  ]
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(30),
                  child: GlassEffect(
                    sigmaX: 16,
                    sigmaY: 16,
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 28),
                      child: Form(
                        key: formKey,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  isEditing ? 'Editar Producto' : 'Nuevo Producto',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 24,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                IconButton(
                                  icon: const Icon(Icons.close, color: Colors.white70),
                                  onPressed: () => Navigator.pop(context),
                                )
                              ],
                            ),
                            const SizedBox(height: 24),
                            
                            // QR ID (Primary Key essentially)
                            _buildFormField(
                              controller: qrIdController,
                              label: 'ID de QR (Código Único)',
                              hint: 'Ej: PROD_LAV_05',
                              icon: Icons.qr_code_rounded,
                              enabled: !isEditing, // Do not change QR ID when editing
                              validator: (v) => v!.isEmpty ? 'Requerido' : null,
                            ),
                            const SizedBox(height: 16),

                            // Name
                            _buildFormField(
                              controller: nameController,
                              label: 'Nombre del Producto',
                              hint: 'Ej: Lavadora Premium 18Kg',
                              icon: Icons.abc_rounded,
                              validator: (v) => v!.isEmpty ? 'Requerido' : null,
                            ),
                            const SizedBox(height: 16),

                            // Description
                            _buildFormField(
                              controller: descriptionController,
                              label: 'Descripción',
                              hint: 'Detalles y características...',
                              icon: Icons.description_outlined,
                              maxLines: 3,
                              validator: (v) => v!.isEmpty ? 'Requerido' : null,
                            ),
                            const SizedBox(height: 16),

                            Row(
                              children: [
                                // Price
                                Expanded(
                                  child: _buildFormField(
                                    controller: priceController,
                                    label: 'Precio (\$)',
                                    hint: 'Ej: 799.99',
                                    icon: Icons.attach_money_rounded,
                                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                    validator: (v) {
                                      if (v!.isEmpty) return 'Requerido';
                                      if (double.tryParse(v) == null) return 'Número inválido';
                                      return null;
                                    },
                                  ),
                                ),
                                const SizedBox(width: 16),
                                // Stock
                                Expanded(
                                  child: _buildFormField(
                                    controller: stockController,
                                    label: 'Stock',
                                    hint: 'Ej: 10',
                                    icon: Icons.grid_3x3_rounded,
                                    keyboardType: TextInputType.number,
                                    validator: (v) {
                                      if (v!.isEmpty) return 'Requerido';
                                      if (int.tryParse(v) == null) return 'Entero inválido';
                                      return null;
                                    },
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),

                            // Category
                            _buildFormField(
                              controller: categoryController,
                              label: 'Categoría específica',
                              hint: 'Ej: Lavado, Refrigeración, TV',
                              icon: Icons.category_outlined,
                              validator: (v) => v!.isEmpty ? 'Requerido' : null,
                            ),
                            const SizedBox(height: 16),

                            // Image URL & Picker
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Expanded(
                                  child: _buildFormField(
                                    controller: imageUrlController,
                                    label: 'URL de la Imagen (dejar vacío para buscar automáticamente)',
                                    hint: 'Ej: https://ejemplo.com/imagen.jpg',
                                    icon: Icons.image_outlined,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                StatefulBuilder(
                                  builder: (context, setStateBtn) {
                                    bool uploading = false;
                                    return SizedBox(
                                      height: 54,
                                      child: ElevatedButton.icon(
                                        onPressed: uploading ? null : () async {
                                          try {
                                            final result = await FilePicker.platform.pickFiles(
                                              type: FileType.image,
                                              withData: true,
                                            );
                                            if (result != null && result.files.single.bytes != null) {
                                              setStateBtn(() => uploading = true);
                                              
                                              final uploadRes = await _apiService.uploadProductImage(
                                                result.files.single.bytes!,
                                                result.files.single.name,
                                              );
                                              
                                              if (uploadRes['success']) {
                                                final String newUrl = uploadRes['image_url'];
                                                imageUrlController.text = newUrl;
                                                _showToast('¡Imagen subida con éxito!');
                                              } else {
                                                _showErrorToast(uploadRes['message']);
                                              }
                                            }
                                          } catch (e) {
                                            _showErrorToast('Error al seleccionar imagen: $e');
                                          } finally {
                                            setStateBtn(() => uploading = false);
                                          }
                                        },
                                        icon: uploading 
                                          ? const SizedBox(
                                              width: 18, 
                                              height: 18, 
                                              child: CircularProgressIndicator(strokeWidth: 2, valueColor: AlwaysStoppedAnimation<Color>(Colors.white70))
                                            )
                                          : const Icon(Icons.upload_file_rounded),
                                        label: Text(uploading ? 'Subiendo...' : 'Subir'),
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: Colors.white.withOpacity(0.08),
                                          foregroundColor: Colors.white,
                                          elevation: 0,
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(14),
                                            side: BorderSide(color: Colors.white.withOpacity(0.15)),
                                          ),
                                          padding: const EdgeInsets.symmetric(horizontal: 16),
                                        ),
                                      ),
                                    );
                                  }
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),

                            // Product Type Selector (Linea Blanca/Gris/Electro)
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Tipo de Producto',
                                  style: TextStyle(color: Colors.white70, fontSize: 13),
                                ),
                                const SizedBox(height: 8),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 14),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withOpacity(0.06),
                                    borderRadius: BorderRadius.circular(14),
                                    border: Border.all(color: Colors.white.withOpacity(0.15)),
                                  ),
                                  child: DropdownButtonHideUnderline(
                                    child: DropdownButton<String>(
                                      value: selectedProductType,
                                      dropdownColor: const Color(0xFF151F36),
                                      icon: const Icon(Icons.arrow_drop_down, color: Colors.white70),
                                      style: const TextStyle(color: Colors.white, fontSize: 15),
                                      isExpanded: true,
                                      items: <String>['Linea Blanca', 'Linea Gris', 'Electrodomésticos']
                                          .map<DropdownMenuItem<String>>((String value) {
                                        return DropdownMenuItem<String>(
                                          value: value,
                                          child: Text(value),
                                        );
                                      }).toList(),
                                      onChanged: (String? newValue) {
                                        if (newValue != null) {
                                          setDialogState(() {
                                            selectedProductType = newValue;
                                          });
                                        }
                                      },
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 20),

                            // AR Visible Switch
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Compatible con AR',
                                      style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w600),
                                    ),
                                    Text(
                                      'Permite previsualización 3D en catálogo',
                                      style: TextStyle(color: Colors.white60, fontSize: 12),
                                    ),
                                  ],
                                ),
                                Switch(
                                  value: isArVisible,
                                  activeThumbColor: Colors.indigoAccent,
                                  inactiveThumbColor: Colors.white30,
                                  inactiveTrackColor: Colors.white12,
                                  onChanged: (bool value) {
                                    setDialogState(() {
                                      isArVisible = value;
                                    });
                                  },
                                ),
                              ],
                            ),
                            const SizedBox(height: 32),

                            // Submit Button
                            ElevatedButton(
                              onPressed: () async {
                                if (formKey.currentState!.validate()) {
                                  final data = {
                                    'qr_id': qrIdController.text.trim(),
                                    'name': nameController.text.trim(),
                                    'description': descriptionController.text.trim(),
                                    'price': double.parse(priceController.text.trim()),
                                    'stock': int.parse(stockController.text.trim()),
                                    'category': categoryController.text.trim(),
                                    'product_type': selectedProductType,
                                    'image_url': imageUrlController.text.trim(),
                                    'is_ar_visible': isArVisible ? 1 : 0,
                                  };

                                  Navigator.pop(context); // Close dialog
                                  _showLoadingOverlay();

                                  Map<String, dynamic> result;
                                  if (isEditing) {
                                    result = await _apiService.updateProduct(product['id'], data);
                                  } else {
                                    result = await _apiService.createProduct(data);
                                  }

                                  _hideLoadingOverlay();

                                  if (result['success']) {
                                    _showToast(isEditing ? '¡Producto actualizado!' : '¡Producto creado!');
                                    _loadProducts();
                                  } else {
                                    _showErrorToast(result['message']);
                                  }
                                }
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.white,
                                foregroundColor: const Color(0xFF0B1222),
                                padding: const EdgeInsets.symmetric(vertical: 16),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(14),
                                ),
                              ),
                              child: Text(
                                isEditing ? 'Guardar Cambios' : 'Añadir Producto',
                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                              ),
                            )
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  void _confirmDelete(int productId, String name) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: const Color(0xFF151F36),
          title: const Text('Eliminar Producto', style: TextStyle(color: Colors.white)),
          content: Text('¿Está seguro de que desea eliminar "$name"? Esta acción no se puede deshacer.',
              style: const TextStyle(color: Colors.white70)),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancelar', style: TextStyle(color: Colors.white54)),
            ),
            ElevatedButton(
              onPressed: () async {
                Navigator.pop(context); // Close dialog
                _showLoadingOverlay();
                
                final result = await _apiService.deleteProduct(productId);
                
                _hideLoadingOverlay();
                if (result['success']) {
                  _showToast('Producto eliminado correctamente');
                  _loadProducts();
                } else {
                  _showErrorToast(result['message']);
                }
              },
              style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent, foregroundColor: Colors.white),
              child: const Text('Eliminar'),
            )
          ],
        );
      },
    );
  }

  void _confirmBulkDelete() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: const Color(0xFF151F36),
          title: const Text('Eliminar Productos Seleccionados', style: TextStyle(color: Colors.white)),
          content: Text('¿Está seguro de que desea eliminar los ${_selectedProductIds.length} productos seleccionados? Esta acción no se puede deshacer.',
              style: const TextStyle(color: Colors.white70)),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancelar', style: TextStyle(color: Colors.white54)),
            ),
            ElevatedButton(
              onPressed: () async {
                Navigator.pop(context); // Close dialog
                _showLoadingOverlay();
                
                final result = await _apiService.bulkDeleteProducts(_selectedProductIds.toList());
                
                _hideLoadingOverlay();
                if (result['success']) {
                  _showToast('Productos eliminados correctamente');
                  _loadProducts();
                } else {
                  _showErrorToast(result['message']);
                }
              },
              style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent, foregroundColor: Colors.white),
              child: const Text('Eliminar'),
            )
          ],
        );
      },
    );
  }

  void _showLoadingOverlay() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(
        child: CircularProgressIndicator(valueColor: AlwaysStoppedAnimation<Color>(Colors.white)),
      ),
    );
  }

  void _hideLoadingOverlay() {
    Navigator.of(context, rootNavigator: true).pop();
  }

  void _showToast(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.teal),
    );
  }

  void _showErrorToast(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.redAccent),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0B1222),
      appBar: AppBar(
        title: const Text(
          'Inventario LogCoC',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        backgroundColor: const Color(0xFF0B1222),
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
        actions: [
          if (_selectedProductIds.isNotEmpty) ...[
            IconButton(
              icon: const Icon(Icons.clear_all_rounded, color: Colors.white70),
              tooltip: 'Deseleccionar todo',
              onPressed: () {
                setState(() {
                  _selectedProductIds.clear();
                });
              },
            ),
            IconButton(
              icon: const Icon(Icons.delete_sweep_rounded, color: Color(0xFFEF4444)),
              tooltip: 'Eliminar seleccionados (${_selectedProductIds.length})',
              onPressed: _confirmBulkDelete,
            ),
          ],
          IconButton(
            icon: const Icon(Icons.upload_file_rounded, color: Colors.tealAccent),
            tooltip: 'Importar Excel/Factura',
            onPressed: _isImporting ? null : _showImportConfirmationDialog,
          ),
          IconButton(
            icon: const Icon(Icons.refresh_rounded, color: Colors.white),
            tooltip: 'Refrescar',
            onPressed: _loadProducts,
          )
        ],
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
        child: SafeArea(
          child: Column(
            children: [
              _buildSearchBar(),
              Expanded(
                child: _isLoading
                    ? const Center(
                        child: CircularProgressIndicator(
                          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      )
                    : _error != null
                        ? _buildErrorView()
                        : _buildProductList(),
              ),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showFormDialog(),
        backgroundColor: Colors.indigoAccent,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add),
        label: const Text('Nuevo Producto'),
      ),
    );
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.06),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.white.withOpacity(0.12)),
        ),
        child: TextField(
          style: const TextStyle(color: Colors.white),
          decoration: InputDecoration(
            hintText: 'Buscar por QR, nombre o categoría...',
            hintStyle: TextStyle(color: Colors.white.withOpacity(0.4)),
            prefixIcon: const Icon(Icons.search, color: Colors.white54),
            border: InputBorder.none,
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          ),
          onChanged: (v) => setState(() => searchQuery = v),
        ),
      ),
    );
  }

  Widget _buildErrorView() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.cloud_off_rounded, size: 64, color: Colors.redAccent),
          const SizedBox(height: 16),
          Text(_error!, style: const TextStyle(color: Colors.white, fontSize: 16)),
          const SizedBox(height: 16),
          ElevatedButton(onPressed: _loadProducts, child: const Text('Reintentar')),
        ],
      ),
    );
  }

  Widget _buildProductList() {
    final list = _filteredProducts;
    if (list.isEmpty) {
      return Center(
        child: Text(
          'No se encontraron productos en el inventario.',
          style: TextStyle(color: Colors.white.withOpacity(0.6), fontSize: 16),
        ),
      );
    }

    return ListView.builder(
      physics: const ClampingScrollPhysics(),
      padding: const EdgeInsets.only(left: 16, right: 16, top: 8, bottom: 88),
      itemCount: list.length,
      itemBuilder: (context, index) {
        final prod = list[index];
        final name = prod['name'] ?? 'Producto';
        final qrId = prod['qr_id'] ?? 'Sin ID';
        final category = prod['category'] ?? 'Sin Categoría';
        final double price = (prod['price'] is num) ? (prod['price'] as num).toDouble() : 0.0;
        final int stock = (prod['stock'] is num) ? (prod['stock'] as num).toInt() : 0;
        final bool isAr = prod['is_ar_visible'] == 1;

        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.04),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.white.withOpacity(0.1)),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: GlassEffect(
              sigmaX: 8,
              sigmaY: 8,
              child: ListTile(
                contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                leading: Checkbox(
                  value: _selectedProductIds.contains(prod['id']),
                  activeColor: Colors.indigoAccent,
                  checkColor: Colors.white,
                  side: BorderSide(color: Colors.white.withOpacity(0.4)),
                  onChanged: (bool? val) {
                    setState(() {
                      if (val == true) {
                        _selectedProductIds.add(prod['id']);
                      } else {
                        _selectedProductIds.remove(prod['id']);
                      }
                    });
                  },
                ),
                onTap: () {
                  setState(() {
                    if (_selectedProductIds.contains(prod['id'])) {
                      _selectedProductIds.remove(prod['id']);
                    } else {
                      _selectedProductIds.add(prod['id']);
                    }
                  });
                },
                title: Row(
                  children: [
                    Expanded(
                      child: Text(
                        name,
                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
                      ),
                    ),
                    if (isAr)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: Colors.indigoAccent.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: const Text('AR', style: TextStyle(color: Colors.indigoAccent, fontSize: 10, fontWeight: FontWeight.bold)),
                      ),
                  ],
                ),
                subtitle: Padding(
                  padding: const EdgeInsets.only(top: 8.0),
                  child: Text(
                    'QR: $qrId • Cat: $category\nPrecio: \$${price.toStringAsFixed(2)} • Stock: $stock',
                    style: TextStyle(color: Colors.white.withOpacity(0.6), fontSize: 13, height: 1.4),
                  ),
                ),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.edit_outlined, color: Colors.cyanAccent),
                      tooltip: 'Editar',
                      onPressed: () => _showFormDialog(product: prod),
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete_outline, color: Color(0xFFEF4444)),
                      tooltip: 'Eliminar',
                      onPressed: () => _confirmDelete(prod['id'], name),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildFormField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    bool enabled = true,
    int maxLines = 1,
    TextInputType keyboardType = TextInputType.text,
    String? Function(String?)? validator,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(color: Colors.white70, fontSize: 13),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          enabled: enabled,
          maxLines: maxLines,
          keyboardType: keyboardType,
          style: TextStyle(color: enabled ? Colors.white : Colors.white38),
          validator: validator,
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: TextStyle(color: Colors.white.withOpacity(0.3)),
            prefixIcon: Icon(icon, color: enabled ? Colors.white54 : Colors.white24, size: 20),
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
              borderSide: const BorderSide(color: Colors.indigoAccent, width: 1.5),
            ),
            disabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide(color: Colors.white.withOpacity(0.05)),
            ),
          ),
        ),
      ],
    );
  }
}
