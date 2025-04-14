import 'package:flutter/material.dart';

class PrivacyPage extends StatelessWidget {
  const PrivacyPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Aviso de Privacidad')),
      body: const Padding(
        padding: EdgeInsets.all(16),
        child: SingleChildScrollView(
          child: Text(
            'Este es el aviso de privacidad. Aquí se explica cómo se recopilan, '
            'almacenan y protegen los datos de los usuarios. Es importante adaptarlo '
            'a los requisitos legales vigentes.',
            style: TextStyle(fontSize: 16),
          ),
        ),
      ),
    );
  }
}
