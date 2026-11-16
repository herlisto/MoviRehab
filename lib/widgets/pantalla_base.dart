import 'package:flutter/material.dart';

/// Ancho máximo del contenido: en Windows (ventanas anchas) el contenido se
/// centra en lugar de estirarse de lado a lado.
const double anchoMaximoContenido = 760;

/// Estructura común de las pantallas: fondo con degradado «naturaleza», barra
/// superior transparente y contenido centrado con ancho máximo.
class PantallaBase extends StatelessWidget {
  final String? titulo;
  final Widget cuerpo;
  final List<Widget>? acciones;
  final Widget? botonFlotante;
  final Widget? menuLateral;

  const PantallaBase({
    super.key,
    required this.cuerpo,
    this.titulo,
    this.acciones,
    this.botonFlotante,
    this.menuLateral,
  });

  @override
  Widget build(BuildContext context) {
    final esquema = Theme.of(context).colorScheme;
    final oscuro = esquema.brightness == Brightness.dark;

    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            oscuro
                ? esquema.primaryContainer.withValues(alpha: 0.55)
                : esquema.primaryContainer.withValues(alpha: 0.75),
            esquema.surface,
          ],
          stops: const [0.0, 0.45],
        ),
      ),
      child: Scaffold(
        backgroundColor: Colors.transparent,
        drawer: menuLateral,
        appBar: AppBar(
          title: titulo == null ? null : Text(titulo!),
          actions: acciones,
        ),
        floatingActionButton: botonFlotante,
        body: Align(
          alignment: Alignment.topCenter,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: anchoMaximoContenido),
            child: cuerpo,
          ),
        ),
      ),
    );
  }
}
