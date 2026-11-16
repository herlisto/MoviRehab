import 'package:flutter/material.dart';

/// Gráfico de barras sencillo (sin paquetes externos): una barra por valor.
/// La última barra (por ejemplo «hoy») se resalta con el color de acento.
class GraficoBarras extends StatelessWidget {
  final List<double> valores;
  final List<String> etiquetas;
  final double altura;

  /// Texto accesible que resume el gráfico.
  final String? descripcion;

  GraficoBarras({
    super.key,
    required this.valores,
    required this.etiquetas,
    this.altura = 140,
    this.descripcion,
  }) : assert(valores.length == etiquetas.length);

  @override
  Widget build(BuildContext context) {
    final esquema = Theme.of(context).colorScheme;
    final estilo = Theme.of(context).textTheme.labelSmall;
    final maximo = valores.fold<double>(0, (m, v) => v > m ? v : m);
    const alturaEtiquetas = 38.0;
    final alturaBarras = altura - alturaEtiquetas;

    return Semantics(
      label: descripcion,
      child: SizedBox(
        height: altura,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            for (var i = 0; i < valores.length; i++)
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Text(
                      valores[i] == 0 ? '' : valores[i].round().toString(),
                      style: estilo?.copyWith(color: esquema.onSurfaceVariant),
                    ),
                    const SizedBox(height: 2),
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 400),
                      curve: Curves.easeOutCubic,
                      width: 18,
                      height: maximo == 0
                          ? 4
                          : (alturaBarras - 16) *
                                    (valores[i] / maximo).clamp(0.0, 1.0) +
                                4,
                      decoration: BoxDecoration(
                        color: i == valores.length - 1
                            ? esquema.tertiary
                            : esquema.primary.withValues(
                                alpha: valores[i] == 0 ? 0.2 : 0.85,
                              ),
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      etiquetas[i],
                      style: estilo?.copyWith(color: esquema.onSurfaceVariant),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}

/// Gráfico de línea con área rellena. Los valores se reparten uniformemente
/// en horizontal. Con un único valor se dibuja un punto.
class GraficoLinea extends StatelessWidget {
  final List<double> valores;

  /// Etiqueta bajo el primer y el último punto.
  final String? etiquetaInicio;
  final String? etiquetaFin;
  final double altura;
  final String? descripcion;

  const GraficoLinea({
    super.key,
    required this.valores,
    this.etiquetaInicio,
    this.etiquetaFin,
    this.altura = 150,
    this.descripcion,
  });

  @override
  Widget build(BuildContext context) {
    final esquema = Theme.of(context).colorScheme;
    final estilo = Theme.of(context).textTheme.labelSmall
        ?.copyWith(color: esquema.onSurfaceVariant);

    return Semantics(
      label: descripcion,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            height: altura,
            width: double.infinity,
            child: CustomPaint(
              painter: _PintorLinea(
                valores: valores,
                color: esquema.primary,
                colorPunto: esquema.tertiary,
                colorCuadricula: esquema.outlineVariant,
              ),
            ),
          ),
          if (etiquetaInicio != null || etiquetaFin != null)
            Padding(
              padding: const EdgeInsets.only(top: 6),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(etiquetaInicio ?? '', style: estilo),
                  Text(etiquetaFin ?? '', style: estilo),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

class _PintorLinea extends CustomPainter {
  final List<double> valores;
  final Color color;
  final Color colorPunto;
  final Color colorCuadricula;

  _PintorLinea({
    required this.valores,
    required this.color,
    required this.colorPunto,
    required this.colorCuadricula,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final cuadricula = Paint()
      ..color = colorCuadricula
      ..strokeWidth = 1;
    for (var i = 0; i <= 3; i++) {
      final y = size.height * i / 3;
      canvas.drawLine(Offset(0, y), Offset(size.width, y), cuadricula);
    }
    if (valores.isEmpty) return;

    var minimo = valores.reduce((a, b) => a < b ? a : b);
    var maximo = valores.reduce((a, b) => a > b ? a : b);
    if (maximo - minimo < 1) {
      // Serie plana: se centra la línea con un margen artificial.
      minimo -= 5;
      maximo += 5;
    }
    const margen = 10.0;
    final alto = size.height - margen * 2;

    Offset punto(int i) {
      final x = valores.length == 1
          ? size.width / 2
          : margen + (size.width - margen * 2) * i / (valores.length - 1);
      final y = margen + alto * (1 - (valores[i] - minimo) / (maximo - minimo));
      return Offset(x, y);
    }

    final linea = Path()..moveTo(punto(0).dx, punto(0).dy);
    for (var i = 1; i < valores.length; i++) {
      final p = punto(i);
      linea.lineTo(p.dx, p.dy);
    }

    if (valores.length > 1) {
      final area = Path.from(linea)
        ..lineTo(punto(valores.length - 1).dx, size.height)
        ..lineTo(punto(0).dx, size.height)
        ..close();
      canvas.drawPath(
        area,
        Paint()
          ..shader = LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [color.withValues(alpha: 0.35), color.withValues(alpha: 0)],
          ).createShader(Offset.zero & size),
      );
      canvas.drawPath(
        linea,
        Paint()
          ..color = color
          ..style = PaintingStyle.stroke
          ..strokeWidth = 3
          ..strokeCap = StrokeCap.round
          ..strokeJoin = StrokeJoin.round,
      );
    }

    final relleno = Paint()..color = color;
    final centro = Paint()..color = colorPunto;
    for (var i = 0; i < valores.length; i++) {
      canvas.drawCircle(punto(i), 5, relleno);
      canvas.drawCircle(punto(i), 2.5, centro);
    }
  }

  @override
  bool shouldRepaint(covariant _PintorLinea anterior) =>
      anterior.valores != valores ||
      anterior.color != color ||
      anterior.colorPunto != colorPunto ||
      anterior.colorCuadricula != colorCuadricula;
}

/// Barra horizontal que compara un valor con su meta (media frente al
/// objetivo de un ejercicio).
class BarraObjetivo extends StatelessWidget {
  final String titulo;
  final String subtitulo;
  final String valorTexto;

  /// Fracción 0..1 (se limita automáticamente).
  final double fraccion;

  const BarraObjetivo({
    super.key,
    required this.titulo,
    required this.subtitulo,
    required this.valorTexto,
    required this.fraccion,
  });

  @override
  Widget build(BuildContext context) {
    final esquema = Theme.of(context).colorScheme;
    final textos = Theme.of(context).textTheme;
    final completo = fraccion >= 1;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                titulo,
                overflow: TextOverflow.ellipsis,
                style: textos.titleSmall?.copyWith(fontWeight: FontWeight.w700),
              ),
            ),
            Text(
              valorTexto,
              style: textos.titleSmall?.copyWith(
                color: completo ? esquema.primary : esquema.onSurface,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: TweenAnimationBuilder<double>(
            tween: Tween<double>(begin: 0, end: fraccion.clamp(0.0, 1.0)),
            duration: const Duration(milliseconds: 500),
            curve: Curves.easeOutCubic,
            builder: (context, valor, _) => LinearProgressIndicator(
              value: valor,
              minHeight: 10,
              backgroundColor: esquema.outlineVariant.withValues(alpha: 0.5),
              color: completo ? esquema.primary : esquema.secondary,
            ),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          subtitulo,
          style: textos.bodySmall?.copyWith(color: esquema.onSurfaceVariant),
        ),
      ],
    );
  }
}
