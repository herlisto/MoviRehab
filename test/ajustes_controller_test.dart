import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:movirehab/controllers/ajustes_controller.dart';

import 'helpers/fake_repository.dart';

void main() {
  late FakeRepository repositorio;
  late AjustesController ajustes;

  setUp(() {
    repositorio = FakeRepository();
    ajustes = AjustesController(repositorio: repositorio);
  });

  tearDown(() => ajustes.dispose());

  test('por defecto sigue el tema y el idioma del dispositivo', () async {
    await ajustes.cargar();

    expect(ajustes.modoTema, ThemeMode.system);
    expect(ajustes.idioma, isNull);
  });

  test('cambiar el tema notifica al instante y lo guarda', () async {
    var avisos = 0;
    ajustes.addListener(() => avisos++);

    final futuro = ajustes.cambiarModoTema(ThemeMode.dark);
    expect(ajustes.modoTema, ThemeMode.dark);
    expect(avisos, 1);
    await futuro;

    expect(repositorio.ajustes[AjustesController.claveTema], 'dark');
  });

  test('cambiar el idioma notifica al instante y lo guarda', () async {
    var avisos = 0;
    ajustes.addListener(() => avisos++);

    final futuro = ajustes.cambiarIdioma(const Locale('en'));
    expect(ajustes.idioma, const Locale('en'));
    expect(avisos, 1);
    await futuro;

    expect(repositorio.ajustes[AjustesController.claveIdioma], 'en');
  });

  test('elegir lo mismo no notifica', () async {
    await ajustes.cambiarModoTema(ThemeMode.dark);
    await ajustes.cambiarIdioma(const Locale('es'));
    var avisos = 0;
    ajustes.addListener(() => avisos++);

    await ajustes.cambiarModoTema(ThemeMode.dark);
    await ajustes.cambiarIdioma(const Locale('es'));

    expect(avisos, 0);
  });

  test('cargar recupera las preferencias guardadas', () async {
    repositorio.ajustes[AjustesController.claveTema] = 'dark';
    repositorio.ajustes[AjustesController.claveIdioma] = 'en';

    await ajustes.cargar();

    expect(ajustes.modoTema, ThemeMode.dark);
    expect(ajustes.idioma?.languageCode, 'en');
  });

  test('valores guardados desconocidos se ignoran', () async {
    repositorio.ajustes[AjustesController.claveTema] = 'rosa';
    repositorio.ajustes[AjustesController.claveIdioma] = 'fr';

    await ajustes.cargar();

    expect(ajustes.modoTema, ThemeMode.system);
    expect(ajustes.idioma, isNull);
  });

  test('si falla la base de datos la preferencia sigue activa', () async {
    repositorio.fallar = true;

    await ajustes.cargar();
    await ajustes.cambiarModoTema(ThemeMode.light);

    expect(ajustes.modoTema, ThemeMode.light);
    expect(repositorio.ajustes, isEmpty);
  });
}
