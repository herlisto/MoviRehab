import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'controllers/movirehab_controller.dart';
import 'l10n/app_localizations.dart';
import 'models/ejercicio_model.dart';
import 'routes.dart';
import 'views/pantalla_ajustes_permisos.dart';
import 'views/pantalla_aviso_privacidad.dart';
import 'views/pantalla_detalle_ejercicio.dart';
import 'views/pantalla_historial_mediciones.dart';
import 'views/pantalla_inicio.dart';
import 'views/pantalla_perfil.dart';
import 'views/pantalla_plan_ejercicios.dart';
import 'views/pantalla_progreso.dart';
import 'views/pantalla_resumen_sesion.dart';
import 'views/pantalla_sesion_guiada.dart';
import 'widgets/plataforma_no_soportada.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();

  // SQLite local y permisos de dispositivo no existen en navegador.
  if (kIsWeb) {
    runApp(const PlataformaNoSoportadaApp());
    return;
  }

  runApp(
    MultiProvider(
      providers: [ChangeNotifierProvider(create: (_) => MoviRehabController())],
      child: const MoviRehabApp(),
    ),
  );
}

class MoviRehabApp extends StatelessWidget {
  /// [locale] fuerza un idioma (útil en tests); `null` sigue el del dispositivo
  /// y usa español si el idioma del sistema no está soportado.
  const MoviRehabApp({super.key, this.locale});

  final Locale? locale;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      onGenerateTitle: (context) => AppLocalizations.of(context).appTitle,
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.teal),
      ),
      locale: locale,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      localeResolutionCallback: _resolverIdioma,
      initialRoute: Rutas.inicio,
      routes: {
        Rutas.inicio: (context) => const InicioScreen(),
        Rutas.perfil: (context) => const PerfilScreen(),
        Rutas.plan: (context) => const PlanEjerciciosScreen(),
        Rutas.sesionGuiada: (context) => const SesionGuiadaScreen(),
        Rutas.progreso: (context) => const ProgresoScreen(),
        Rutas.historial: (context) => const HistorialMedicionesScreen(),
        Rutas.privacidad: (context) => const AvisoPrivacidadScreen(),
        Rutas.ajustes: (context) => const AjustesPermisosScreen(),
      },
      onGenerateRoute: _generarRuta,
    );
  }

  /// Español por defecto; inglés solo si el dispositivo está en inglés.
  static Locale _resolverIdioma(
    Locale? dispositivo,
    Iterable<Locale> soportados,
  ) {
    if (dispositivo != null) {
      for (final candidato in soportados) {
        if (candidato.languageCode == dispositivo.languageCode) {
          return candidato;
        }
      }
    }
    return const Locale('es');
  }

  /// Rutas que reciben argumentos tipados.
  static Route<dynamic>? _generarRuta(RouteSettings settings) {
    final argumentos = settings.arguments;

    switch (settings.name) {
      case Rutas.detalleEjercicio:
        return MaterialPageRoute<void>(
          settings: settings,
          builder: (context) => DetalleEjercicioScreen(
            ejercicio: argumentos is EjercicioModel ? argumentos : null,
          ),
        );
      case Rutas.resumen:
        return MaterialPageRoute<void>(
          settings: settings,
          builder: (context) => ResumenSesionScreen(
            sesionId: argumentos is int ? argumentos : null,
          ),
        );
    }
    return null;
  }
}
