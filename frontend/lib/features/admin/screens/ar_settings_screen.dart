import 'package:flutter/material.dart';
import '../../../core/api_service.dart';
import 'package:logw_front/core/theme/app_colors.dart';

class ARSettingsScreen extends StatefulWidget {
  const ARSettingsScreen({super.key});

  @override
  State<ARSettingsScreen> createState() => _ARSettingsScreenState();
}

class _ARSettingsScreenState extends State<ARSettingsScreen> {
  final ApiService _apiService = ApiService();
  bool _isLoading = true;
  Map<String, bool> settings = {
    'Precio': true,
    'Descripción': true,
    'Stock': true,
    'Chatbot': true,
  };

  @override
  void initState() {
    super.initState();
    _fetchSettings();
  }

  Future<void> _fetchSettings() async {
    setState(() {
      _isLoading = true;
    });
    final list = await _apiService.getARSettings();
    final Map<String, bool> updatedSettings = Map.from(settings);
    for (var item in list) {
      if (item is Map) {
        final name = item['section_name'] as String?;
        final isEnabled = item['is_enabled'] as int?;
        if (name != null && isEnabled != null) {
          updatedSettings[name] = isEnabled == 1;
        }
      }
    }
    setState(() {
      settings = updatedSettings;
      _isLoading = false;
    });
  }

  Future<void> _onToggleSetting(String key, bool newValue) async {
    // Optimistic UI update
    setState(() {
      settings[key] = newValue;
    });

    final res = await _apiService.toggleARSetting(key, newValue);
    if (!res['success']) {
      // Revert
      setState(() {
        settings[key] = !newValue;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al actualizar $key: ${res['message'] ?? 'Desconocido'}'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('$key actualizado correctamente'),
            duration: const Duration(seconds: 1),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: const Text(
          'Configuración AR',
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
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Colors.purpleAccent))
          : ListView(
              padding: const EdgeInsets.all(16.0),
              children: settings.keys.map((String key) {
                return Card(
                  color: Colors.white.withOpacity(0.05),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                    side: BorderSide(color: Colors.white.withOpacity(0.1)),
                  ),
                  child: CheckboxListTile(
                    title: Text(key, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                    subtitle: Text('Mostrar $key en la vista AR', style: TextStyle(color: Colors.white.withOpacity(0.6))),
                    value: settings[key],
                    activeColor: Colors.purpleAccent,
                    checkColor: Colors.white,
                    onChanged: (bool? value) {
                      if (value != null) {
                        _onToggleSetting(key, value);
                      }
                    },
                  ),
                );
              }).toList(),
            ),
    );
  }
}

