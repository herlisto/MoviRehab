import 'package:flutter/foundation.dart'
    show TargetPlatform, debugPrint, defaultTargetPlatform, kIsWeb;
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:provider/provider.dart';

import '../controllers/ajustes_controller.dart';
import '../l10n/app_localizations.dart';
import '../routes.dart';
import '../services/fuente_movimiento.dart';
import '../widgets/pantalla_base.dart';
import '../widgets/tarjeta_estadistica.dart';

/// Ajustes de la aplicación: modo oscuro, idioma (español / inglés, se aplica
/// al instante), sensor de movimiento y estado real de los permisos de cámara
/// y micrófono (Android / iOS). En Windows y otras plataformas el sistema no
/// gestiona los permisos por app y se indica "No aplica".
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
    final ajustes = context.watch<AjustesController>();
    final sensorDisponible = context.read<FuenteMovimiento>().disponible;
    final esquema = Theme.of(context).colorScheme;

    final oscuro =
        ajustes.modoTema == ThemeMode.dark ||
        (ajustes.modoTema == ThemeMode.system &&
            MediaQuery.platformBrightnessOf(context) == Brightness.dark);
    final codigoIdioma =
        ajustes.idioma?.languageCode ??
        Localizations.localeOf(context).languageCode;

    return PantallaBase(
      titulo: l10n.settingsTitle,
      cuerpo: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TituloSeccion(texto: l10n.settingsAppearance),
            Card(
              child: SwitchListTile(
                secondary: Icon(oscuro ? Icons.dark_mode : Icons.light_mode),
                title: Text(l10n.settingsDarkMode),
                subtitle: Text(l10n.settingsDarkModeHelp),
                value: oscuro,
                onChanged: (valor) => ajustes.cambiarModoTema(
                  valor ? ThemeMode.dark : ThemeMode.light,
                ),
              ),
            ),
            TituloSeccion(texto: l10n.settingsLanguage),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      l10n.settingsLanguageHelp,
                      style: TextStyle(color: esquema.onSurfaceVariant),
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      child: SegmentedButton<String>(
                        showSelectedIcon: false,
                        segments: const [
                          ButtonSegment<String>(
                            value: 'es',
                            icon: Icon(Icons.translate),
                            label: Text('Español'),
                          ),
                          ButtonSegment<String>(
                            value: 'en',
                            icon: Icon(Icons.translate),
                            label: Text('English'),
                          ),
                        ],
                        selected: {codigoIdioma == 'en' ? 'en' : 'es'},
                        onSelectionChanged: (seleccion) =>
                            ajustes.cambiarIdioma(Locale(seleccion.first)),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            TituloSeccion(texto: l10n.settingsSensors),
            Card(
              child: ListTile(
                leading: const Icon(Icons.sensors),
                title: Text(l10n.settingsMotionSensor),
                subtitle: Text(
                  sensorDisponible
                      ? l10n.settingsMotionSensorAvailable
                      : l10n.settingsMotionSensorUnavailable,
                ),
                trailing: Icon(
                  sensorDisponible
                      ? Icons.check_circle
                      : Icons.remove_circle_outline,
                  color: sensorDisponible ? esquema.primary : null,
                ),
              ),
            ),
            TituloSeccion(texto: l10n.settingsPermissions),
            Card(
              child: Column(
                children: [
                  _permisoTile(
                    l10n,
                    l10n.permissionCamera,
                    _camara,
                    Permission.camera,
                  ),
                  const Divider(height: 1),
                  _permisoTile(
                    l10n,
                    l10n.permissionMicrophone,
                    _microfono,
                    Permission.microphone,
                  ),
                ],
              ),
            ),
            TituloSeccion(texto: l10n.settingsPrivacySection),
            Card(
              child: ListTile(
                leading: const Icon(Icons.shield_outlined),
                title: Text(l10n.privacyTitle),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => Navigator.pushNamed(context, Rutas.privacidad),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
