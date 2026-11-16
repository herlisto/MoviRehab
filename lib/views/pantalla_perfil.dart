import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../controllers/movirehab_controller.dart';
import '../l10n/app_localizations.dart';
import '../models/usuario_resumen_model.dart';
import '../routes.dart';
import '../widgets/mensaje_estado.dart';
import '../widgets/pantalla_base.dart';
import '../widgets/tarjeta_estadistica.dart';

/// Perfil del usuario activo y gestión de usuarios: crear, cambiar de usuario,
/// renombrar, borrar y ver los ejercicios que ha hecho cada uno.
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
      if (mounted) context.read<MoviRehabController>().cargarUsuarios();
    });
  }

  /// Texto de error para un resultado que no fue correcto.
  String _mensajeError(AppLocalizations l10n, ResultadoGuardado resultado) {
    switch (resultado) {
      case ResultadoGuardado.duplicado:
        return l10n.userDuplicate;
      case ResultadoGuardado.invalido:
        return l10n.userInvalid;
      case ResultadoGuardado.error:
      case ResultadoGuardado.ok:
        return l10n.errorSaving;
    }
  }

  Future<void> _nuevoUsuario() async {
    final controlador = context.read<MoviRehabController>();
    final l10n = AppLocalizations.of(context);
    final mensajes = ScaffoldMessenger.of(context);

    final creado = await showDialog<bool>(
      context: context,
      builder: (_) => _DialogoAlias(
        titulo: l10n.userNewTitle,
        textoBoton: l10n.userCreate,
        guardar: controlador.crearUsuario,
        mensajeError: (r) => _mensajeError(l10n, r),
      ),
    );
    if (creado == true) {
      mensajes.showSnackBar(SnackBar(content: Text(l10n.userCreated)));
    }
  }

  Future<void> _renombrar(UsuarioResumenModel item) async {
    final controlador = context.read<MoviRehabController>();
    final l10n = AppLocalizations.of(context);
    final id = item.usuario.id;
    if (id == null) return;

    await showDialog<bool>(
      context: context,
      builder: (_) => _DialogoAlias(
        titulo: l10n.userRenameTitle,
        textoBoton: l10n.save,
        inicial: item.usuario.alias.replaceAll('_', ' '),
        guardar: (alias) => controlador.renombrarUsuario(id, alias),
        mensajeError: (r) => _mensajeError(l10n, r),
      ),
    );
  }

  Future<void> _borrar(UsuarioResumenModel item) async {
    final controlador = context.read<MoviRehabController>();
    final l10n = AppLocalizations.of(context);
    final mensajes = ScaffoldMessenger.of(context);
    final id = item.usuario.id;
    if (id == null) return;

    final confirmado = await showDialog<bool>(
      context: context,
      builder: (contexto) => AlertDialog(
        title: Text(l10n.userDeleteTitle),
        content: Text(
          l10n.userDeleteBody(item.usuario.alias.replaceAll('_', ' ')),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(contexto, false),
            child: Text(l10n.cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(contexto, true),
            child: Text(l10n.delete),
          ),
        ],
      ),
    );
    if (confirmado != true) return;

    final borrado = await controlador.eliminarUsuario(id);
    mensajes.showSnackBar(
      SnackBar(content: Text(borrado ? l10n.userDeleted : l10n.errorSaving)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final controller = context.watch<MoviRehabController>();
    final usuarios = controller.usuarios;
    final activoId = controller.usuario?.id;

    Widget cuerpo;
    if (usuarios.isNotEmpty) {
      UsuarioResumenModel? activo;
      for (final item in usuarios) {
        if (item.usuario.id == activoId) activo = item;
      }
      cuerpo = ListView(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 96),
        children: [
          if (activo != null) _TarjetaActivo(item: activo),
          TituloSeccion(texto: l10n.usersTitle),
          for (final item in usuarios)
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: _TarjetaUsuario(
                item: item,
                activo: item.usuario.id == activoId,
                puedeBorrar: usuarios.length > 1,
                alSeleccionar: () {
                  final id = item.usuario.id;
                  if (id != null) controller.seleccionarUsuario(id);
                },
                alVerEjercicios: () => Navigator.pushNamed(
                  context,
                  Rutas.historial,
                  arguments: item.usuario.id,
                ),
                alRenombrar: () => _renombrar(item),
                alBorrar: () => _borrar(item),
              ),
            ),
        ],
      );
    } else if (controller.hayError) {
      cuerpo = MensajeEstado(
        icono: Icons.error_outline,
        mensaje: l10n.errorLoading,
        textoAccion: l10n.retry,
        onAccion: controller.cargarUsuarios,
      );
    } else {
      cuerpo = const Center(child: CircularProgressIndicator());
    }

    return PantallaBase(
      titulo: l10n.profileTitle,
      botonFlotante: FloatingActionButton.extended(
        onPressed: _nuevoUsuario,
        icon: const Icon(Icons.person_add_alt_1),
        label: Text(l10n.userNew),
      ),
      cuerpo: cuerpo,
    );
  }
}

String _inicial(String alias) {
  final limpio = alias.replaceAll('_', ' ').trim();
  if (limpio.isEmpty) return '?';
  return String.fromCharCode(limpio.runes.first).toUpperCase();
}

/// Tarjeta grande con el usuario activo (como el perfil original: nombre e ID).
class _TarjetaActivo extends StatelessWidget {
  final UsuarioResumenModel item;

  const _TarjetaActivo({required this.item});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final esquema = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(28),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [esquema.primary, esquema.secondary],
        ),
      ),
      child: Column(
        children: [
          CircleAvatar(
            radius: 40,
            backgroundColor: esquema.onPrimary.withValues(alpha: 0.2),
            child: Text(
              _inicial(item.usuario.alias),
              style: TextStyle(
                fontSize: 34,
                fontWeight: FontWeight.bold,
                color: esquema.onPrimary,
              ),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            // El alias se guarda como "Paciente_Principal": se muestra legible.
            item.usuario.alias.replaceAll('_', ' '),
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: esquema.onPrimary,
            ),
          ),
          Text(
            l10n.profileId(item.usuario.id ?? 0),
            style: TextStyle(color: esquema.onPrimary.withValues(alpha: 0.85)),
          ),
          const SizedBox(height: 4),
          Text(
            l10n.userActive,
            style: TextStyle(
              color: esquema.onPrimary,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _TarjetaUsuario extends StatelessWidget {
  final UsuarioResumenModel item;
  final bool activo;
  final bool puedeBorrar;
  final VoidCallback alSeleccionar;
  final VoidCallback alVerEjercicios;
  final VoidCallback alRenombrar;
  final VoidCallback alBorrar;

  const _TarjetaUsuario({
    required this.item,
    required this.activo,
    required this.puedeBorrar,
    required this.alSeleccionar,
    required this.alVerEjercicios,
    required this.alRenombrar,
    required this.alBorrar,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final esquema = Theme.of(context).colorScheme;
    final alias = item.usuario.alias.replaceAll('_', ' ');

    return Card(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(24),
        side: BorderSide(
          color: activo ? esquema.primary : esquema.outlineVariant,
          width: activo ? 2 : 1,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  backgroundColor: esquema.primaryContainer,
                  child: Text(
                    _inicial(item.usuario.alias),
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: esquema.onPrimaryContainer,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        alias,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(fontWeight: FontWeight.w700),
                      ),
                      Text(
                        '${l10n.userSessions(item.sesiones)} · '
                        '${l10n.userMeasurements(item.mediciones)}',
                        style: TextStyle(color: esquema.onSurfaceVariant),
                      ),
                    ],
                  ),
                ),
                if (activo)
                  Chip(
                    avatar: Icon(
                      Icons.check_circle,
                      size: 18,
                      color: esquema.primary,
                    ),
                    label: Text(l10n.userActive),
                  ),
                PopupMenuButton<String>(
                  tooltip: l10n.userMore,
                  onSelected: (valor) {
                    if (valor == 'renombrar') alRenombrar();
                    if (valor == 'borrar') alBorrar();
                  },
                  itemBuilder: (_) => [
                    PopupMenuItem(
                      value: 'renombrar',
                      child: Text(l10n.userRename),
                    ),
                    if (puedeBorrar)
                      PopupMenuItem(value: 'borrar', child: Text(l10n.delete)),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 4,
              children: [
                if (!activo)
                  FilledButton.tonal(
                    onPressed: alSeleccionar,
                    child: Text(l10n.userSelect),
                  ),
                OutlinedButton.icon(
                  onPressed: alVerEjercicios,
                  icon: const Icon(Icons.history),
                  label: Text(l10n.userSeeExercises),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// Diálogo para escribir el nombre de un usuario. Se mantiene abierto
/// mostrando el error si [guardar] no devuelve [ResultadoGuardado.ok].
class _DialogoAlias extends StatefulWidget {
  final String titulo;
  final String textoBoton;
  final String inicial;
  final Future<ResultadoGuardado> Function(String alias) guardar;
  final String Function(ResultadoGuardado resultado) mensajeError;

  const _DialogoAlias({
    required this.titulo,
    required this.textoBoton,
    required this.guardar,
    required this.mensajeError,
    this.inicial = '',
  });

  @override
  State<_DialogoAlias> createState() => _DialogoAliasState();
}

class _DialogoAliasState extends State<_DialogoAlias> {
  late final TextEditingController _texto = TextEditingController(
    text: widget.inicial,
  );
  String? _error;
  bool _guardando = false;

  @override
  void dispose() {
    _texto.dispose();
    super.dispose();
  }

  Future<void> _enviar() async {
    if (_guardando) return;
    setState(() {
      _guardando = true;
      _error = null;
    });
    final resultado = await widget.guardar(_texto.text);
    if (!mounted) return;
    if (resultado == ResultadoGuardado.ok) {
      Navigator.pop(context, true);
      return;
    }
    setState(() {
      _guardando = false;
      _error = widget.mensajeError(resultado);
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return AlertDialog(
      title: Text(widget.titulo),
      content: TextField(
        controller: _texto,
        autofocus: true,
        maxLength: MoviRehabController.maxLongitudAlias,
        textCapitalization: TextCapitalization.words,
        decoration: InputDecoration(
          labelText: l10n.userNameLabel,
          errorText: _error,
        ),
        onSubmitted: (_) => _enviar(),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: Text(l10n.cancel),
        ),
        FilledButton(
          onPressed: _guardando ? null : _enviar,
          child: Text(widget.textoBoton),
        ),
      ],
    );
  }
}
