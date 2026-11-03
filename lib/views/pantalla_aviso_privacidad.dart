import 'package:flutter/material.dart';

class AvisoPrivacidadScreen extends StatelessWidget {
  const AvisoPrivacidadScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Aviso de Privacidad')),
      body: const Padding(
        padding: EdgeInsets.all(16.0),
        child: Text('Tratamiento local de datos respetando la privacidad del usuario.'),
      ),
    );
  }
}
