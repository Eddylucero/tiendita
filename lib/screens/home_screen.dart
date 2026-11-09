import 'package:flutter/material.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

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
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(
            'Resumen general',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 6),
          const Text('Información del período contable'),
          const SizedBox(height: 20),

          // TARJETAS DEL RESUMEN
          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            mainAxisSpacing: 12,
            crossAxisSpacing: 12,
            childAspectRatio: 1.35,
            children: const [
              _SummaryCard(
                title: 'Ingresos',
                icon: Icons.trending_up_rounded,
                color: Colors.green,
              ),
              _SummaryCard(
                title: 'Gastos',
                icon: Icons.trending_down_rounded,
                color: Colors.redAccent,
              ),
              _SummaryCard(
                title: 'Ganancia estimada',
                icon: Icons.account_balance_wallet_outlined,
                color: Colors.blue,
              ),
              _SummaryCard(
                title: 'Plata en productos',
                icon: Icons.inventory_2_outlined,
                color: Colors.teal,
              ),
            ],
          ),

          const SizedBox(height: 24),

          // MOVIMIENTOS RECIENTES
          Text(
            'Movimientos recientes',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 12),

          Card(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                children: [
                  Icon(
                    Icons.receipt_long_outlined,
                    size: 42,
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'Aquí aparecerán los movimientos',
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 24),

          Text(
            'Accesos rápidos',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 12),

          Row(
            children: [
              Expanded(
                child: _QuickAccess(
                  title: 'Contabilidad',
                  icon: Icons.calculate_outlined,
                  onTap: () {
                    Navigator.pushNamed(context, '/accounting');
                  },
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _QuickAccess(
                  title: 'Inventario',
                  icon: Icons.inventory_2_outlined,
                  onTap: () {
                    Navigator.pushNamed(context, '/inventory');
                  },
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _SummaryCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final Color color;

  const _SummaryCard({
    required this.title,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: color),
            const Spacer(),
            Text(
              title,
              maxLines: 2,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 4),
            const Text(
              'Sin datos',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ],
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
    return Card(
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              Icon(icon, size: 32),
              const SizedBox(height: 8),
              Text(title),
            ],
          ),
        ),
      ),
    );
  }
}
