import 'package:flutter/material.dart';

class PerfilScreen extends StatelessWidget {
  const PerfilScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Perfil de Usuario')),
      body: const Padding(
        padding: EdgeInsets.all(16.0),
        child: Column(
          children: [
            CircleAvatar(radius: 40, child: Icon(Icons.person, size: 40)),
            SizedBox(height: 12),
            Text('Paciente Demo', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
            Text('ID SQLite: 1', style: TextStyle(color: Colors.grey)),
          ],
        ),
      ),
    );
  }
}