import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'controllers/movirehab_controller.dart';
import 'views/pantalla_inicio.dart';
import 'views/pantalla_perfil.dart';
import 'views/pantalla_plan_ejercicios.dart';
import 'views/pantalla_detalle_ejercicio.dart';
import 'views/pantalla_sesion_guiada.dart';
import 'views/pantalla_resumen_sesion.dart';
import 'views/pantalla_progreso.dart';
import 'views/pantalla_historial_mediciones.dart';
import 'views/pantalla_aviso_privacidad.dart';
import 'views/pantalla_ajustes_permisos.dart';

void main() {
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => MoviRehabController()),
      ],
      child: const MoviRehabApp(),
    ),
  );
}

class MoviRehabApp extends StatelessWidget {
  const MoviRehabApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'MoviRehab',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.teal),
      ),
      initialRoute: '/',
      routes: {
        '/': (context) => const InicioScreen(),
        '/perfil': (context) => const PerfilScreen(),
        '/plan': (context) => const PlanEjerciciosScreen(),
        '/detalle_ejercicio': (context) => const DetalleEjercicioScreen(),
        '/sesion_guiada': (context) => const SesionGuiadaScreen(),
        '/resumen': (context) => const ResumenSesionScreen(),
        '/progreso': (context) => const ProgresoScreen(),
        '/historial': (context) => const HistorialMedicionesScreen(),
        '/privacidad': (context) => const AvisoPrivacidadScreen(),
        '/ajustes': (context) => const AjustesPermisosScreen(),
      },
    );
  }
}