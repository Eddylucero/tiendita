import 'package:flutter/material.dart';

class BentoTile extends StatefulWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  final VoidCallback? onTap;
  final bool featured;

  const BentoTile({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(18),
    this.onTap,
    this.featured = false,
  });

  @override
  State<BentoTile> createState() => _BentoTileState();
}

class _BentoTileState extends State<BentoTile> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final duration = MediaQuery.disableAnimationsOf(context)
        ? Duration.zero
        : const Duration(milliseconds: 170);
    final background = widget.featured
        ? colors.primaryContainer
        : colors.surfaceContainerLow;
    return AnimatedScale(
      scale: _pressed ? 0.985 : 1,
      duration: duration,
      curve: Curves.easeOutCubic,
      child: AnimatedContainer(
        duration: duration,
        decoration: BoxDecoration(
          color: background,
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: colors.outlineVariant),
        ),
        child: Material(
          color: background,
          borderRadius: BorderRadius.circular(22),
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: widget.onTap,
            onHighlightChanged: widget.onTap == null
                ? null
                : (value) {
                    setState(() => _pressed = value);
                  },
            child: Padding(padding: widget.padding, child: widget.child),
          ),
        ),
      ),
    );
  }
}

class BentoHeader extends StatelessWidget {
  final String eyebrow;
  final String title;
  final String subtitle;
  final IconData icon;

  const BentoHeader({
    super.key,
    required this.eyebrow,
    required this.title,
    required this.subtitle,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return BentoTile(
      featured: true,
      padding: const EdgeInsets.all(22),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  eyebrow.toUpperCase(),
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: colors.primary,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1.4,
                  ),
                ),
                const SizedBox(height: 14),
                Text(
                  title,
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    color: colors.onPrimaryContainer,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  subtitle,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: colors.onPrimaryContainer,
                    height: 1.35,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: colors.surfaceContainerLow,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(icon, color: colors.primary, size: 25),
          ),
        ],
      ),
    );
  }
}

class BentoItem {
  final Widget child;
  final int span;
  const BentoItem(this.child, {this.span = 1});
}

class BentoGrid extends StatelessWidget {
  final List<BentoItem> items;
  final double spacing;
  const BentoGrid({super.key, required this.items, this.spacing = 12});

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) {
      final twoColumns = constraints.maxWidth >= 340;
      final half = (constraints.maxWidth - spacing) / 2;
      return Wrap(
        spacing: spacing,
        runSpacing: spacing,
        children: items
            .map(
              (item) => SizedBox(
                width: twoColumns && item.span == 1
                    ? half
                    : constraints.maxWidth,
                child: item.child,
              ),
            )
            .toList(),
      );
    },
  );
}
