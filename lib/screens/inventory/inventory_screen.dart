import 'dart:io';

import 'package:flutter/material.dart';

import '../../models/product_model.dart';
import '../../repositories/product_repository.dart';
import '../../services/image_storage_service.dart';
import '../../widgets/product_card.dart';
import 'product_detail_screen.dart';

class InventoryScreen extends StatefulWidget {
  const InventoryScreen({super.key});

  @override
  State<InventoryScreen> createState() => _InventoryScreenState();
}

class _InventoryScreenState extends State<InventoryScreen> {
  final ProductRepository _repository = ProductRepository();
  final TextEditingController _searchController = TextEditingController();

  late Future<List<ProductModel>> _productosFuture;

  @override
  void initState() {
    super.initState();
    _cargarProductos();
  }

  void _cargarProductos() {
    _productosFuture = _repository.getAll();
  }

  Future<void> _refrescar() async {
    setState(_cargarProductos);
    await _productosFuture;
  }

  Future<void> _abrirFormulario() async {
    final guardado = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      showDragHandle: true,
      builder: (context) => const _ProductForm(),
    );

    if (guardado == true && mounted) {
      await _refrescar();
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Row(
          children: [
            Icon(Icons.inventory_2_rounded),
            SizedBox(width: 10),
            Text('Inventario'),
          ],
        ),
      ),
      body: Column(
        children: [
          // BUSCADOR
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              controller: _searchController,
              onChanged: (_) => setState(() {}),
              decoration: InputDecoration(
                hintText: 'Buscar productos...',
                prefixIcon: const Icon(Icons.search_rounded),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.close_rounded),
                        onPressed: () {
                          _searchController.clear();
                          setState(() {});
                        },
                      )
                    : null,
                filled: true,
                fillColor: colors.surfaceContainerLow,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),

          // LISTA DE PRODUCTOS
          Expanded(
            child: FutureBuilder<List<ProductModel>>(
              future: _productosFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (snapshot.hasError) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.error_outline, size: 44),
                          const SizedBox(height: 12),
                          const Text('Error al cargar productos'),
                          const SizedBox(height: 12),
                          FilledButton(
                            onPressed: _refrescar,
                            child: const Text('Reintentar'),
                          ),
                        ],
                      ),
                    ),
                  );
                }

                final todos = snapshot.data ?? [];

                final busqueda = _searchController.text.trim().toLowerCase();

                final productos = todos.where((producto) {
                  return producto.nombre.toLowerCase().contains(busqueda);
                }).toList();

                if (productos.isEmpty) {
                  return _estadoVacio(
                    busqueda.isEmpty
                        ? 'No hay productos registrados'
                        : 'No se encontraron productos',
                    busqueda.isEmpty
                        ? 'Agrega tu primer producto.'
                        : 'Intenta con otro nombre.',
                  );
                }

                return RefreshIndicator(
                  onRefresh: _refrescar,
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      final columnas = constraints.maxWidth >= 600 ? 4 : 2;

                      return GridView.builder(
                        padding: const EdgeInsets.fromLTRB(12, 0, 12, 90),
                        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: columnas,
                          crossAxisSpacing: 10,
                          mainAxisSpacing: 10,
                          mainAxisExtent: 230,
                        ),
                        itemCount: productos.length,
                        itemBuilder: (context, index) {
                          final producto = productos[index];

                          return ProductCard(
                            producto: producto,
                            onTap: () async {
                              await Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) =>
                                      ProductDetailScreen(producto: producto),
                                ),
                              );

                              if (mounted) {
                                await _refrescar();
                              }
                            },
                          );
                        },
                      );
                    },
                  ),
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _abrirFormulario,
        icon: const Icon(Icons.add_rounded),
        label: const Text('Agregar'),
      ),
    );
  }

  Widget _estadoVacio(String titulo, String mensaje) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.inventory_2_outlined,
            size: 70,
            color: Theme.of(context).colorScheme.outline,
          ),
          const SizedBox(height: 16),
          Text(
            titulo,
            style: Theme.of(context).textTheme.titleMedium,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(mensaje, textAlign: TextAlign.center),
        ],
      ),
    );
  }
}

// FORMULARIO PARA AGREGAR PRODUCTOS
class _ProductForm extends StatefulWidget {
  const _ProductForm();

  @override
  State<_ProductForm> createState() => _ProductFormState();
}

class _ProductFormState extends State<_ProductForm> {
  final _formKey = GlobalKey<FormState>();

  final _nombreController = TextEditingController();
  final _compraController = TextEditingController();
  final _ventaController = TextEditingController();

  final ProductRepository _repository = ProductRepository();
  final ImageStorageService _imageService = ImageStorageService();

  String? _imagenPath;
  bool _guardando = false;
  bool _guardado = false;

  // CONFIGURACIÓN DE IVA
  bool _aplicaIva = false;
  double _tarifaIva = 15;

  Future<void> _seleccionarImagen() async {
    try {
      final ruta = await _imageService.seleccionarYGuardarImagen();

      if (ruta == null) return;

      if (!mounted) {
        await _imageService.eliminarImagen(ruta);
        return;
      }

      final rutaAnterior = _imagenPath;

      setState(() {
        _imagenPath = ruta;
      });

      if (rutaAnterior != null) {
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

  String? _validarPrecio(String? value) {
    final precio = double.tryParse((value ?? '').trim().replaceAll(',', '.'));

    if (precio == null || !precio.isFinite || precio < 0) {
      return 'Ingresa un precio válido';
    }

    return null;
  }

  Future<void> _guardarProducto() async {
    if (!_formKey.currentState!.validate()) return;
    if (_guardando) return;

    setState(() => _guardando = true);

    try {
      final nombre = _nombreController.text.trim();

      final unico = await _repository.nombreUnico(nombre);

      if (!unico) {
        if (mounted) {
          _mostrarMensaje('Ya existe un producto con ese nombre.');
        }
        return;
      }

      final producto = ProductModel(
        nombre: nombre,
        imagenPath: _imagenPath,
        precioCompra: double.parse(
          _compraController.text.trim().replaceAll(',', '.'),
        ),
        precioVenta: double.parse(
          _ventaController.text.trim().replaceAll(',', '.'),
        ),
        tarifaIva: _aplicaIva ? _tarifaIva : 0,
      );

      await _repository.create(producto);
      _guardado = true;

      if (!mounted) return;

      Navigator.pop(context, true);
    } catch (e) {
      if (mounted) {
        _mostrarMensaje('Error al guardar el producto: $e');
      }
    } finally {
      if (mounted) {
        setState(() => _guardando = false);
      }
    }
  }

  @override
  void dispose() {
    // Eliminar fotografías provisionales al cerrar
    // el formulario sin guardar.
    if (!_guardado && _imagenPath != null) {
      _imageService.eliminarImagen(_imagenPath);
    }

    _nombreController.dispose();
    _compraController.dispose();
    _ventaController.dispose();

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
                'Nuevo producto',
                style: Theme.of(context).textTheme.titleLarge,
              ),

              const SizedBox(height: 20),

              // FOTOGRAFÍA
              Center(
                child: InkWell(
                  onTap: _guardando ? null : _seleccionarImagen,
                  borderRadius: BorderRadius.circular(16),
                  child: Container(
                    height: 140,
                    width: 180,
                    decoration: BoxDecoration(
                      color: colors.surfaceContainerHigh,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: _imagenPath == null
                        ? const Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.add_a_photo_outlined, size: 40),
                              SizedBox(height: 8),
                              Text('Agregar fotografía'),
                            ],
                          )
                        : ClipRRect(
                            borderRadius: BorderRadius.circular(16),
                            child: Image.file(
                              File(_imagenPath!),
                              fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) =>
                                  const Icon(Icons.broken_image_outlined),
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
                  prefixIcon: Icon(Icons.inventory_2_outlined),
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Ingresa el nombre';
                  }
                  return null;
                },
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
                          value: _tarifaIva,
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
                          'Selecciona la tarifa correspondiente '
                          'al producto.',
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
                      onPressed: _guardando ? null : _guardarProducto,
                      icon: _guardando
                          ? const SizedBox(
                              height: 16,
                              width: 16,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.save_outlined),
                      label: const Text('Guardar'),
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
