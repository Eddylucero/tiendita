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

    return await db.insert(tableName, values);
  }

  // EDITAR PRODUCTO
  Future<int> edit(ProductModel data) async {
    if (data.productoId == null) {
      throw ArgumentError('El producto debe tener un ID para editarse.');
    }

    final db = await database.db;

    final values = data.toMap();
    values.remove('producto_id');

    return await db.update(
      tableName,
      values,
      where: 'producto_id = ?',
      whereArgs: [data.productoId],
    );
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
