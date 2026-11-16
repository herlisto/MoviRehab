import 'package:flutter/material.dart';
import 'package:movirehab/controllers/ajustes_controller.dart';
import 'package:movirehab/controllers/movirehab_controller.dart';
import 'package:movirehab/l10n/app_localizations.dart';
import 'package:movirehab/main.dart';
import 'package:movirehab/services/fuente_movimiento.dart';
import 'package:movirehab/theme/app_theme.dart';
import 'package:provider/provider.dart';

import 'fake_repository.dart';

Widget _proveedores({
  required MoviRehabController controlador,
  required AjustesController? ajustes,
  required FuenteMovimiento? fuente,
  required Widget hijo,
}) {
  return MultiProvider(
    providers: [
      ChangeNotifierProvider<MoviRehabController>.value(value: controlador),
      ChangeNotifierProvider<AjustesController>.value(
        value: ajustes ?? AjustesController(repositorio: FakeRepository()),
      ),
      Provider<FuenteMovimiento>.value(
        value: fuente ?? const FuenteNoDisponible(),
      ),
    ],
    child: hijo,
  );
}

/// Pantalla suelta dentro de un `MaterialApp` localizado y con los
/// controladores. Por defecto no hay sensor (modo manual).
Widget envolverPantalla(
  Widget pantalla,
  MoviRehabController controlador, {
  Locale locale = const Locale('es'),
  AjustesController? ajustes,
  FuenteMovimiento? fuente,
}) {
  return _proveedores(
    controlador: controlador,
    ajustes: ajustes,
    fuente: fuente,
    hijo: MaterialApp(
      theme: AppTheme.claro,
      darkTheme: AppTheme.oscuro,
      locale: locale,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: pantalla,
    ),
  );
}

/// La aplicación completa (rutas incluidas). Con `locale: null` el idioma sale
/// de [ajustes], como en la aplicación real.
Widget envolverApp(
  MoviRehabController controlador, {
  Locale? locale = const Locale('es'),
  AjustesController? ajustes,
  FuenteMovimiento? fuente,
}) {
  return _proveedores(
    controlador: controlador,
    ajustes: ajustes,
    fuente: fuente,
    hijo: MoviRehabApp(locale: locale),
  );
}
