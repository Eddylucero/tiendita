import '../database/database_connection.dart';
import '../models/product_model.dart';

class ProductRepository {
  final String tableName = 'productos';

  final DatabaseConnection database = DatabaseConnection.instance;

  // INSERTAR PRODUCTO
  Future<int> create(ProductModel data) async {
    final db = await database.db;

    final values = data.toMap();
    values.remove('producto_id');

    return db.transaction((txn) async {
      final id = await txn.insert(tableName, values);
      final periods = await txn.query('periodos',
          columns: ['periodo_id'], orderBy: 'anio DESC, mes DESC', limit: 1);
      if (periods.isNotEmpty) {
        await txn.insert('inventario_mensual', {
          'producto_id': id,
          'periodo_id': periods.first['periodo_id'],
          'cantidad_inicial': data.cantidadInicial,
          'cantidad_comprada': 0,
          'cantidad_restante': data.cantidadInicial,
          'precio_compra': data.precioCompra,
          'precio_venta': data.precioVenta,
        });
      }
      return id;
    });
  }

  // EDITAR PRODUCTO
  Future<int> edit(ProductModel data) async {
    if (data.productoId == null) {
      throw ArgumentError('El producto debe tener un ID para editarse.');
    }

    final db = await database.db;

    final values = data.toMap();
    values.remove('producto_id');

    return db.transaction((txn) async {
      final updated = await txn.update(
        tableName,
        values,
        where: 'producto_id = ?',
        whereArgs: [data.productoId],
      );
      if (updated == 0) return 0;

      final periods = await txn.query('periodos',
          columns: ['periodo_id'], orderBy: 'anio DESC, mes DESC', limit: 1);
      if (periods.isNotEmpty) {
        final periodId = periods.first['periodo_id'] as int;
        final inventory = await txn.query('inventario_mensual',
          where: 'producto_id = ? AND periodo_id = ?',
          whereArgs: [data.productoId, periodId], limit: 1);
        if (inventory.isEmpty) {
          await txn.insert('inventario_mensual', {
            'producto_id': data.productoId,
            'periodo_id': periodId,
            'cantidad_inicial': data.cantidadInicial,
            'cantidad_comprada': 0,
            'cantidad_restante': data.cantidadInicial,
            'precio_compra': data.precioCompra,
            'precio_venta': data.precioVenta,
          });
        } else {
          final row = inventory.first;
          final oldInitial = (row['cantidad_inicial'] as num).toInt();
          if (oldInitial != data.cantidadInicial) {
            final newRemaining = (row['cantidad_restante'] as num).toInt()
                + data.cantidadInicial - oldInitial;
            if (newRemaining < 0) {
              throw StateError('La cantidad inicial no puede ser menor que lo ya vendido.');
            }
            await txn.update('inventario_mensual', {
              'cantidad_inicial': data.cantidadInicial,
              'cantidad_restante': newRemaining,
            }, where: 'inventario_id = ?', whereArgs: [row['inventario_id']]);
          }
        }
      }
      return updated;
    });
  }

  // ELIMINAR PRODUCTO
  Future<int> delete(int productoId) async {
    final db = await database.db;

    return await db.delete(
      tableName,
      where: 'producto_id = ?',
      whereArgs: [productoId],
    );
  }

  // LISTAR TODOS LOS PRODUCTOS
  Future<List<ProductModel>> getAll() async {
    final db = await database.db;

    final response = await db.query(
      tableName,
      orderBy: 'nombre COLLATE NOCASE ASC',
    );

    return response.map((e) => ProductModel.fromMap(e)).toList();
  }

  // OBTENER PRODUCTO POR ID
  Future<ProductModel?> getById(int productoId) async {
    final db = await database.db;

    final response = await db.query(
      tableName,
      where: 'producto_id = ?',
      whereArgs: [productoId],
      limit: 1,
    );

    if (response.isEmpty) return null;

    return ProductModel.fromMap(response.first);
  }

  Future<int> getAvailableQuantity(ProductModel product) async {
    if (product.productoId == null) return product.cantidadInicial;
    final db = await database.db;
    final rows = await db.rawQuery('''
      SELECT inventario_mensual.cantidad_restante
      FROM inventario_mensual
      INNER JOIN periodos
        ON periodos.periodo_id = inventario_mensual.periodo_id
      WHERE inventario_mensual.producto_id = ?
      ORDER BY periodos.anio DESC, periodos.mes DESC
      LIMIT 1
    ''', [product.productoId]);
    return rows.isEmpty
        ? product.cantidadInicial
        : (rows.first['cantidad_restante'] as num).toInt();
  }

  // BUSCAR PRODUCTOS
  Future<List<ProductModel>> search(String nombre) async {
    final db = await database.db;

    final response = await db.query(
      tableName,
      where: 'nombre LIKE ?',
      whereArgs: ['%$nombre%'],
      orderBy: 'nombre COLLATE NOCASE ASC',
    );

    return response.map((e) => ProductModel.fromMap(e)).toList();
  }

  // VERIFICAR NOMBRE DUPLICADO
  Future<bool> nombreUnico(String nombre, {int? productoId}) async {
    final db = await database.db;

    final response = await db.query(
      tableName,
      columns: ['producto_id'],
      where: productoId == null
          ? 'LOWER(nombre) = LOWER(?)'
          : 'LOWER(nombre) = LOWER(?) AND producto_id != ?',
      whereArgs: productoId == null
          ? [nombre.trim()]
          : [nombre.trim(), productoId],
      limit: 1,
    );

    return response.isEmpty;
  }
}
