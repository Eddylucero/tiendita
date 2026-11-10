class MonthlyInventoryModel {
  final int inventarioId;
  final int productoId;
  final int periodoId;
  final String nombreProducto;
  final String? imagenPath;
  int cantidadInicial;
  int cantidadComprada;
  int cantidadRestante;
  double precioCompra;
  double precioVenta;

  MonthlyInventoryModel({
    required this.inventarioId,
    required this.productoId,
    required this.periodoId,
    required this.nombreProducto,
    this.imagenPath,
    required this.cantidadInicial,
    required this.cantidadComprada,
    required this.cantidadRestante,
    required this.precioCompra,
    required this.precioVenta,
  });

  factory MonthlyInventoryModel.fromMap(Map<String, dynamic> data) {
    return MonthlyInventoryModel(
      inventarioId: data['inventario_id'] as int,
      productoId: data['producto_id'] as int,
      periodoId: data['periodo_id'] as int,
      nombreProducto: data['nombre'] as String,
      imagenPath: data['imagen_path'] as String?,
      cantidadInicial: (data['cantidad_inicial'] as num).toInt(),
      cantidadComprada: (data['cantidad_comprada'] as num).toInt(),
      cantidadRestante: (data['cantidad_restante'] as num).toInt(),
      precioCompra: (data['precio_compra'] as num).toDouble(),
      precioVenta: (data['precio_venta'] as num).toDouble(),
    );
  }

  int get cantidadTotal => cantidadInicial + cantidadComprada;
  int get cantidadVendida => cantidadTotal - cantidadRestante;
  double get gananciaUnitaria => precioVenta - precioCompra;
  double get gananciaTotal => cantidadVendida * gananciaUnitaria;
  double get dineroInvertidoRestante => cantidadRestante * precioCompra;
}
