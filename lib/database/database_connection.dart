import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class DatabaseConnection {
  static final DatabaseConnection instance = DatabaseConnection._internal();

  factory DatabaseConnection() => instance;

  DatabaseConnection._internal();

  static Database? _database;

  Future<Database> get db async {
    _database ??= await inicializarDb();
    return _database!;
  }

  Future<Database> inicializarDb() async {
    final rutaDb = await getDatabasesPath();
    final rutaFinal = join(rutaDb, 'contabilidad_tienda.db');

    return openDatabase(
      rutaFinal,
      version: 3,
      onConfigure: (db) async {
        await db.execute('PRAGMA foreign_keys = ON');
      },
      onCreate: (db, version) async {
        // PRODUCTOS
        await db.execute('''
          CREATE TABLE productos (
            producto_id INTEGER PRIMARY KEY AUTOINCREMENT,
            nombre TEXT NOT NULL,
            imagen_path TEXT,
            precio_compra REAL NOT NULL DEFAULT 0,
            precio_venta REAL NOT NULL DEFAULT 0,
            tarifa_iva REAL NOT NULL DEFAULT 0
          )
        ''');

        // PERIODOS CONTABLES
        await db.execute('''
          CREATE TABLE periodos (
            periodo_id INTEGER PRIMARY KEY AUTOINCREMENT,
            mes INTEGER NOT NULL CHECK(mes BETWEEN 1 AND 12),
            anio INTEGER NOT NULL,
            estado TEXT NOT NULL DEFAULT 'abierto',
            UNIQUE(mes, anio)
          )
        ''');

        // INVENTARIO MENSUAL
        await db.execute('''
          CREATE TABLE inventario_mensual (
            inventario_id INTEGER PRIMARY KEY AUTOINCREMENT,
            producto_id INTEGER NOT NULL,
            periodo_id INTEGER NOT NULL,
            cantidad_inicial INTEGER NOT NULL DEFAULT 0,
            cantidad_comprada INTEGER NOT NULL DEFAULT 0,
            cantidad_restante INTEGER NOT NULL DEFAULT 0,
            precio_compra REAL NOT NULL,
            precio_venta REAL NOT NULL,

            UNIQUE(producto_id, periodo_id),

            FOREIGN KEY (producto_id)
              REFERENCES productos(producto_id)
              ON DELETE RESTRICT,

            FOREIGN KEY (periodo_id)
              REFERENCES periodos(periodo_id)
              ON DELETE CASCADE
          )
        ''');

        // OTROS MOVIMIENTOS CONTABLES
        await db.execute('''
          CREATE TABLE movimientos (
            movimiento_id INTEGER PRIMARY KEY AUTOINCREMENT,
            periodo_id INTEGER NOT NULL,
            tipo TEXT NOT NULL
              CHECK(tipo IN ('ingreso', 'gasto')),
            concepto TEXT NOT NULL,
            monto REAL NOT NULL CHECK(monto >= 0),
            fecha TEXT NOT NULL,

            FOREIGN KEY (periodo_id)
              REFERENCES periodos(periodo_id)
              ON DELETE CASCADE
          )
        ''');
      },
      onUpgrade: (db, oldVersion, newVersion) async {
        if (oldVersion < 3) {
          // Agregar columna tarifa_iva a la tabla productos
          await db.execute('''
            ALTER TABLE productos
            ADD COLUMN tarifa_iva REAL NOT NULL DEFAULT 0
          ''');
        }
      },
    );
  }
}
