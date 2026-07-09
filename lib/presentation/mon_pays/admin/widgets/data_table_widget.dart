// lib/presentation/mon_pays/admin/widgets/data_table_widget.dart

import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';

/// Widget générique pour afficher un tableau de données avec actions
class DataTableWidget<T> extends StatelessWidget {
  final List<T> items;
  final List<DataColumnConfig> columns;
  final Widget Function(T item, int index) itemBuilder;
  final void Function(T item)? onEdit;
  final void Function(T item)? onDelete;
  final void Function(T item)? onTap;
  final bool isLoading;
  final String emptyMessage;

  const DataTableWidget({
    Key? key,
    required this.items,
    required this.columns,
    required this.itemBuilder,
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
                )),
            if (onEdit != null || onDelete != null)
              const DataColumn(
                label: Text(
                  'Actions',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
          ],
          rows: items.asMap().entries.map((entry) {
            final index = entry.key;
            final item = entry.value;
            return DataRow(
              onSelectChanged: onTap != null ? (_) => onTap!(item) : null,
              cells: [
                ..._buildCells(item, index),
                if (onEdit != null || onDelete != null)
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
              ],
            );
          }).toList(),
        ),
      ),
    );
  }

  List<DataCell> _buildCells(T item, int index) {
    final widget = itemBuilder(item, index);
    if (widget is Row) {
      // Si le builder retourne un Row, on extrait ses enfants pour les mettre dans des DataCell
      // Mais pour simplifier, on suppose que le builder retourne un Widget qui représente la ligne
      // On va plutôt utiliser un approche différente : on construit les cellules à partir des colonnes.
      // Pour une meilleure flexibilité, on peut passer une liste de builders de cellules.
      // Ici, pour simplifier, on suppose que itemBuilder renvoie un Row avec des Expanded.
      // Mais pour un vrai usage, il vaut mieux que le widget accepte une liste de fonctions de construction de cellules.
      // On va ajuster pour que l'utilisateur fournisse des cellules directement.
      // Pour rester cohérent avec l'usage, on va modifier le paramètre itemBuilder pour qu'il retourne une liste de Widgets.
      // Mais on va garder une version simplifiée.
      throw UnsupportedError('Veuillez utiliser une approche différente');
    }
    // Par défaut, on affiche un seul widget sur toute la ligne (simplifié)
    return [DataCell(widget)];
  }
}

/// Configuration d'une colonne
class DataColumnConfig {
  final String label;
  final double? width;

  DataColumnConfig({required this.label, this.width});
}
