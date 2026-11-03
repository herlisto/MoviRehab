import 'package:flutter/material.dart';

class AjustesPermisosScreen extends StatelessWidget {
  const AjustesPermisosScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Ajustes y Permisos')),
      body: ListView(
        children: const [
          ListTile(title: Text('Permiso de Cámara'), trailing: Icon(Icons.check)),
          ListTile(title: Text('Permiso de Micrófono'), trailing: Icon(Icons.check)),
        ],
      ),
    );
  }
}
