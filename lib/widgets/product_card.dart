import 'dart:io';

import 'package:flutter/material.dart';

import '../models/product_model.dart';

class ProductCard extends StatelessWidget {
  final ProductModel producto;
  final VoidCallback onTap;

  const ProductCard({super.key, required this.producto, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Card(
      clipBehavior: Clip.antiAlias,
      elevation: 0,
      color: colors.surfaceContainerLow,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
        side: BorderSide(color: colors.outlineVariant),
      ),
      child: InkWell(
        onTap: onTap,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // IMAGEN DEL PRODUCTO
            Expanded(
              child: SizedBox(
                width: double.infinity,
                child: _imagenProducto(colors),
              ),
            ),

            // INFORMACIÓN
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    producto.nombre,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    '\$${producto.precioVenta.toStringAsFixed(2)}',
                    style: TextStyle(
                      color: colors.primary,
                      fontWeight: FontWeight.bold,
                      fontSize: 17,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _imagenProducto(ColorScheme colors) {
    final ruta = producto.imagenPath;

    if (ruta == null || ruta.isEmpty) {
      return _sinImagen(colors);
    }

    return Image.file(
      File(ruta),
      fit: BoxFit.cover,
      errorBuilder: (context, error, stackTrace) {
        return _sinImagen(colors);
      },
    );
  }

  Widget _sinImagen(ColorScheme colors) {
    return Container(
      color: colors.surfaceContainerHighest,
      child: Center(
        child: Icon(
          Icons.inventory_2_outlined,
          size: 50,
          color: colors.onSurfaceVariant,
        ),
      ),
    );
  }
}
