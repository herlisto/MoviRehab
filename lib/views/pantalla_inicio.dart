import 'package:flutter/material.dart';

class InicioScreen extends StatelessWidget {
  const InicioScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('MoviRehab - Inicio'),
        actions: [
          IconButton(
            icon: const Icon(Icons.privacy_tip),
            onPressed: () => Navigator.pushNamed(context, '/privacidad'),
          ),
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () => Navigator.pushNamed(context, '/ajustes'),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Card(
              color: Theme.of(context).colorScheme.primaryContainer,
              child: const Padding(
                padding: EdgeInsets.all(20.0),
                child: Column(
                  children: [
                    Icon(Icons.accessibility_new, size: 60),
                    SizedBox(height: 10),
                    Text(
                      'Rehabilitación de Movilidad Articular',
                      style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),
            ListTile(
              leading: const Icon(Icons.person),
              title: const Text('Perfil de Usuario'),
              onTap: () => Navigator.pushNamed(context, '/perfil'),
            ),
            ListTile(
              leading: const Icon(Icons.list),
              title: const Text('Plan de Ejercicios'),
              onTap: () => Navigator.pushNamed(context, '/plan'),
            ),
            ListTile(
              leading: const Icon(Icons.camera),
              title: const Text('Sesión Guiada NUI'),
              onTap: () => Navigator.pushNamed(context, '/sesion_guiada'),
            ),
            ListTile(
              leading: const Icon(Icons.show_chart),
              title: const Text('Progreso y Medias'),
              onTap: () => Navigator.pushNamed(context, '/progreso'),
            ),
            ListTile(
              leading: const Icon(Icons.history),
              title: const Text('Historial de Mediciones'),
              onTap: () => Navigator.pushNamed(context, '/historial'),
            ),
          ],
        ),
      ),
    );
  }
}