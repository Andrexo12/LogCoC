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
      appBar: AppBar(title: const Text('Configuración AR')),
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
