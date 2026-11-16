import '../l10n/app_localizations.dart';

/// Articulaciones que se pueden elegir al crear un ejercicio. Son los valores
/// que se guardan en la base de datos (en español, como los 10 ejercicios
/// preestablecidos); en pantalla se traducen con [nombreArticulacion].
const List<String> articulacionesDisponibles = [
  'Hombro',
  'Codo',
  'Muñeca',
  'Cadera',
  'Rodilla',
  'Tobillo',
  'Cervical',
  'Otra',
];

/// Nombre de la articulación en el idioma activo. Si no es una de las
/// conocidas, se devuelve tal cual.
String nombreArticulacion(AppLocalizations l10n, String articulacion) {
  switch (articulacion) {
    case 'Hombro':
      return l10n.jointShoulder;
    case 'Codo':
      return l10n.jointElbow;
    case 'Muñeca':
      return l10n.jointWrist;
    case 'Cadera':
      return l10n.jointHip;
    case 'Rodilla':
      return l10n.jointKnee;
    case 'Tobillo':
      return l10n.jointAnkle;
    case 'Cervical':
      return l10n.jointNeck;
    case 'Otra':
      return l10n.jointOther;
  }
  return articulacion;
}

/// Nombre del ejercicio en el idioma activo. Solo se traducen los
/// preestablecidos; los creados por el usuario se muestran como se escribieron.
String nombreEjercicio(AppLocalizations l10n, String nombre) {
  return _preestablecidos(l10n)[nombre] ?? nombre;
}

Map<String, String> _preestablecidos(AppLocalizations l10n) => {
  'Elevación lateral de hombro': l10n.exShoulderLateralRaise,
  'Flexión de codo': l10n.exElbowFlexion,
  'Rotación externa de hombro': l10n.exShoulderExternalRotation,
  'Extensión de rodilla': l10n.exKneeExtension,
  'Flexión dorsal de tobillo': l10n.exAnkleDorsiflexion,
  'Circunducción de muñeca': l10n.exWristCircumduction,
  'Flexión de cadera': l10n.exHipFlexion,
  'Apertura pectoral': l10n.exChestOpening,
  'Pronación de antebrazo': l10n.exForearmPronation,
  'Inclinación lateral cervical': l10n.exNeckLateralTilt,
};
