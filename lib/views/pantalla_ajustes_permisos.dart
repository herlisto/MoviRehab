import 'package:flutter/foundation.dart'
    show TargetPlatform, debugPrint, defaultTargetPlatform, kIsWeb;
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';

import '../l10n/app_localizations.dart';

/// Estado real de los permisos de cámara y micrófono (Android / iOS).
/// En Windows y otras plataformas el sistema no los gestiona por app y se
/// indica "No aplica".
class AjustesPermisosScreen extends StatefulWidget {
  const AjustesPermisosScreen({super.key});

  @override
  State<AjustesPermisosScreen> createState() => _AjustesPermisosScreenState();
}

class _AjustesPermisosScreenState extends State<AjustesPermisosScreen>
    with WidgetsBindingObserver {
  PermissionStatus? _camara;
  PermissionStatus? _microfono;

  bool get _soportado =>
      !kIsWeb &&
      (defaultTargetPlatform == TargetPlatform.android ||
          defaultTargetPlatform == TargetPlatform.iOS);

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _refrescar();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  /// Al volver de los ajustes del sistema se relee el estado.
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) _refrescar();
  }

  Future<void> _refrescar() async {
    if (!_soportado) return;
    try {
      final camara = await Permission.camera.status;
      final microfono = await Permission.microphone.status;
      if (!mounted) return;
      setState(() {
        _camara = camara;
        _microfono = microfono;
      });
    } catch (e) {
      debugPrint('MoviRehab: no se pudo leer el estado de los permisos: $e');
    }
  }

  Future<void> _solicitar(Permission permiso) async {
    try {
      await permiso.request();
    } catch (e) {
      debugPrint('MoviRehab: no se pudo solicitar el permiso: $e');
    }
    await _refrescar();
  }

  Widget _permisoTile(
    AppLocalizations l10n,
    String titulo,
    PermissionStatus? estado,
    Permission permiso,
  ) {
    final esquema = Theme.of(context).colorScheme;

    if (!_soportado) {
      return ListTile(
        title: Text(titulo),
        subtitle: Text(l10n.permissionNotApplicable),
        trailing: const Icon(Icons.remove_circle_outline),
      );
    }
    if (estado == null) {
      return ListTile(
        title: Text(titulo),
        trailing: const SizedBox(
          width: 24,
          height: 24,
          child: CircularProgressIndicator(strokeWidth: 2),
        ),
      );
    }
    if (estado.isGranted) {
      return ListTile(
        title: Text(titulo),
        subtitle: Text(l10n.permissionGranted),
        trailing: Icon(Icons.check_circle, color: esquema.primary),
      );
    }
    if (estado.isRestricted) {
      return ListTile(
        title: Text(titulo),
        subtitle: Text(l10n.permissionRestricted),
        trailing: const Icon(Icons.block),
      );
    }
    if (estado.isPermanentlyDenied) {
      return ListTile(
        title: Text(titulo),
        subtitle: Text(l10n.permissionPermanentlyDenied),
        trailing: TextButton(
          onPressed: openAppSettings,
          child: Text(l10n.permissionOpenSettings),
        ),
      );
    }
    return ListTile(
      title: Text(titulo),
      subtitle: Text(l10n.permissionDenied),
      trailing: TextButton(
        onPressed: () => _solicitar(permiso),
        child: Text(l10n.permissionRequest),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return Scaffold(
      appBar: AppBar(title: Text(l10n.settingsTitle)),
      body: ListView(
        children: [
          _permisoTile(l10n, l10n.permissionCamera, _camara, Permission.camera),
          _permisoTile(
            l10n,
            l10n.permissionMicrophone,
            _microfono,
            Permission.microphone,
          ),
        ],
      ),
    );
  }
}
