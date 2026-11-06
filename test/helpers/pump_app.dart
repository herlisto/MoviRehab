import 'package:flutter/material.dart';
import 'package:movirehab/controllers/movirehab_controller.dart';
import 'package:movirehab/l10n/app_localizations.dart';
import 'package:movirehab/main.dart';
import 'package:provider/provider.dart';

/// Pantalla suelta dentro de un `MaterialApp` localizado y con el controlador.
Widget envolverPantalla(
  Widget pantalla,
  MoviRehabController controlador, {
  Locale locale = const Locale('es'),
}) {
  return ChangeNotifierProvider<MoviRehabController>.value(
    value: controlador,
    child: MaterialApp(
      locale: locale,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: pantalla,
    ),
  );
}

/// La aplicación completa (rutas incluidas) con el controlador dado.
Widget envolverApp(
  MoviRehabController controlador, {
  Locale locale = const Locale('es'),
}) {
  return ChangeNotifierProvider<MoviRehabController>.value(
    value: controlador,
    child: MoviRehabApp(locale: locale),
  );
}
