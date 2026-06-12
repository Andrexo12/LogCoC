import 'package:flutter/material.dart';

class ARSettingsScreen extends StatefulWidget {
  const ARSettingsScreen({super.key});

  @override
  State<ARSettingsScreen> createState() => _ARSettingsScreenState();
}

class _ARSettingsScreenState extends State<ARSettingsScreen> {
  Map<String, bool> settings = {
    'Precio': true,
    'Descripción': true,
    'Stock': true,
    'Chatbot': true,
  };

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Configuración AR',
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
      ),
      body: ListView(
        children: settings.keys.map((String key) {
          return CheckboxListTile(
            title: Text(key),
            subtitle: Text('Mostrar $key en la vista AR'),
            value: settings[key],
            onChanged: (bool? value) {
              setState(() {
                settings[key] = value!;
              });
              // TODO: Guardar en backend
            },
          );
        }).toList(),
      ),
    );
  }
}
