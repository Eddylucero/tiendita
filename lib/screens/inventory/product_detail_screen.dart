import 'package:flutter/material.dart';

import '../../models/product_model.dart';
import '../../repositories/product_repository.dart';
import '../../services/image_storage_service.dart';
import '../../widgets/product_image.dart';

class ProductDetailScreen extends StatefulWidget {
  final ProductModel producto;

  const ProductDetailScreen({super.key, required this.producto});

  @override
  State<ProductDetailScreen> createState() => _ProductDetailScreenState();
}

class _ProductDetailScreenState extends State<ProductDetailScreen> {
  final ProductRepository _repository = ProductRepository();

  late ProductModel _producto;
  late Future<int> _cantidadDisponibleFuture;

  @override
  void initState() {
    super.initState();
    _producto = widget.producto;
    _cantidadDisponibleFuture = _repository.getAvailableQuantity(_producto);
  }

  Future<void> _editarProducto() async {
    final actualizado = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      showDragHandle: true,
      builder: (context) => _EditProductForm(producto: _producto),
    );

    if (actualizado != true) return;

    try {
      final productoActualizado = await _repository.getById(
        _producto.productoId!,
      );

      if (!mounted) return;

      if (productoActualizado != null) {
        final nuevaCantidadFuture = _repository.getAvailableQuantity(
          productoActualizado,
        );
        setState(() {
          _producto = productoActualizado;
          _cantidadDisponibleFuture = nuevaCantidadFuture;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Producto actualizado correctamente')),
        );
      }
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('No se pudo actualizar la vista: $e')),
      );
    }
  }

  Widget _mostrarImagen() {
    final colors = Theme.of(context).colorScheme;
    final ruta = _producto.imagenPath;

    if (ruta == null || ruta.isEmpty) {
      return _imagenPredeterminada(colors);
    }

    return SizedBox(
      width: double.infinity,
      height: 250,
      child: ProductImage(
        imagePath: ruta,
        fallback: _imagenPredeterminada(colors),
      ),
    );
  }

  Widget _imagenPredeterminada(ColorScheme colors) {
    return Container(
      height: 250,
      width: double.infinity,
      color: colors.surfaceContainerHighest,
      child: Icon(
        Icons.inventory_2_outlined,
        size: 85,
        color: colors.onSurfaceVariant,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Detalle del producto'),
        actions: [
          IconButton(
            tooltip: 'Editar producto',
            onPressed: _editarProducto,
            icon: const Icon(Icons.edit_outlined),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // FOTOGRAFÍA
          ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: _mostrarImagen(),
          ),

          const SizedBox(height: 24),

          // NOMBRE
          Text(
            _producto.nombre,
            style: theme.textTheme.headlineMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),

          const SizedBox(height: 8),

          Text(
            'Información general del producto',
            style: TextStyle(color: colors.onSurfaceVariant),
          ),

          const SizedBox(height: 20),

          // ESTADO DEL IVA
          Card(
            elevation: 0,
            color: colors.surfaceContainerLow,
            child: ListTile(
              leading: Icon(Icons.receipt_long_outlined, color: colors.primary),
              title: const Text('Impuesto al Valor Agregado'),
              subtitle: Text(
                _producto.aplicaIva
                    ? 'Tarifa registrada: ${_producto.tarifaIva.toStringAsFixed(0)} %'
                    : 'Tarifa registrada: 0 %',
              ),
              trailing: Chip(
                label: Text(
                  _producto.aplicaIva
                      ? '${_producto.tarifaIva.toStringAsFixed(0)} %'
                      : '0 %',
                ),
              ),
            ),
          ),

          const SizedBox(height: 20),

          // PRECIOS
          Row(
            children: [
              Expanded(
                child: _DetailCard(
                  titulo: 'Precio de compra',
                  valor: '\$${_producto.precioCompra.toStringAsFixed(2)}',
                  icono: Icons.shopping_cart_outlined,
                  color: colors.primary,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _DetailCard(
                  titulo: 'Precio de venta',
                  valor: '\$${_producto.precioVenta.toStringAsFixed(2)}',
                  icono: Icons.sell_outlined,
                  color: colors.tertiary,
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),

          Row(
            children: [
              Expanded(
                child: _DetailCard(
                  titulo: 'Ganancia unitaria',
                  valor: '\$${_producto.gananciaUnitaria.toStringAsFixed(2)}',
                  icono: Icons.trending_up_rounded,
                  color: colors.primary,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: FutureBuilder<int>(
                  future: _cantidadDisponibleFuture,
                  builder: (context, snapshot) => _DetailCard(
                    titulo: 'Cantidad disponible',
                    valor: snapshot.hasError
                        ? 'Error'
                        : snapshot.hasData ? '${snapshot.data}' : '...',
                    icono: Icons.inventory_2_outlined,
                    color: colors.secondary,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 24),

          FilledButton.icon(
            onPressed: _editarProducto,
            icon: const Icon(Icons.edit_rounded),
            label: const Text('Editar producto'),
            style: FilledButton.styleFrom(
              minimumSize: const Size.fromHeight(52),
            ),
          ),
        ],
      ),
    );
  }
}

// TARJETA DE INFORMACIÓN
class _DetailCard extends StatelessWidget {
  final String titulo;
  final String valor;
  final IconData icono;
  final Color color;

  const _DetailCard({
    required this.titulo,
    required this.valor,
    required this.icono,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      elevation: 0,
      color: theme.colorScheme.surfaceContainerLow,
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icono, color: color),
            const SizedBox(height: 14),
            Text(titulo, style: theme.textTheme.bodySmall),
            const SizedBox(height: 6),
            Text(
              valor,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// FORMULARIO PARA EDITAR PRODUCTO
class _EditProductForm extends StatefulWidget {
  final ProductModel producto;

  const _EditProductForm({required this.producto});

  @override
  State<_EditProductForm> createState() => _EditProductFormState();
}

class _EditProductFormState extends State<_EditProductForm> {
  final _formKey = GlobalKey<FormState>();

  final ProductRepository _repository = ProductRepository();
  final ImageStorageService _imageService = ImageStorageService();

  late TextEditingController _nombreController;
  late TextEditingController _compraController;
  late TextEditingController _ventaController;
  late TextEditingController _cantidadInicialController;

  String? _imagenPath;
  String? _imagenOriginal;

  bool _guardando = false;
  bool _guardado = false;

  // CONFIGURACIÓN DEL IVA
  bool _aplicaIva = false;
  double _tarifaIva = 15;

  @override
  void initState() {
    super.initState();

    _nombreController = TextEditingController(text: widget.producto.nombre);
    _cantidadInicialController = TextEditingController(
      text: '${widget.producto.cantidadInicial}',
    );

    _compraController = TextEditingController(
      text: widget.producto.precioCompra.toStringAsFixed(2),
    );

    _ventaController = TextEditingController(
      text: widget.producto.precioVenta.toStringAsFixed(2),
    );

    _imagenPath = widget.producto.imagenPath;
    _imagenOriginal = widget.producto.imagenPath;

    // RECUPERAR IVA GUARDADO
    _aplicaIva = widget.producto.aplicaIva;
    _tarifaIva = _aplicaIva ? widget.producto.tarifaIva : 15;
  }

  Future<void> _seleccionarImagen() async {
    try {
      final nuevaRuta = await _imageService.seleccionarYGuardarImagen();

      if (nuevaRuta == null) return;

      if (!mounted) {
        await _imageService.eliminarImagen(nuevaRuta);
        return;
      }

      final rutaAnterior = _imagenPath;

      setState(() {
        _imagenPath = nuevaRuta;
      });

      // Eliminar únicamente fotografías provisionales.
      if (rutaAnterior != null && rutaAnterior != _imagenOriginal) {
        await _imageService.eliminarImagen(rutaAnterior);
      }
    } catch (e) {
      if (!mounted) return;

      _mostrarMensaje('No se pudo seleccionar la imagen.');
    }
  }

  void _mostrarMensaje(String mensaje) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(mensaje)));
  }

  String? _validarPrecio(String? valor) {
    final numero = double.tryParse((valor ?? '').trim().replaceAll(',', '.'));

    if (numero == null || !numero.isFinite || numero < 0) {
      return 'Ingresa un precio válido';
    }

    return null;
  }

  String? _validarCantidad(String? valor) {
    final cantidad = int.tryParse((valor ?? '').trim());
    return cantidad == null || cantidad < 0
        ? 'Ingresa una cantidad válida'
        : null;
  }

  Future<void> _guardarCambios() async {
    if (!_formKey.currentState!.validate()) return;
    if (_guardando) return;

    setState(() => _guardando = true);

    try {
      final nombre = _nombreController.text.trim();

      final unico = await _repository.nombreUnico(
        nombre,
        productoId: widget.producto.productoId,
      );

      if (!unico) {
        if (mounted) {
          _mostrarMensaje('Ya existe otro producto con ese nombre.');
        }
        return;
      }

      final actualizado = ProductModel(
        productoId: widget.producto.productoId,
        nombre: nombre,
        imagenPath: _imagenPath,
        precioCompra: double.parse(
          _compraController.text.trim().replaceAll(',', '.'),
        ),
        precioVenta: double.parse(
          _ventaController.text.trim().replaceAll(',', '.'),
        ),
        tarifaIva: _aplicaIva ? _tarifaIva : 0,
        cantidadInicial: int.parse(_cantidadInicialController.text.trim()),
      );

      await _repository.edit(actualizado);

      _guardado = true;

      // Eliminar la imagen anterior solo después
      // de actualizar SQLite correctamente.
      if (_imagenOriginal != null && _imagenOriginal != _imagenPath) {
        try {
          await _imageService.eliminarImagen(_imagenOriginal);
        } catch (_) {
          // La actualización de SQLite ya se completó.
        }
      }

      if (!mounted) return;

      Navigator.pop(context, true);
    } catch (e) {
      if (mounted) {
        _mostrarMensaje('Error al actualizar el producto: $e');
      }
    } finally {
      if (mounted) {
        setState(() => _guardando = false);
      }
    }
  }

  @override
  void dispose() {
    // Limpiar fotografía provisional si se cancela.
    if (!_guardado && _imagenPath != null && _imagenPath != _imagenOriginal) {
      _imageService.eliminarImagen(_imagenPath);
    }

    _nombreController.dispose();
    _compraController.dispose();
    _ventaController.dispose();
    _cantidadInicialController.dispose();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Padding(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom + 20,
      ),
      child: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Editar producto',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 14),

              // FOTOGRAFÍA
              Center(
                child: InkWell(
                  onTap: _guardando ? null : _seleccionarImagen,
                  borderRadius: BorderRadius.circular(16),
                  child: Container(
                    width: 180,
                    height: 140,
                    decoration: BoxDecoration(
                      color: colors.surfaceContainerHigh,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: _imagenPath == null
                        ? const Icon(Icons.add_a_photo_outlined, size: 48)
                        : ClipRRect(
                            borderRadius: BorderRadius.circular(16),
                            child: ProductImage(
                              imagePath: _imagenPath!,
                              fallback: const Icon(Icons.broken_image_outlined),
                            ),
                          ),
                  ),
                ),
              ),

              const SizedBox(height: 20),

              // NOMBRE
              TextFormField(
                controller: _nombreController,
                enabled: !_guardando,
                textCapitalization: TextCapitalization.sentences,
                decoration: const InputDecoration(
                  labelText: 'Nombre del producto',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.inventory_2_outlined),
                ),
                validator: (valor) {
                  if (valor == null || valor.trim().isEmpty) {
                    return 'Ingresa el nombre';
                  }
                  return null;
                },
              ),

              const SizedBox(height: 14),

              TextFormField(
                controller: _cantidadInicialController,
                enabled: !_guardando,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Cantidad inicial',
                  prefixIcon: Icon(Icons.inventory_2_outlined),
                  border: OutlineInputBorder(),
                ),
                validator: _validarCantidad,
              ),

              const SizedBox(height: 14),

              // PRECIO DE COMPRA
              TextFormField(
                controller: _compraController,
                enabled: !_guardando,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                decoration: const InputDecoration(
                  labelText: 'Precio pueblo (compra)',
                  prefixText: '\$ ',
                  border: OutlineInputBorder(),
                ),
                validator: _validarPrecio,
              ),

              const SizedBox(height: 14),

              // PRECIO DE VENTA
              TextFormField(
                controller: _ventaController,
                enabled: !_guardando,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                decoration: const InputDecoration(
                  labelText: 'Precio tienda (venta)',
                  prefixText: '\$ ',
                  border: OutlineInputBorder(),
                ),
                validator: _validarPrecio,
              ),

              const SizedBox(height: 18),

              // CONFIGURACIÓN DE IVA
              Card(
                elevation: 0,
                color: colors.surfaceContainerLow,
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  child: Column(
                    children: [
                      SwitchListTile(
                        contentPadding: EdgeInsets.zero,
                        title: const Text(
                          'Aplicar IVA',
                          style: TextStyle(fontWeight: FontWeight.w600),
                        ),
                        subtitle: Text(
                          _aplicaIva ? 'Producto con IVA' : 'Producto sin IVA',
                        ),
                        secondary: const Icon(Icons.receipt_long_outlined),
                        value: _aplicaIva,
                        onChanged: _guardando
                            ? null
                            : (valor) {
                                setState(() {
                                  _aplicaIva = valor;
                                });
                              },
                      ),

                      if (_aplicaIva) ...[
                        const Divider(),

                        DropdownButtonFormField<double>(
                          initialValue: _tarifaIva,
                          decoration: const InputDecoration(
                            labelText: 'Tarifa de IVA',
                            prefixIcon: Icon(Icons.percent_rounded),
                            border: OutlineInputBorder(),
                          ),
                          items: const [
                            DropdownMenuItem(value: 15, child: Text('15 %')),
                            DropdownMenuItem(value: 5, child: Text('5 %')),
                          ],
                          onChanged: _guardando
                              ? null
                              : (valor) {
                                  if (valor != null) {
                                    setState(() {
                                      _tarifaIva = valor;
                                    });
                                  }
                                },
                        ),

                        const SizedBox(height: 10),

                        Text(
                          'La tarifa seleccionada se guardará '
                          'en la base de datos.',
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ],
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 24),

              // BOTONES
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: _guardando
                          ? null
                          : () => Navigator.pop(context, false),
                      child: const Text('Cancelar'),
                    ),
                  ),

                  const SizedBox(width: 12),

                  Expanded(
                    child: FilledButton.icon(
                      onPressed: _guardando ? null : _guardarCambios,
                      icon: _guardando
                          ? const SizedBox(
                              height: 16,
                              width: 16,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.save_outlined),
                      label: const Text('Guardar cambios'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
