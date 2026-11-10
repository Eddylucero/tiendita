import '../database/database_connection.dart';
import '../models/accounting_period_model.dart';
import '../models/monthly_inventory_model.dart';

class AccountingRepository {
  final DatabaseConnection database = DatabaseConnection.instance;

  Future<List<AccountingPeriodModel>> getPeriods() async {
    final db = await database.db;
    final rows = await db.query('periodos', orderBy: 'anio DESC, mes DESC');
    return rows.map(AccountingPeriodModel.fromMap).toList();
  }

  Future<bool> periodExists(int mes, int anio) async {
    final db = await database.db;
    final rows = await db.query(
      'periodos',
      columns: ['periodo_id'],
      where: 'mes = ? AND anio = ?',
      whereArgs: [mes, anio],
      limit: 1,
    );
    return rows.isNotEmpty;
  }

  Future<AccountingPeriodModel?> getPeriod(int mes, int anio) async {
    final db = await database.db;
    final rows = await db.query(
      'periodos',
      where: 'mes = ? AND anio = ?',
      whereArgs: [mes, anio],
      limit: 1,
    );
    return rows.isEmpty ? null : AccountingPeriodModel.fromMap(rows.first);
  }

  Future<AccountingPeriodModel> createPeriod({
    required int mes,
    required int anio,
    required String encargado,
  }) async {
    final db = await database.db;

    return db.transaction((txn) async {
      final periodId = await txn.insert('periodos', {
        'mes': mes,
        'anio': anio,
        'encargado': encargado.trim(),
        'estado': 'abierto',
      });

      final previousPeriods = await txn.query(
        'periodos',
        columns: ['periodo_id'],
        where: '(anio < ?) OR (anio = ? AND mes < ?)',
        whereArgs: [anio, anio, mes],
        orderBy: 'anio DESC, mes DESC',
        limit: 1,
      );
      final previousPeriodId = previousPeriods.isEmpty
          ? null
          : previousPeriods.first['periodo_id'] as int;

      final products = await txn.query(
        'productos',
        orderBy: 'nombre COLLATE NOCASE ASC',
      );

      for (final product in products) {
        final productId = product['producto_id'] as int;
        var initialQuantity =
            (product['cantidad_inicial'] as num?)?.toInt() ?? 0;

        if (previousPeriodId != null) {
          final previousInventory = await txn.query(
            'inventario_mensual',
            columns: ['cantidad_restante'],
            where: 'producto_id = ? AND periodo_id = ?',
            whereArgs: [productId, previousPeriodId],
            limit: 1,
          );
          if (previousInventory.isNotEmpty) {
            initialQuantity =
                (previousInventory.first['cantidad_restante'] as num).toInt();
          }
        }

        await txn.insert('inventario_mensual', {
          'producto_id': productId,
          'periodo_id': periodId,
          'cantidad_inicial': initialQuantity,
          'cantidad_comprada': 0,
          'cantidad_restante': initialQuantity,
          'precio_compra': product['precio_compra'],
          'precio_venta': product['precio_venta'],
        });
      }

      return AccountingPeriodModel(
        periodoId: periodId,
        mes: mes,
        anio: anio,
        encargado: encargado.trim(),
      );
    });
  }

  Future<List<MonthlyInventoryModel>> getInventory(int periodId) async {
    final db = await database.db;
    final rows = await db.rawQuery(
      '''
      SELECT inventario_mensual.*, productos.nombre, productos.imagen_path
      FROM inventario_mensual
      INNER JOIN productos
        ON productos.producto_id = inventario_mensual.producto_id
      WHERE inventario_mensual.periodo_id = ?
      ORDER BY productos.nombre COLLATE NOCASE ASC
    ''',
      [periodId],
    );
    return rows.map(MonthlyInventoryModel.fromMap).toList();
  }

  Future<({double ganancia, double dineroEnProducto})> getLatestTotals() async {
    final periods = await getPeriods();
    if (periods.isEmpty) return (ganancia: 0.0, dineroEnProducto: 0.0);
    final inventory = await getInventory(periods.first.periodoId!);
    double gain = 0;
    double invested = 0;
    for (final product in inventory) {
      gain += product.gananciaTotal;
      invested += product.dineroInvertidoRestante;
    }
    return (ganancia: gain, dineroEnProducto: invested);
  }

  Future<MonthlyInventoryModel?> getLatestAccountingProduct() async {
    final periods = await getPeriods();
    if (periods.isEmpty) return null;
    final db = await database.db;
    final rows = await db.rawQuery(
      '''
      SELECT inventario_mensual.*, productos.nombre, productos.imagen_path
      FROM inventario_mensual
      INNER JOIN productos
        ON productos.producto_id = inventario_mensual.producto_id
      WHERE inventario_mensual.periodo_id = ?
      ORDER BY inventario_mensual.inventario_id DESC
      LIMIT 1
    ''',
      [periods.first.periodoId],
    );
    return rows.isEmpty ? null : MonthlyInventoryModel.fromMap(rows.first);
  }

  Future<void> updateInventory(MonthlyInventoryModel inventory) async {
    final db = await database.db;
    final updated = await db.update(
      'inventario_mensual',
      {
        'cantidad_inicial': inventory.cantidadInicial,
        'cantidad_comprada': inventory.cantidadComprada,
        'cantidad_restante': inventory.cantidadRestante,
        'precio_compra': inventory.precioCompra,
        'precio_venta': inventory.precioVenta,
      },
      where: 'inventario_id = ?',
      whereArgs: [inventory.inventarioId],
    );

    if (updated != 1) {
      throw StateError('No se pudo actualizar el inventario mensual.');
    }
  }
}
