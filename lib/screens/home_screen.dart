import 'package:flutter/material.dart';
import '../repositories/accounting_repository.dart';
import '../models/monthly_inventory_model.dart';
import '../widgets/bento.dart';
import '../widgets/product_image.dart';

class HomeScreen extends StatefulWidget {
  final bool active;
  const HomeScreen({super.key, this.active = true});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  static const double capital = 1876.75;
  final _repository = AccountingRepository();
  late Future<({double ganancia, double dineroEnProducto})> _totals;
  late Future<MonthlyInventoryModel?> _latestProduct;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void didUpdateWidget(covariant HomeScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.active && !oldWidget.active) _load();
  }

  void _load() {
    _totals = _repository.getLatestTotals();
    _latestProduct = _repository.getLatestAccountingProduct();
  }

  Future<void> _refresh() async {
    final next = _repository.getLatestTotals();
    final nextProduct = _repository.getLatestAccountingProduct();
    if (!mounted) return;
    setState(() {
      _totals = next;
      _latestProduct = nextProduct;
    });
    await Future.wait([next, nextProduct]);
  }

  Future<void> _open(String route) async {
    await Navigator.pushNamed(context, route);
    if (!mounted) return;
    try {
      await _refresh();
    } catch (_) {
      // El estado de error permite reintentar la carga.
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Row(
          children: [
            Icon(Icons.storefront_rounded),
            SizedBox(width: 10),
            Text('Mi Tienda'),
          ],
        ),
        actions: [
          IconButton(
            onPressed: () {},
            icon: const Icon(Icons.notifications_none_rounded),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _refresh,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            const BentoHeader(
              eyebrow: 'Mi Tienda',
              title: 'Tu negocio, en orden.',
              subtitle: 'Inventario y contabilidad en un solo lugar.',
              icon: Icons.storefront_rounded,
            ),
            const SizedBox(height: 28),
            Text(
              'Resumen general',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 14),

            FutureBuilder<({double ganancia, double dineroEnProducto})>(
              future: _totals,
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return BentoTile(
                    child: Column(
                      children: [
                        const Text('No se pudo cargar el resumen'),
                        const SizedBox(height: 8),
                        FilledButton(
                          onPressed: _refresh,
                          child: const Text('Reintentar'),
                        ),
                      ],
                    ),
                  );
                }
                final totals = snapshot.data;
                return BentoGrid(
                  items: [
                    BentoItem(
                      _SummaryCard(
                        title: 'Ganancia acumulada',
                        value: totals == null
                            ? '...'
                            : '\$${totals.ganancia.toStringAsFixed(2)}',
                        icon: Icons.trending_up_rounded,
                      ),
                    ),
                    BentoItem(
                      _SummaryCard(
                        title: 'Dinero en producto',
                        value: totals == null
                            ? '...'
                            : '\$${totals.dineroEnProducto.toStringAsFixed(2)}',
                        icon: Icons.inventory_2_outlined,
                      ),
                    ),
                    BentoItem(
                      _SummaryCard(
                        title: 'Capital',
                        value: '\$${capital.toStringAsFixed(2)}',
                        icon: Icons.account_balance_wallet_outlined,
                      ),
                    ),
                  ],
                );
              },
            ),

            const SizedBox(height: 24),

            Text(
              'Último producto en contabilidad',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 12),

            FutureBuilder<MonthlyInventoryModel?>(
              future: _latestProduct,
              builder: (context, snapshot) {
                final product = snapshot.data;
                final colors = Theme.of(context).colorScheme;
                return BentoTile(
                  child: Row(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(14),
                        child: SizedBox(
                          width: 72,
                          height: 72,
                          child:
                              product?.imagenPath != null &&
                                  product!.imagenPath!.isNotEmpty
                              ? ProductImage(
                                  imagePath: product.imagenPath!,
                                  fallback: Icon(
                                    Icons.inventory_2_outlined,
                                    color: colors.primary,
                                  ),
                                )
                              : ColoredBox(
                                  color: colors.surfaceContainerHighest,
                                  child: Icon(
                                    Icons.inventory_2_outlined,
                                    color: colors.primary,
                                  ),
                                ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Text(
                          snapshot.hasError
                              ? 'No se pudo cargar el producto'
                              : snapshot.connectionState ==
                                    ConnectionState.waiting
                              ? 'Cargando producto...'
                              : product?.nombreProducto ??
                                    'Aún no hay productos en contabilidad',
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),

            const SizedBox(height: 24),

            Text(
              'Accesos rápidos',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 12),

            BentoGrid(
              items: [
                BentoItem(
                  _QuickAccess(
                    title: 'Contabilidad',
                    icon: Icons.calculate_outlined,
                    onTap: () => _open('/accounting'),
                  ),
                ),
                BentoItem(
                  _QuickAccess(
                    title: 'Inventario',
                    icon: Icons.inventory_2_outlined,
                    onTap: () => _open('/inventory'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _SummaryCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;

  const _SummaryCard({
    required this.title,
    required this.value,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return BentoTile(
      child: SizedBox(
        height: MediaQuery.textScalerOf(
          context,
        ).scale(126).clamp(126, 220).toDouble(),
        child: Padding(
          padding: const EdgeInsets.all(2),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(icon, color: Theme.of(context).colorScheme.primary),
              const Spacer(),
              Text(
                title,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: 4),
              FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerLeft,
                child: Text(
                  value,
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w800,
                    fontFeatures: const [FontFeature.tabularFigures()],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _QuickAccess extends StatelessWidget {
  final String title;
  final IconData icon;
  final VoidCallback onTap;

  const _QuickAccess({
    required this.title,
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return BentoTile(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.all(8),
        child: Column(
          children: [
            Icon(icon, size: 32),
            const SizedBox(height: 8),
            Text(title),
          ],
        ),
      ),
    );
  }
}
