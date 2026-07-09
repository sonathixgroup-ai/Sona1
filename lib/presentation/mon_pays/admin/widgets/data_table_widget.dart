// lib/presentation/mon_pays/admin/widgets/data_table_widget.dart

import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';

class DataColumnConfig {
  final String label;
  final double? width;
  final bool numeric;

  DataColumnConfig({
    required this.label,
    this.width,
    this.numeric = false,
  });
}

class DataTableWidget<T> extends StatelessWidget {
  final List<T> items;
  final List<DataColumnConfig> columns;
  final List<Widget> Function(T item) cellBuilder;
  final void Function(T item)? onEdit;
  final void Function(T item)? onDelete;
  final void Function(T item)? onTap;
  final bool isLoading;
  final String emptyMessage;

  const DataTableWidget({
    Key? key,
    required this.items,
    required this.columns,
    required this.cellBuilder,
    this.onEdit,
    this.onDelete,
    this.onTap,
    this.isLoading = false,
    this.emptyMessage = 'Aucune donnée disponible',
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (items.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.inbox, size: 64, color: AppColors.textHint),
            const SizedBox(height: 16),
            Text(
              emptyMessage,
              style: AppTextStyles.bodyMedium.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
      );
    }

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      margin: const EdgeInsets.all(16),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: DataTable(
          headingRowColor: MaterialStateProperty.resolveWith<Color?>(
            (states) => AppColors.backgroundLight,
          ),
          columnSpacing: 20,
          horizontalMargin: 16,
          columns: [
            ...columns.map((col) => DataColumn(
                  label: Text(
                    col.label,
                    style: AppTextStyles.bodySmall.copyWith(
                      fontWeight: FontWeight.bold,
                      color: AppColors.primaryBlue,
                    ),
                  ),
                  numeric: col.numeric,
                )),
            if (onEdit != null || onDelete != null)
              const DataColumn(
                label: Text(
                  'Actions',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
          ],
          rows: items.map((item) {
            final cells = cellBuilder(item);
            final dataCells = cells.map((widget) => DataCell(widget)).toList();
            if (onEdit != null || onDelete != null) {
              dataCells.add(
                DataCell(
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (onEdit != null)
                        IconButton(
                          icon: const Icon(Icons.edit, color: AppColors.primaryBlue),
                          onPressed: () => onEdit!(item),
                          tooltip: 'Modifier',
                          iconSize: 20,
                        ),
                      if (onDelete != null)
                        IconButton(
                          icon: const Icon(Icons.delete, color: AppColors.primaryRed),
                          onPressed: () => onDelete!(item),
                          tooltip: 'Supprimer',
                          iconSize: 20,
                        ),
                    ],
                  ),
                ),
              );
            }
            return DataRow(
              onSelectChanged: onTap != null ? (_) => onTap!(item) : null,
              cells: dataCells,
            );
          }).toList(),
        ),
      ),
    );
  }
}
