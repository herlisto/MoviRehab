import 'package:flutter/widgets.dart';
import 'package:intl/intl.dart';

/// Formatea [valor] con [decimales] decimales según el idioma activo
/// (`85,0` en español, `85.0` en inglés).
String formatearDecimal(BuildContext context, num valor, {int decimales = 1}) {
  final idioma = Localizations.localeOf(context).toString();
  return NumberFormat.decimalPatternDigits(
    locale: idioma,
    decimalDigits: decimales,
  ).format(valor);
}
