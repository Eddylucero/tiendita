import 'package:flutter/material.dart';
import 'package:sqflite/sqflite.dart';

import '../../models/accounting_period_model.dart';
import '../../repositories/accounting_repository.dart';
import 'accounting_detail_screen.dart';
import '../../widgets/bento.dart';

class AccountingScreen extends StatefulWidget {
  final bool active;
  const AccountingScreen({super.key, this.active = true});

  @override
  State<AccountingScreen> createState() => _AccountingScreenState();
}

class _AccountingScreenState extends State<AccountingScreen> {
  final _repository = AccountingRepository();
  late Future<List<AccountingPeriodModel>> _periods;

  @override
  void initState() {
    super.initState();
    _reload();
  }

  @override
  void didUpdateWidget(covariant AccountingScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.active && !oldWidget.active) {
      _reload();
    }
  }

  void _reload() {
    _periods = _repository.getPeriods();
  }

  Future<void> _refresh() async {
    final nextPeriods = _repository.getPeriods();
    if (!mounted) return;
    setState(() {
      _periods = nextPeriods;
    });
    await nextPeriods;
  }

  Future<void> _open(AccountingPeriodModel period) async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => AccountingDetailScreen(period: period)),
    );
    if (!mounted) return;
    try {
      await _refresh();
    } catch (_) {
      // FutureBuilder muestra el error y ofrece Reintentar.
    }
  }

  Future<void> _create() async {
    final input = await showDialog<({int mes, int anio, String encargado})>(
      context: context,
      builder: (_) => const _NewPeriodDialog(),
    );
    if (input == null || !mounted) return;
    AccountingPeriodModel period;
    try {
      final existing = await _repository.getPeriod(input.mes, input.anio);
      period =
          existing ??
          await _repository.createPeriod(
            mes: input.mes,
            anio: input.anio,
            encargado: input.encargado,
          );
    } on DatabaseException catch (e) {
      if (e.isUniqueConstraintError()) {
        final existing = await _repository.getPeriod(input.mes, input.anio);
        if (existing != null) {
          if (!mounted) return;
          await _showSavedPeriod(existing);
          return;
        }
      }
      if (mounted) {
        _message('No se pudo crear el período: $e');
      }
      return;
    } catch (e) {
      if (mounted) {
        _message('No se pudo crear el período: $e');
      }
      return;
    }
    if (!mounted) return;
    await _showSavedPeriod(period);
  }

  Future<void> _showSavedPeriod(AccountingPeriodModel period) async {
    if (!mounted) return;
    try {
      await _refresh();
    } catch (e) {
      if (mounted) {
        _message(
          'El período está guardado, pero no se pudo actualizar la lista: $e',
        );
      }
    }
    if (!mounted) return;
    await _open(period);
  }

  void _message(String value) => ScaffoldMessenger.of(
    context,
  ).showSnackBar(SnackBar(content: Text(value)));

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(
        title: const Row(
          children: [
            Icon(Icons.calculate_rounded),
            SizedBox(width: 10),
            Text('Contabilidad'),
          ],
        ),
      ),
      body: Column(
        children: [
          const Padding(
            padding: EdgeInsets.fromLTRB(16, 8, 16, 8),
            child: BentoHeader(
              eyebrow: 'Períodos contables',
              title: 'Cada mes, claro.',
              subtitle:
                  'Revisa productos y registra los movimientos del período.',
              icon: Icons.calendar_month_rounded,
            ),
          ),
          Expanded(
            child: FutureBuilder<List<AccountingPeriodModel>>(
              future: _periods,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError) {
                  return Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Text('Error al cargar períodos'),
                        const SizedBox(height: 12),
                        FilledButton(
                          onPressed: _refresh,
                          child: const Text('Reintentar'),
                        ),
                      ],
                    ),
                  );
                }
                final periods = snapshot.data ?? [];
                if (periods.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.calendar_month_outlined,
                          size: 70,
                          color: colors.outline,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'No hay períodos registrados',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        const SizedBox(height: 8),
                        const Text('Agrega tu primer período.'),
                      ],
                    ),
                  );
                }
                return RefreshIndicator(
                  onRefresh: _refresh,
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      final columns = constraints.maxWidth >= 700
                          ? 4
                          : constraints.maxWidth >= 340
                          ? 2
                          : 1;
                      Widget tile(AccountingPeriodModel period, {bool featured = false}) => BentoTile(
                        featured: featured,
                        onTap: () => _open(period),
                        child: Padding(
                          padding: const EdgeInsets.all(2),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Icon(
                                Icons.calendar_month_outlined,
                                size: 42,
                                color: colors.primary,
                              ),
                              const Spacer(),
                              Text(
                                '${period.nombreMes} ${period.anio}',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w600,
                                  fontSize: 15,
                                ),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                period.encargado,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(color: colors.primary),
                              ),
                            ],
                          ),
                        ),
                      );
                      return CustomScrollView(
                        slivers: [
                          SliverPadding(
                            padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
                            sliver: SliverToBoxAdapter(
                              child: SizedBox(
                                height: 150,
                                child: tile(periods.first, featured: true),
                              ),
                            ),
                          ),
                          SliverPadding(
                            padding: const EdgeInsets.fromLTRB(12, 0, 12, 90),
                            sliver: SliverGrid(
                              gridDelegate:
                                  SliverGridDelegateWithFixedCrossAxisCount(
                                    crossAxisCount: columns,
                                    crossAxisSpacing: 12,
                                    mainAxisSpacing: 12,
                                    mainAxisExtent: MediaQuery.textScalerOf(
                                      context,
                                    ).scale(180).clamp(180, 280).toDouble(),
                                  ),
                              delegate: SliverChildBuilderDelegate(
                                (context, index) => tile(periods[index + 1]),
                                childCount: periods.length - 1,
                              ),
                            ),
                          ),
                        ],
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
        heroTag: null,
        onPressed: _create,
        icon: const Icon(Icons.add_rounded),
        label: const Text('Agregar'),
      ),
    );
  }
}

class _NewPeriodDialog extends StatefulWidget {
  const _NewPeriodDialog();
  @override
  State<_NewPeriodDialog> createState() => _NewPeriodDialogState();
}

class _NewPeriodDialogState extends State<_NewPeriodDialog> {
  final _form = GlobalKey<FormState>();
  final _name = TextEditingController();
  late int _month;
  late int _year;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _month = now.month;
    _year = now.year;
  }

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
    title: const Text('Nuevo período'),
    content: Form(
      key: _form,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          DropdownButtonFormField<int>(
            initialValue: _month,
            decoration: const InputDecoration(
              labelText: 'Mes',
              border: OutlineInputBorder(),
            ),
            items: List.generate(
              12,
              (i) => DropdownMenuItem(
                value: i + 1,
                child: Text(AccountingPeriodModel.nombresMeses[i]),
              ),
            ),
            onChanged: (value) {
              if (value != null) {
                setState(() {
                  _month = value;
                });
              }
            },
          ),
          const SizedBox(height: 12),
          TextFormField(
            initialValue: '$_year',
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(
              labelText: 'Año',
              border: OutlineInputBorder(),
            ),
            validator: (value) {
              final year = int.tryParse((value ?? '').trim());
              return year == null || year < 1 || year > 9999
                  ? 'Ingresa un año válido'
                  : null;
            },
            onChanged: (value) => _year = int.tryParse(value.trim()) ?? 0,
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: _name,
            textCapitalization: TextCapitalization.words,
            decoration: const InputDecoration(
              labelText: 'Persona que recibe la contabilidad',
              border: OutlineInputBorder(),
            ),
            validator: (value) =>
                (value ?? '').trim().isEmpty ? 'Ingresa el nombre' : null,
          ),
        ],
      ),
    ),
    actions: [
      TextButton(
        onPressed: () => Navigator.pop(context),
        child: const Text('Cancelar'),
      ),
      FilledButton(
        onPressed: () {
          if (_form.currentState!.validate()) {
            Navigator.pop(context, (
              mes: _month,
              anio: _year,
              encargado: _name.text.trim(),
            ));
          }
        },
        child: const Text('Guardar'),
      ),
    ],
  );
}
