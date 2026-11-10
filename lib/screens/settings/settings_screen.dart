import 'package:flutter/material.dart';
import '../../widgets/bento.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Ajustes')),
    body: ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const BentoHeader(
          eyebrow: 'Tu espacio',
          title: 'Configuración',
          subtitle: 'Personaliza tu experiencia de trabajo.',
          icon: Icons.tune_rounded,
        ),
        const SizedBox(height: 24),
        BentoGrid(
          items: [
            BentoItem(
              BentoTile(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      Icons.palette_outlined,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                    const SizedBox(height: 18),
                    Text(
                      'Apariencia',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 5),
                    const Text('Sigue el tema del dispositivo'),
                  ],
                ),
              ),
            ),
            BentoItem(
              BentoTile(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      Icons.tune_rounded,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                    const SizedBox(height: 18),
                    Text(
                      'Preferencias',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 5),
                    const Text('Próximamente'),
                  ],
                ),
              ),
            ),
            BentoItem(
              BentoTile(
                child: Row(
                  children: [
                    Icon(
                      Icons.settings_outlined,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                    const SizedBox(width: 14),
                    const Expanded(
                      child: Text('Vista de Configuración pendiente'),
                    ),
                  ],
                ),
              ),
              span: 2,
            ),
          ],
        ),
      ],
    ),
  );
}
