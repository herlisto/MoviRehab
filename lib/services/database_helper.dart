import 'dart:io';

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import '../models/ejercicio_model.dart';
import '../models/evolucion_ejercicio_model.dart';
import '../models/medicion_historial_model.dart';
import '../models/medicion_model.dart';
import '../models/resumen_sesion_model.dart';
import '../models/usuario_model.dart';
import 'rehab_repository.dart';

/// Acceso a la base de datos SQLite local de MoviRehab.
///
/// * Android / iOS / macOS: motor nativo de `sqflite`.
/// * Windows / Linux: `sqflite_common_ffi`.
/// * Web: no soportado (la app lo avisa en `main.dart` y no llega a abrir la BD).
class DatabaseHelper implements RehabRepository {
  DatabaseHelper._();

  static final DatabaseHelper instance = DatabaseHelper._();

  static const String _nombreBD = 'movirehab.db';

  /// Versión del esquema. La v2 es el esquema actual de cuatro tablas.
  static const int _versionBD = 2;

  static const String _aliasPorDefecto = 'Paciente_Principal';

  static bool _motorConfigurado = false;

  /// Apertura en curso o ya completada. Se comparte entre todas las llamadas
  /// para no abrir la base de datos dos veces si se piden a la vez.
  Future<Database>? _apertura;

  Future<Database> get database async {
    final apertura = _apertura ??= _abrirBD();
    try {
      return await apertura;
    } catch (_) {
      // Permite reintentar si la apertura falló.
      _apertura = null;
      rethrow;
    }
  }

  static void _configurarMotor() {
    if (_motorConfigurado) return;
    if (!kIsWeb && (Platform.isWindows || Platform.isLinux)) {
      sqfliteFfiInit();
      databaseFactory = databaseFactoryFfi;
    }
    _motorConfigurado = true;
  }

  Future<Database> _abrirBD() async {
    _configurarMotor();

    final carpeta = await getApplicationDocumentsDirectory();
    final ruta = p.join(carpeta.path, _nombreBD);

    return openDatabase(
      ruta,
      version: _versionBD,
      onConfigure: (db) async {
        await db.execute('PRAGMA foreign_keys = ON');
      },
      onCreate: (db, version) async {
        await _crearTablas(db);
        await _sembrarDatosDemo(db);
      },
      onUpgrade: (db, oldVersion, newVersion) async {
        // Una BD anterior a la v2 tiene un esquema desconocido: se reconstruye.
        // (Antes se llamaba a _createDB sin borrar nada y fallaba con
        // "table usuario already exists".)
        if (oldVersion < 2) {
          await _eliminarTablas(db);
          await _crearTablas(db);
          await _sembrarDatosDemo(db);
        }
      },
    );
  }

  // ---------------------------------------------------------------------------
  // Esquema
  // ---------------------------------------------------------------------------

  static const String _sqlCrearUsuario = '''
    CREATE TABLE usuario (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      alias TEXT NOT NULL
    )
  ''';

  static const String _sqlCrearEjercicio = '''
    CREATE TABLE ejercicio (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      nombre TEXT NOT NULL,
      articulacion TEXT NOT NULL,
      objetivo_grados INTEGER NOT NULL
    )
  ''';

  static const String _sqlCrearSesion = '''
    CREATE TABLE sesion (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      usuario_id INTEGER NOT NULL,
      fecha TEXT NOT NULL,
      FOREIGN KEY (usuario_id) REFERENCES usuario (id) ON DELETE CASCADE
    )
  ''';

  static const String _sqlCrearMedicion = '''
    CREATE TABLE medicion (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      sesion_id INTEGER NOT NULL,
      ejercicio_id INTEGER NOT NULL,
      grados INTEGER NOT NULL,
      repeticiones INTEGER NOT NULL,
      FOREIGN KEY (sesion_id) REFERENCES sesion (id) ON DELETE CASCADE,
      FOREIGN KEY (ejercicio_id) REFERENCES ejercicio (id) ON DELETE CASCADE
    )
  ''';

  Future<void> _crearTablas(Database db) async {
    await db.execute(_sqlCrearUsuario);
    await db.execute(_sqlCrearEjercicio);
    await db.execute(_sqlCrearSesion);
    await db.execute(_sqlCrearMedicion);
  }

  /// Borra en orden hijo -> padre para respetar las claves foráneas.
  Future<void> _eliminarTablas(Database db) async {
    await db.execute('DROP TABLE IF EXISTS medicion');
    await db.execute('DROP TABLE IF EXISTS sesion');
    await db.execute('DROP TABLE IF EXISTS ejercicio');
    await db.execute('DROP TABLE IF EXISTS usuario');
  }

  static const List<EjercicioModel> _ejerciciosDemo = [
    EjercicioModel(
      nombre: 'Elevación lateral de hombro',
      articulacion: 'Hombro',
      objetivoGrados: 90,
    ),
    EjercicioModel(
      nombre: 'Flexión de codo',
      articulacion: 'Codo',
      objetivoGrados: 135,
    ),
    EjercicioModel(
      nombre: 'Rotación externa de hombro',
      articulacion: 'Hombro',
      objetivoGrados: 45,
    ),
    EjercicioModel(
      nombre: 'Extensión de rodilla',
      articulacion: 'Rodilla',
      objetivoGrados: 120,
    ),
    EjercicioModel(
      nombre: 'Flexión dorsal de tobillo',
      articulacion: 'Tobillo',
      objetivoGrados: 20,
    ),
    EjercicioModel(
      nombre: 'Circunducción de muñeca',
      articulacion: 'Muñeca',
      objetivoGrados: 60,
    ),
    EjercicioModel(
      nombre: 'Flexión de cadera',
      articulacion: 'Cadera',
      objetivoGrados: 90,
    ),
    EjercicioModel(
      nombre: 'Apertura pectoral',
      articulacion: 'Hombro',
      objetivoGrados: 110,
    ),
    EjercicioModel(
      nombre: 'Pronación de antebrazo',
      articulacion: 'Codo',
      objetivoGrados: 80,
    ),
    EjercicioModel(
      nombre: 'Inclinación lateral cervical',
      articulacion: 'Cervical',
      objetivoGrados: 45,
    ),
  ];

  /// Datos de demostración: un usuario, el plan de 10 ejercicios y una
  /// medición de ejemplo (para que Progreso e Historial no salgan vacíos).
  Future<void> _sembrarDatosDemo(Database db) async {
    final usuarioId = await db.insert('usuario', {'alias': _aliasPorDefecto});

    int? primerEjercicioId;
    for (final ejercicio in _ejerciciosDemo) {
      final id = await db.insert('ejercicio', ejercicio.toMap());
      primerEjercicioId ??= id;
    }

    final sesionId = await db.insert('sesion', {
      'usuario_id': usuarioId,
      'fecha': fechaHoy(),
    });

    await db.insert('medicion', {
      'sesion_id': sesionId,
      'ejercicio_id': primerEjercicioId,
      'grados': 85,
      'repeticiones': 12,
    });
  }

  /// Fecha local de hoy con formato `AAAA-MM-DD`.
  static String fechaHoy() {
    return DateTime.now().toIso8601String().split('T').first;
  }

  // ---------------------------------------------------------------------------
  // Consultas
  // ---------------------------------------------------------------------------

  static const String _sqlEvolucion = '''
    SELECT e.nombre AS nombre,
           e.articulacion AS articulacion,
           AVG(m.grados) AS promedio_grados,
           SUM(m.repeticiones) AS total_reps
    FROM medicion m
    JOIN ejercicio e ON m.ejercicio_id = e.id
    GROUP BY e.id, e.nombre, e.articulacion
    ORDER BY e.id
  ''';

  static const String _sqlHistorial = '''
    SELECT m.id AS id,
           s.fecha AS fecha,
           e.nombre AS ejercicio,
           m.grados AS grados,
           m.repeticiones AS repeticiones
    FROM medicion m
    JOIN sesion s ON m.sesion_id = s.id
    JOIN ejercicio e ON m.ejercicio_id = e.id
    ORDER BY s.fecha DESC, m.id DESC
  ''';

  static const String _sqlResumenSesion = '''
    SELECT s.id AS sesion_id,
           s.fecha AS fecha,
           COUNT(DISTINCT m.ejercicio_id) AS total_ejercicios,
           COALESCE(AVG(m.grados), 0) AS promedio_grados
    FROM sesion s
    LEFT JOIN medicion m ON m.sesion_id = s.id
    WHERE s.id = ?
    GROUP BY s.id, s.fecha
  ''';

  static const String _sqlUltimoResumen = '''
    SELECT s.id AS sesion_id,
           s.fecha AS fecha,
           COUNT(DISTINCT m.ejercicio_id) AS total_ejercicios,
           AVG(m.grados) AS promedio_grados
    FROM sesion s
    JOIN medicion m ON m.sesion_id = s.id
    GROUP BY s.id, s.fecha
    ORDER BY s.fecha DESC, s.id DESC
    LIMIT 1
  ''';

  @override
  Future<UsuarioModel> obtenerUsuarioPrincipal() async {
    final db = await database;
    final filas = await db.query('usuario', orderBy: 'id ASC', limit: 1);
    if (filas.isNotEmpty) return UsuarioModel.fromMap(filas.first);

    final id = await db.insert('usuario', {'alias': _aliasPorDefecto});
    return UsuarioModel(id: id, alias: _aliasPorDefecto);
  }

  @override
  Future<List<EjercicioModel>> obtenerEjercicios() async {
    final db = await database;
    final filas = await db.query('ejercicio', orderBy: 'id ASC');
    return filas.map(EjercicioModel.fromMap).toList();
  }

  @override
  Future<int> actualizarEjercicio(EjercicioModel ejercicio) async {
    final db = await database;
    return db.update(
      'ejercicio',
      ejercicio.toMap(),
      where: 'id = ?',
      whereArgs: [ejercicio.id],
    );
  }

  @override
  Future<int> eliminarEjercicio(int id) async {
    final db = await database;
    return db.delete('ejercicio', where: 'id = ?', whereArgs: [id]);
  }

  @override
  Future<int> crearSesion(int usuarioId) async {
    final db = await database;
    return db.insert('sesion', {'usuario_id': usuarioId, 'fecha': fechaHoy()});
  }

  @override
  Future<int> registrarMedicion(MedicionModel medicion) async {
    final db = await database;
    return db.insert('medicion', medicion.toMap());
  }

  @override
  Future<List<EvolucionEjercicioModel>> obtenerEvolucionPromedio() async {
    final db = await database;
    final filas = await db.rawQuery(_sqlEvolucion);
    return filas.map(EvolucionEjercicioModel.fromMap).toList();
  }

  @override
  Future<List<MedicionHistorialModel>> obtenerHistorialMediciones() async {
    final db = await database;
    final filas = await db.rawQuery(_sqlHistorial);
    return filas.map(MedicionHistorialModel.fromMap).toList();
  }

  @override
  Future<ResumenSesionModel?> obtenerResumenSesion(int sesionId) async {
    final db = await database;
    final filas = await db.rawQuery(_sqlResumenSesion, [sesionId]);
    if (filas.isEmpty) return null;
    return ResumenSesionModel.fromMap(filas.first);
  }

  @override
  Future<ResumenSesionModel?> obtenerUltimoResumen() async {
    final db = await database;
    final filas = await db.rawQuery(_sqlUltimoResumen);
    if (filas.isEmpty) return null;
    return ResumenSesionModel.fromMap(filas.first);
  }
}
