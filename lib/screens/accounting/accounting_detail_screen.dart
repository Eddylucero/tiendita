import 'package:flutter/material.dart';

import '../../models/accounting_period_model.dart';
import '../../models/monthly_inventory_model.dart';
import '../../repositories/accounting_repository.dart';
import '../../widgets/product_image.dart';

class AccountingDetailScreen extends StatefulWidget {
  final AccountingPeriodModel period;
  const AccountingDetailScreen({super.key, required this.period});

  @override
  State<AccountingDetailScreen> createState() => _AccountingDetailScreenState();
}

class _AccountingDetailScreenState extends State<AccountingDetailScreen> {
  final _repository = AccountingRepository();
  final _form = GlobalKey<FormState>();
  final _initial = TextEditingController();
  final _bought = TextEditingController();
  final _remaining = TextEditingController();
  final _purchase = TextEditingController();
  final _sale = TextEditingController();
  late Future<List<MonthlyInventoryModel>> _future;
  List<MonthlyInventoryModel> _items = [];
  int _index = 0;
  bool _saving = false;
  bool _dirty = false;
  bool _loadingFields = false;

  @override
  void initState() {
    super.initState();
    _future = _repository.getInventory(widget.period.periodoId!);
    for (final c in [_initial, _bought, _remaining, _purchase, _sale]) {
      c.addListener(() {
        if (mounted && !_loadingFields) {
          setState(() {
            _dirty = true;
          });
        }
      });
    }
  }

  @override
  void dispose() {
    for (final c in [_initial, _bought, _remaining, _purchase, _sale]) {
      c.dispose();
    }
    super.dispose();
  }

  void _show(int index) {
    _loadingFields = true;
    _index = index;
    final item = _items[index];
    _initial.text = '${item.cantidadInicial}';
    _bought.text = '${item.cantidadComprada}';
    _remaining.text = '${item.cantidadRestante}';
    _purchase.text = item.precioCompra.toStringAsFixed(2);
    _sale.text = item.precioVenta.toStringAsFixed(2);
    _dirty = false;
    _loadingFields = false;
  }

  int? _quantity(String value) => int.tryParse(value.trim());
  double? _price(String value) =>
      double.tryParse(value.trim().replaceAll(',', '.'));

  String? _validateQuantity(String? value) {
    final n = _quantity(value ?? '');
    return n == null || n < 0 ? 'Ingresa una cantidad válida' : null;
  }

  String? _validateRemaining(String? value) {
    final n = _quantity(value ?? '');
    final initial = _quantity(_initial.text);
    final bought = _quantity(_bought.text);
    if (n == null || n < 0) return 'Ingresa una cantidad válida';
    if (initial != null && bought != null && n > initial + bought) {
      return 'No puede superar la cantidad total';
    }
    return null;
  }

  String? _validatePrice(String? value) {
    final n = _price(value ?? '');
    return n == null || !n.isFinite || n < 0
        ? 'Ingresa un precio válido'
        : null;
  }

  Future<bool> _save() async {
    if (_saving) return false;
    if (!_dirty) return true;
    if (!_form.currentState!.validate()) return false;
    setState(() {
      _saving = true;
    });
    try {
      final item = _items[_index];
      final updated = MonthlyInventoryModel(
        inventarioId: item.inventarioId,
        productoId: item.productoId,
        periodoId: item.periodoId,
        nombreProducto: item.nombreProducto,
        imagenPath: item.imagenPath,
        cantidadInicial: _quantity(_initial.text)!,
        cantidadComprada: _quantity(_bought.text)!,
        cantidadRestante: _quantity(_remaining.text)!,
        precioCompra: _price(_purchase.text)!,
        precioVenta: _price(_sale.text)!,
      );
      await _repository.updateInventory(updated);
      _items[_index] = updated;
      _dirty = false;
      return true;
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('No se pudieron guardar los cambios: $e')),
        );
      }
      return false;
    } finally {
      if (mounted) {
        setState(() {
          _saving = false;
        });
      }
    }
  }

  Future<void> _move(int step) async {
    if (!await _save() || !mounted) return;
    setState(() {
      _show(_index + step);
    });
  }

  Future<void> _back() async {
    if (await _save() && mounted) {
      Navigator.pop(context);
    }
  }

  Widget _field(
    String label,
    TextEditingController controller,
    String? Function(String?) validator, {
    bool decimal = false,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextFormField(
        controller: controller,
        enabled: !_saving,
        keyboardType: TextInputType.numberWithOptions(decimal: decimal),
        decoration: InputDecoration(
          labelText: label,
          prefixText: decimal ? '\$ ' : null,
          border: const OutlineInputBorder(),
        ),
        validator: validator,
      ),
    );
  }

  Widget _value(String title, String value, IconData icon) {
    final colors = Theme.of(context).colorScheme;
    return Card(
      elevation: 0,
      color: colors.surfaceContainerLow,
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: colors.primary),
            const SizedBox(height: 12),
            Text(title, style: Theme.of(context).textTheme.bodySmall),
            const SizedBox(height: 6),
            Text(
              value,
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return PopScope(
      canPop: !_dirty && !_saving,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop && !_saving) _back();
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text('${widget.period.nombreMes} ${widget.period.anio}'),
        ),
        body: FutureBuilder<List<MonthlyInventoryModel>>(
          future: _future,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            if (snapshot.hasError) {
              return Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text('Error al cargar productos'),
                    FilledButton(
                      onPressed: () {
                        final nextInventory = _repository.getInventory(
                          widget.period.periodoId!,
                        );
                        setState(() {
                          _future = nextInventory;
                        });
                      },
                      child: const Text('Reintentar'),
                    ),
                  ],
                ),
              );
            }
            if (_items.isEmpty) {
              _items = snapshot.data ?? [];
              if (_items.isNotEmpty) _show(0);
            }
            if (_items.isEmpty) {
              return const Center(
                child: Text('No hay productos registrados en este período.'),
              );
            }
            final item = _items[_index];
            final initial = _quantity(_initial.text) ?? 0;
            final bought = _quantity(_bought.text) ?? 0;
            final remaining = _quantity(_remaining.text) ?? 0;
            final purchase = _price(_purchase.text) ?? 0;
            final sale = _price(_sale.text) ?? 0;
            final total = initial + bought;
            final sold = total - remaining;
            return Form(
              key: _form,
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  Text(
                    'Tiendero: ${widget.period.encargado}',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Producto ${_index + 1} de ${_items.length}',
                    style: TextStyle(color: colors.onSurfaceVariant),
                  ),
                  const SizedBox(height: 16),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(20),
                    child: SizedBox(
                      height: 250,
                      width: double.infinity,
                      child: item.imagenPath == null || item.imagenPath!.isEmpty
                          ? _fallback(colors)
                          : ProductImage(
                              imagePath: item.imagenPath!,
                              fallback: _fallback(colors),
                            ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    item.nombreProducto,
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 20),
                  _value(
                    'Cantidad inicial',
                    '${item.cantidadInicial}',
                    Icons.inventory_2_outlined,
                  ),
                  SizedBox(height: 12),
                  _field('Cantidad comprada', _bought, _validateQuantity),
                  _field(
                    'Cantidad de producto que sobra',
                    _remaining,
                    _validateRemaining,
                  ),
                  _field(
                    'Precio pueblo (compra)',
                    _purchase,
                    _validatePrice,
                    decimal: true,
                  ),
                  _field(
                    'Precio tienda (venta)',
                    _sale,
                    _validatePrice,
                    decimal: true,
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: _value(
                          'Cantidad total',
                          '$total',
                          Icons.inventory_2_outlined,
                        ),
                      ),
                      Expanded(
                        child: _value(
                          'Cantidad vendida',
                          '$sold',
                          Icons.sell_outlined,
                        ),
                      ),
                    ],
                  ),
                  Row(
                    children: [
                      Expanded(
                        child: _value(
                          'Dinero en producto',
                          '\$${(remaining * purchase).toStringAsFixed(2)}',
                          Icons.account_balance_wallet_outlined,
                        ),
                      ),
                      Expanded(
                        child: _value(
                          'Ganancia por producto',
                          '\$${((sale - purchase) * sold).toStringAsFixed(2)}',
                          Icons.trending_up_rounded,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  FilledButton.icon(
                    onPressed: _saving
                        ? null
                        : () async {
                            if (await _save() && mounted) {
                              ScaffoldMessenger.of(this.context).showSnackBar(
                                const SnackBar(
                                  content: Text('Cambios guardados'),
                                ),
                              );
                            }
                          },
                    icon: const Icon(Icons.save_outlined),
                    label: const Text('Guardar cambios'),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: _saving || _index == 0
                              ? null
                              : () => _move(-1),
                          child: const Text('Anterior'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: FilledButton(
                          onPressed: _saving || _index == _items.length - 1
                              ? null
                              : () => _move(1),
                          child: const Text('Siguiente'),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 40),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _fallback(ColorScheme colors) => Container(
    color: colors.surfaceContainerHighest,
    child: Icon(
      Icons.inventory_2_outlined,
      size: 85,
      color: colors.onSurfaceVariant,
    ),
  );
}
