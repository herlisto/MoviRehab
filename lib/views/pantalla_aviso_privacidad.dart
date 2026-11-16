import 'package:flutter/material.dart';

import '../l10n/app_localizations.dart';
import '../widgets/pantalla_base.dart';

/// Aviso de privacidad: qué datos guarda MoviRehab, para qué, qué permisos usa
/// y qué control tiene la persona sobre ellos. Cada apartado se despliega.
class AvisoPrivacidadScreen extends StatelessWidget {
  const AvisoPrivacidadScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final esquema = Theme.of(context).colorScheme;

    final apartados = <_Apartado>[
      _Apartado(
        Icons.phone_android,
        l10n.privacyLocalTitle,
        l10n.privacyLocalBody,
      ),
      _Apartado(
        Icons.storage_outlined,
        l10n.privacyDataTitle,
        l10n.privacyDataBody,
      ),
      _Apartado(Icons.track_changes, l10n.privacyUseTitle, l10n.privacyUseBody),
      _Apartado(
        Icons.sensors,
        l10n.privacySensorsTitle,
        l10n.privacySensorsBody,
      ),
      _Apartado(
        Icons.share_outlined,
        l10n.privacySharingTitle,
        l10n.privacySharingBody,
      ),
      _Apartado(Icons.tune, l10n.privacyControlTitle, l10n.privacyControlBody),
      _Apartado(
        Icons.favorite_border,
        l10n.privacyHealthTitle,
        l10n.privacyHealthBody,
      ),
    ];

    return PantallaBase(
      titulo: l10n.privacyTitle,
      cuerpo: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(24),
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [esquema.primary, esquema.secondary],
                ),
              ),
              child: Row(
                children: [
                  Icon(Icons.shield, size: 44, color: esquema.onPrimary),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          l10n.privacyHeadline,
                          style: Theme.of(context).textTheme.titleMedium
                              ?.copyWith(
                                color: esquema.onPrimary,
                                fontWeight: FontWeight.w800,
                              ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          l10n.privacyBody,
                          style: TextStyle(
                            color: esquema.onPrimary.withValues(alpha: 0.92),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            for (final apartado in apartados)
              Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Card(
                  clipBehavior: Clip.antiAlias,
                  child: Theme(
                    data: Theme.of(context)
                        .copyWith(dividerColor: Colors.transparent),
                    child: ExpansionTile(
                      leading: Icon(apartado.icono, color: esquema.primary),
                      title: Text(
                        apartado.titulo,
                        style: const TextStyle(fontWeight: FontWeight.w700),
                      ),
                      childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                      expandedCrossAxisAlignment: CrossAxisAlignment.start,
                      children: [Text(apartado.texto)],
                    ),
                  ),
                ),
              ),
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text(
                l10n.privacyUpdated,
                textAlign: TextAlign.center,
                style: TextStyle(color: esquema.onSurfaceVariant, fontSize: 12),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Apartado {
  final IconData icono;
  final String titulo;
  final String texto;

  const _Apartado(this.icono, this.titulo, this.texto);
}
