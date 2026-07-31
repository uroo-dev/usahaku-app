import 'dart:io';

import 'package:flutter/material.dart';
import 'package:usahaku/models/product_model.dart';
import 'package:usahaku/theme/app_theme.dart';
import 'package:usahaku/utils/format_util.dart';

/// Kartu produk sesuai template produk.html.
class ProductCard extends StatelessWidget {
  final ProductModel product;
  final VoidCallback? onTap;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;

  const ProductCard({super.key, required this.product, this.onTap, this.onEdit, this.onDelete});

  @override
  Widget build(BuildContext context) {
    final outOfStock = product.isOutOfStock;
    final lowStock = product.isLowStock && !outOfStock;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: outOfStock
              ? AppColor.surfaceContainerLow.withValues(alpha: 0.6)
              : AppColor.surfaceContainerLowest,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppColor.outlineVariant.withValues(alpha: 0.3)),
          boxShadow: [
            BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 4, offset: const Offset(0, 2)),
          ],
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Container(
                width: 72,
                height: 72,
                color: AppColor.surfaceContainer,
                child: product.imagePath != null && product.imagePath!.isNotEmpty
                    ? Image.file(File(product.imagePath!), fit: BoxFit.cover)
                    : const Icon(Icons.inventory_2, color: AppColor.primary, size: 28),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Text(
                          product.name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: AppColor.onSurface),
                        ),
                      ),
                      if (onEdit != null)
                        IconButton(
                          visualDensity: VisualDensity.compact,
                          icon: const Icon(Icons.edit_outlined, size: 18, color: AppColor.onSurfaceVariant),
                          onPressed: onEdit,
                        ),
                      if (onDelete != null)
                        IconButton(
                          visualDensity: VisualDensity.compact,
                          icon: const Icon(Icons.delete_outline, size: 18, color: AppColor.error),
                          onPressed: onDelete,
                        ),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    product.categoryName,
                    style: const TextStyle(fontSize: 12, color: AppColor.onSurfaceVariant),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'HARGA JUAL',
                            style: TextStyle(fontSize: 10, color: AppColor.outline, fontWeight: FontWeight.w700, letterSpacing: 0.5),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            FormatUtil.rupiah(product.sellPrice),
                            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: AppColor.primary),
                          ),
                          Text(
                            'Modal: ${FormatUtil.rupiah(product.purchasePrice)}',
                            style: const TextStyle(fontSize: 11, color: AppColor.onSurfaceVariant),
                          ),
                        ],
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                            decoration: BoxDecoration(
                              color: outOfStock
                                  ? AppColor.errorContainer
                                  : lowStock
                                      ? AppColor.tertiaryContainer
                                      : AppColor.secondaryContainer.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(999),
                            ),
                            child: Text(
                              product.statusLabel.toUpperCase(),
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                                color: outOfStock
                                    ? AppColor.error
                                    : lowStock
                                        ? AppColor.onTertiary
                                        : AppColor.secondary,
                              ),
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text.rich(
                            TextSpan(
                              children: [
                                const TextSpan(text: 'Stok: '),
                                TextSpan(
                                  text: '${product.stock}',
                                  style: TextStyle(
                                    color: outOfStock
                                        ? AppColor.error
                                        : lowStock
                                            ? AppColor.tertiary
                                            : AppColor.primary,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ],
                            ),
                            style: const TextStyle(fontSize: 13, color: AppColor.onSurface),
                          ),
                          Text(
                            'Min: ${product.minStock}',
                            style: const TextStyle(fontSize: 11, color: AppColor.outline),
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
