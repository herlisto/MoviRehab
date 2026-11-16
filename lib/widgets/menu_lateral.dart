import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../controllers/movirehab_controller.dart';
import '../l10n/app_localizations.dart';
import '../routes.dart';

/// Menú desplegable (cajón lateral) de la pantalla de inicio con todas las
/// opciones de la aplicación.
class MenuLateral extends StatelessWidget {
  /// Se llama con el nombre de la ruta elegida. El cajón ya se ha cerrado.
  final ValueChanged<String> alElegir;

  const MenuLateral({super.key, required this.alElegir});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final esquema = Theme.of(context).colorScheme;
    final usuario = context.watch<MoviRehabController>().usuario;

    Widget opcion(IconData icono, String texto, String ruta) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
        child: ListTile(
          leading: Icon(icono),
          title: Text(texto),
          onTap: () {
            Navigator.pop(context);
            alElegir(ruta);
          },
        ),
      );
    }

    return Drawer(
      child: SafeArea(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            Container(
              margin: const EdgeInsets.all(12),
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(24),
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [esquema.primary, esquema.secondary],
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.eco, size: 36, color: esquema.onPrimary),
                  const SizedBox(height: 10),
                  Text(
                    l10n.appTitle,
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      color: esquema.onPrimary,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  if (usuario != null)
                    Text(
                      usuario.alias.replaceAll('_', ' '),
                      style: TextStyle(
                        color: esquema.onPrimary.withValues(alpha: 0.9),
                      ),
                    ),
                ],
              ),
            ),
            opcion(Icons.person_outline, l10n.menuProfile, Rutas.perfil),
            opcion(Icons.list_alt, l10n.menuPlan, Rutas.plan),
            opcion(
              Icons.play_circle_outline,
              l10n.menuGuidedSession,
              Rutas.sesionGuiada,
            ),
            opcion(Icons.summarize_outlined, l10n.menuSummary, Rutas.resumen),
            opcion(Icons.insights, l10n.menuProgress, Rutas.progreso),
            opcion(Icons.history, l10n.menuHistory, Rutas.historial),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 24, vertical: 8),
              child: Divider(),
            ),
            opcion(Icons.settings_outlined, l10n.menuSettings, Rutas.ajustes),
            opcion(Icons.shield_outlined, l10n.menuPrivacy, Rutas.privacidad),
          ],
        ),
      ),
    );
  }
}
