import 'package:flutter/material.dart';

/// Cifra destacada con icono y etiqueta (sesiones, repeticiones, racha...).
class TarjetaEstadistica extends StatelessWidget {
  final IconData icono;
  final String valor;
  final String etiqueta;

  /// Color del icono y del fondo del icono (por defecto, el primario).
  final Color? color;

  const TarjetaEstadistica({
    super.key,
    required this.icono,
    required this.valor,
    required this.etiqueta,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    final esquema = Theme.of(context).colorScheme;
    final acento = color ?? esquema.primary;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: acento.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icono, color: acento, size: 22),
            ),
            const SizedBox(height: 10),
            FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              child: Text(
                valor,
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w800,
                  color: esquema.onSurface,
                ),
              ),
            ),
            Text(
              etiqueta,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.bodySmall
                  ?.copyWith(color: esquema.onSurfaceVariant),
            ),
          ],
        ),
      ),
    );
  }
}

/// Rejilla adaptable de tarjetas de estadísticas: 2 columnas en pantallas
/// estrechas y 4 en las anchas.
class RejillaEstadisticas extends StatelessWidget {
  final List<Widget> hijos;

  const RejillaEstadisticas({super.key, required this.hijos});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, restricciones) {
        final columnas = restricciones.maxWidth >= 560 ? 4 : 2;
        const separacion = 12.0;
        final ancho =
            (restricciones.maxWidth - separacion * (columnas - 1)) / columnas;
        return Wrap(
          spacing: separacion,
          runSpacing: separacion,
          children: [
            for (final hijo in hijos) SizedBox(width: ancho, child: hijo),
          ],
        );
      },
    );
  }
}

/// Título de sección con una pequeña barra de color.
class TituloSeccion extends StatelessWidget {
  final String texto;
  final Widget? accion;

  const TituloSeccion({super.key, required this.texto, this.accion});

  @override
  Widget build(BuildContext context) {
    final esquema = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.only(top: 24, bottom: 10),
      child: Row(
        children: [
          Container(
            width: 5,
            height: 20,
            decoration: BoxDecoration(
              color: esquema.secondary,
              borderRadius: BorderRadius.circular(3),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              texto,
              style: Theme.of(context).textTheme.titleMedium
                  ?.copyWith(fontWeight: FontWeight.w700),
            ),
          ),
          if (accion != null) accion!,
        ],
      ),
    );
  }
}
