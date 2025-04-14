import 'package:flutter/material.dart';

class TermsPage extends StatelessWidget {
  const TermsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Términos y Condiciones')),
      body: const Padding(
        padding: EdgeInsets.all(16),
        child: SingleChildScrollView(
          child: Text(
            'Aquí van los términos y condiciones de uso de la plataforma. '
            'Puedes personalizar esta sección con los detalles legales, políticas y reglas que apliquen.',
            style: TextStyle(fontSize: 16),
          ),
        ),
      ),
    );
  }
}
