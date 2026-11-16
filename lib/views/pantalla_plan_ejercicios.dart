import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../controllers/movirehab_controller.dart';
import '../l10n/app_localizations.dart';
import '../routes.dart';
import '../utils/nombres.dart';
import '../widgets/mensaje_estado.dart';
import '../widgets/pantalla_base.dart';

class PlanEjerciciosScreen extends StatefulWidget {
  const PlanEjerciciosScreen({super.key});

  @override
  State<PlanEjerciciosScreen> createState() => _PlanEjerciciosScreenState();
}

class _PlanEjerciciosScreenState extends State<PlanEjerciciosScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) context.read<MoviRehabController>().cargarEjercicios();
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final controller = context.watch<MoviRehabController>();
    final ejercicios = controller.ejercicios;
    final esquema = Theme.of(context).colorScheme;

    Widget cuerpo;
    if (ejercicios.isNotEmpty) {
      cuerpo = ListView.separated(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 96),
        itemCount: ejercicios.length,
        separatorBuilder: (_, _) => const SizedBox(height: 10),
        itemBuilder: (context, index) {
          final ej = ejercicios[index];
          final propio = ej.personalizado;
          return Card(
            clipBehavior: Clip.antiAlias,
            child: InkWell(
              onTap: () => Navigator.pushNamed(
                context,
                Rutas.detalleEjercicio,
                arguments: ej,
              ),
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Row(
                  children: [
                    CircleAvatar(
                      backgroundColor: propio
                          ? esquema.tertiaryContainer
                          : esquema.primaryContainer,
                      foregroundColor: propio
                          ? esquema.onTertiaryContainer
                          : esquema.onPrimaryContainer,
                      child: Icon(
                        propio ? Icons.auto_awesome : Icons.self_improvement,
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            nombreEjercicio(l10n, ej.nombre),
                            style: Theme.of(context).textTheme.titleMedium
                                ?.copyWith(fontWeight: FontWeight.w700),
                          ),
                          Text(
                            l10n.planJoint(
                              nombreArticulacion(l10n, ej.articulacion),
                            ),
                            style: TextStyle(color: esquema.onSurfaceVariant),
                          ),
                          if (propio)
                            Padding(
                              padding: const EdgeInsets.only(top: 4),
                              child: Text(
                                l10n.planCustomBadge,
                                style: TextStyle(
                                  color: esquema.tertiary,
                                  fontWeight: FontWeight.w700,
                                  fontSize: 12,
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: esquema.secondaryContainer,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        '${ej.objetivoGrados}°',
                        style: TextStyle(
                          fontWeight: FontWeight.w800,
                          color: esquema.onSecondaryContainer,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      );
    } else if (controller.isLoading) {
      cuerpo = const Center(child: CircularProgressIndicator());
    } else if (controller.hayError) {
      cuerpo = MensajeEstado(
        icono: Icons.error_outline,
        mensaje: l10n.errorLoading,
        textoAccion: l10n.retry,
        onAccion: controller.cargarEjercicios,
      );
    } else {
      cuerpo = MensajeEstado(
        icono: Icons.inbox_outlined,
        mensaje: l10n.planEmpty,
      );
    }

    return PantallaBase(
      titulo: l10n.planTitle,
      botonFlotante: FloatingActionButton.extended(
        onPressed: () => Navigator.pushNamed(context, Rutas.nuevoEjercicio),
        icon: const Icon(Icons.add),
        label: Text(l10n.exerciseNew),
      ),
      cuerpo: cuerpo,
    );
  }
}
