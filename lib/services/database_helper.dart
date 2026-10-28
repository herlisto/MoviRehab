import 'dart:io';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import '../models/ejercicio_model.dart';
import '../models/medicion_model.dart';

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._init();
  static Database? _database;

  DatabaseHelper._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('movirehab.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    if (Platform.isWindows || Platform.isLinux) {
      sqfliteFfiInit();
      databaseFactory = databaseFactoryFfi;
    }

    final dbPath = await getApplicationDocumentsDirectory();
    final path = join(dbPath.path, filePath);

    return await openDatabase(
      path,
      version: 1,
      onConfigure: (db) async {
        await db.execute('PRAGMA foreign_keys = ON');
      },
      onCreate: _createDB,
      onUpgrade: (db, oldVersion, newVersion) async {},
    );
  }

  Future<void> _createDB(Database db, int version) async {
    await db.execute('''
      CREATE TABLE usuario (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        alias TEXT NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE ejercicio (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        nombre TEXT NOT NULL,
        articulacion TEXT NOT NULL,
        objetivo_grados INTEGER NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE sesion (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        usuario_id INTEGER NOT NULL,
        fecha TEXT NOT NULL,
        FOREIGN KEY (usuario_id) REFERENCES usuario (id) ON DELETE CASCADE
      )
    ''');

    await db.execute('''
      CREATE TABLE medicion (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        sesion_id INTEGER NOT NULL,
        ejercicio_id INTEGER NOT NULL,
        grados INTEGER NOT NULL,
        repeticiones INTEGER NOT NULL,
        FOREIGN KEY (sesion_id) REFERENCES sesion (id) ON DELETE CASCADE,
        FOREIGN KEY (ejercicio_id) REFERENCES ejercicio (id) ON DELETE CASCADE
      )
    ''');

    await db.insert('usuario', {'alias': 'Paciente_Principal'});

    final ejerciciosDemo = [
      {'nombre': 'Elevación lateral de hombro', 'articulacion': 'Hombro', 'objetivo_grados': 90},
      {'nombre': 'Flexión de codo', 'articulacion': 'Codo', 'objetivo_grados': 135},
      {'nombre': 'Rotación externa de hombro', 'articulacion': 'Hombro', 'objetivo_grados': 45},
      {'nombre': 'Extensión de rodilla', 'articulacion': 'Rodilla', 'objetivo_grados': 120},
      {'nombre': 'Flexión dorsal de tobillo', 'articulacion': 'Tobillo', 'objetivo_grados': 20},
      {'nombre': 'Circunducción de muñeca', 'articulacion': 'Muñeca', 'objetivo_grados': 60},
      {'nombre': 'Flexión de cadera', 'articulacion': 'Cadera', 'objetivo_grados': 90},
      {'nombre': 'Apertura pectoral', 'articulacion': 'Hombro', 'objetivo_grados': 110},
      {'nombre': 'Pronación de antebrazo', 'articulacion': 'Codo', 'objetivo_grados': 80},
      {'nombre': 'Inclinación lateral cervical', 'articulacion': 'Cervical', 'objetivo_grados': 45},
    ];

    for (var ej in ejerciciosDemo) {
      await db.insert('ejercicio', ej);
    }

    int sesionId = await db.insert('sesion', {
      'usuario_id': 1,
      'fecha': DateTime.now().toIso8601String().split('T')[0]
    });

    await db.insert('medicion', {
      'sesion_id': sesionId,
      'ejercicio_id': 1,
      'grados': 85,
      'repeticiones': 12
    });
  }

  Future<List<EjercicioModel>> obtenerEjercicios() async {
    final db = await database;
    final res = await db.query('ejercicio');
    return res.map((e) => EjercicioModel.fromMap(e)).toList();
  }

  Future<int> actualizarEjercicio(EjercicioModel ejercicio) async {
    final db = await database;
    return await db.update(
      'ejercicio',
      ejercicio.toMap(),
      where: 'id = ?',
      whereArgs: [ejercicio.id],
    );
  }

  Future<int> eliminarEjercicio(int id) async {
    final db = await database;
    return await db.delete('ejercicio', where: 'id = ?', whereArgs: [id]);
  }

  Future<int> crearSesion(int usuarioId) async {
    final db = await database;
    return await db.insert('sesion', {
      'usuario_id': usuarioId,
      'fecha': DateTime.now().toIso8601String().split('T')[0],
    });
  }

  Future<int> registrarMedicion(MedicionModel medicion) async {
    final db = await database;
    return await db.insert('medicion', medicion.toMap());
  }

  Future<List<Map<String, dynamic>>> obtenerEvolucionPromedio() async {
    final db = await database;
    return await db.rawQuery('''
      SELECT e.nombre, e.articulacion, AVG(m.grados) as promedio_grados, SUM(m.repeticiones) as total_reps
      FROM medicion m
      JOIN ejercicio e ON m.ejercicio_id = e.id
      GROUP BY e.id, e.nombre, e.articulacion
    ''');
  }

  Future<List<Map<String, dynamic>>> obtenerHistorialMediciones() async {
    final db = await database;
    return await db.rawQuery('''
      SELECT m.id, s.fecha, e.nombre as ejercicio, m.grados, m.repeticiones
      FROM medicion m
      JOIN sesion s ON m.sesion_id = s.id
      JOIN ejercicio e ON m.ejercicio_id = e.id
      ORDER BY s.fecha DESC
    ''');
  }
}