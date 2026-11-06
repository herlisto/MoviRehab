import 'package:flutter/material.dart';

/// Mensaje centrado con icono, usado para estados vacíos y de error.
/// Si se indica [textoAccion] y [onAccion] se muestra un botón (p. ej. Reintentar).
class MensajeEstado extends StatelessWidget {
  final IconData icono;
  final String mensaje;
  final String? textoAccion;
  final VoidCallback? onAccion;

  const MensajeEstado({
    super.key,
    required this.icono,
    required this.mensaje,
    this.textoAccion,
    this.onAccion,
  });

  @override
  Widget build(BuildContext context) {
    final esquema = Theme.of(context).colorScheme;
    final accion = onAccion;
    final textoBoton = textoAccion;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icono, size: 48, color: esquema.onSurfaceVariant),
            const SizedBox(height: 12),
            Text(
              mensaje,
              textAlign: TextAlign.center,
              style: TextStyle(color: esquema.onSurfaceVariant),
            ),
            if (accion != null && textoBoton != null) ...[
              const SizedBox(height: 16),
              FilledButton.tonal(onPressed: accion, child: Text(textoBoton)),
            ],
          ],
        ),
      ),
    );
  }
}
