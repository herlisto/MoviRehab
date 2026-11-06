import 'package:flutter/material.dart';

import 'mensaje_estado.dart';

/// Pantalla que se muestra en navegador (Web): SQLite local y los permisos del
/// dispositivo no están disponibles allí. Texto bilingüe porque aún no hay
/// localización cargada.
class PlataformaNoSoportadaApp extends StatelessWidget {
  const PlataformaNoSoportadaApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'MoviRehab',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.teal),
      ),
      home: const Scaffold(
        body: MensajeEstado(
          icono: Icons.devices_other,
          mensaje:
              'MoviRehab no está disponible en el navegador. '
              'Ejecútala en Windows o Android.\n\n'
              'MoviRehab is not available in the browser. '
              'Run it on Windows or Android.',
        ),
      ),
    );
  }
}
