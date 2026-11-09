class ProductModel {
  int? productoId;
  String nombre;
  String? imagenPath;
  double precioCompra;
  double precioVenta;
  double tarifaIva;

  ProductModel({
    this.productoId,
    required this.nombre,
    this.imagenPath,
    required this.precioCompra,
    required this.precioVenta,
    this.tarifaIva = 0.0,
  });

  factory ProductModel.fromMap(Map<String, dynamic> data) {
    return ProductModel(
      productoId: data['producto_id'] as int?,
      nombre: data['nombre'] as String,
      imagenPath: data['imagen_path'] as String?,
      precioCompra: (data['precio_compra'] as num?)?.toDouble() ?? 0.0,
      precioVenta: (data['precio_venta'] as num?)?.toDouble() ?? 0.0,

      // Si el producto es antiguo o el IVA es NULL,
      // se utiliza temporalmente 0.
      tarifaIva: (data['tarifa_iva'] as num?)?.toDouble() ?? 0.0,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'producto_id': productoId,
      'nombre': nombre,
      'imagen_path': imagenPath,
      'precio_compra': precioCompra,
      'precio_venta': precioVenta,
      'tarifa_iva': tarifaIva,
    };
  }

  double get gananciaUnitaria => precioVenta - precioCompra;

  bool get aplicaIva => tarifaIva > 0;
}
