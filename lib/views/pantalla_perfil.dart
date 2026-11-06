import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../controllers/movirehab_controller.dart';
import '../l10n/app_localizations.dart';
import '../widgets/mensaje_estado.dart';

class PerfilScreen extends StatefulWidget {
  const PerfilScreen({super.key});

  @override
  State<PerfilScreen> createState() => _PerfilScreenState();
}

class _PerfilScreenState extends State<PerfilScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) context.read<MoviRehabController>().cargarUsuario();
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final controller = context.watch<MoviRehabController>();
    final usuario = controller.usuario;
    final esquema = Theme.of(context).colorScheme;

    Widget cuerpo;
    if (usuario != null) {
      cuerpo = Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            const CircleAvatar(radius: 40, child: Icon(Icons.person, size: 40)),
            const SizedBox(height: 12),
            Text(
              // El alias se guarda como "Paciente_Principal": se muestra legible.
              usuario.alias.replaceAll('_', ' '),
              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            Text(
              l10n.profileId(usuario.id ?? 0),
              style: TextStyle(color: esquema.onSurfaceVariant),
            ),
          ],
        ),
      );
    } else if (controller.hayError) {
      cuerpo = MensajeEstado(
        icono: Icons.error_outline,
        mensaje: l10n.errorLoading,
        textoAccion: l10n.retry,
        onAccion: controller.cargarUsuario,
      );
    } else {
      cuerpo = const Center(child: CircularProgressIndicator());
    }

    return Scaffold(
      appBar: AppBar(title: Text(l10n.profileTitle)),
      body: cuerpo,
    );
  }
}
