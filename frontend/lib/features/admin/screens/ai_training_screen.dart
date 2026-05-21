import 'package:flutter/material.dart';

class AITrainingScreen extends StatefulWidget {
  const AITrainingScreen({super.key});

  @override
  State<AITrainingScreen> createState() => _AITrainingScreenState();
}

class _AITrainingScreenState extends State<AITrainingScreen> {
  final _questionController = TextEditingController();
  final _answerController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Entrenamiento de IA')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              controller: _questionController,
              decoration: const InputDecoration(labelText: 'Pregunta frecuente'),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: _answerController,
              decoration: const InputDecoration(labelText: 'Respuesta predeterminada'),
              maxLines: 3,
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                // TODO: Enviar al backend
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Respuesta guardada con éxito')),
                );
              },
              child: const Text('Guardar Entrenamiento'),
            ),
          ],
        ),
      ),
    );
  }
}
