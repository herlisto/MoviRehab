import 'package:flutter/material.dart';

import '../l10n/app_localizations.dart';
import '../routes.dart';

class InicioScreen extends StatelessWidget {
  const InicioScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.homeTitle),
        actions: [
          IconButton(
            icon: const Icon(Icons.privacy_tip),
            tooltip: l10n.tooltipPrivacy,
            onPressed: () => Navigator.pushNamed(context, Rutas.privacidad),
          ),
          IconButton(
            icon: const Icon(Icons.settings),
            tooltip: l10n.tooltipSettings,
            onPressed: () => Navigator.pushNamed(context, Rutas.ajustes),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Card(
              color: Theme.of(context).colorScheme.primaryContainer,
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  children: [
                    const Icon(Icons.accessibility_new, size: 60),
                    const SizedBox(height: 10),
                    Text(
                      l10n.homeHeadline,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(l10n.welcomeMessage),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),
            ListTile(
              leading: const Icon(Icons.person),
              title: Text(l10n.menuProfile),
              onTap: () => Navigator.pushNamed(context, Rutas.perfil),
            ),
            ListTile(
              leading: const Icon(Icons.list),
              title: Text(l10n.menuPlan),
              onTap: () => Navigator.pushNamed(context, Rutas.plan),
            ),
            ListTile(
              leading: const Icon(Icons.camera_alt),
              title: Text(l10n.menuGuidedSession),
              onTap: () => Navigator.pushNamed(context, Rutas.sesionGuiada),
            ),
            ListTile(
              leading: const Icon(Icons.summarize),
              title: Text(l10n.menuSummary),
              onTap: () => Navigator.pushNamed(context, Rutas.resumen),
            ),
            ListTile(
              leading: const Icon(Icons.show_chart),
              title: Text(l10n.menuProgress),
              onTap: () => Navigator.pushNamed(context, Rutas.progreso),
            ),
            ListTile(
              leading: const Icon(Icons.history),
              title: Text(l10n.menuHistory),
              onTap: () => Navigator.pushNamed(context, Rutas.historial),
            ),
          ],
        ),
      ),
    );
  }
}
