import 'package:flutter/material.dart';
import 'package:citesched_flutter/core/theme/design_system.dart';

/// Standard Table Component
/// Formal table design with:
/// - White background
/// - Black bold headers
/// - Black bottom borders on header
/// - Thin black row separators
/// - Full black outline
class StandardTable extends StatelessWidget {
  final List<String> headers;
  final List<List<Widget>> rows;
  final List<Widget>? actions;
  final double columnWidth;
  final Color? hoverColor;

  const StandardTable({
    Key? key,
    required this.headers,
    required this.rows,
    this.actions,
    this.columnWidth = 150,
    this.hoverColor,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(
          color: DesignSystem.borderColor,
          width: 1,
        ),
        borderRadius: BorderRadius.circular(DesignSystem.borderRadiusSmall),
      ),
      clipBehavior: Clip.hardEdge,
      child: Column(
        children: [
          // Header Row
          Container(
            color: DesignSystem.backgroundColor,
            child: Row(
              children: headers
                  .asMap()
                  .entries
                  .map(
                    (entry) => Expanded(
                      child: Container(
                        padding: const EdgeInsets.all(DesignSystem.spacing12),
                        decoration: BoxDecoration(
                          color: DesignSystem.backgroundColor,
                          border: Border(
                            right: entry.key < headers.length - 1
                                ? const BorderSide(
                                    color: DesignSystem.borderColor,
                                    width: 1,
                                  )
                                : BorderSide.none,
                            bottom: const BorderSide(
                              color: DesignSystem.borderColor,
                              width: 2,
                            ),
                          ),
                        ),
                        child: Text(
                          entry.value,
                          style: DesignSystem.tableHeaderText,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ),
                  )
                  .toList(),
            ),
          ),

          // Data Rows
          ...rows.asMap().entries.map(
            (entry) {
              final rowIndex = entry.key;
              final rowCells = entry.value;
              final isLastRow = rowIndex == rows.length - 1;

              return Container(
                color: DesignSystem.backgroundColor,
                child: Row(
                  children: rowCells.asMap().entries.map(
                    (cellEntry) {
                      final cellIndex = cellEntry.key;
                      final cell = cellEntry.value;

                      return Expanded(
                        child: Container(
                          padding: const EdgeInsets.all(DesignSystem.spacing12),
                          decoration: BoxDecoration(
                            color: DesignSystem.backgroundColor,
                            border: Border(
                              right: cellIndex < rowCells.length - 1
                                  ? const BorderSide(
                                      color: DesignSystem.borderColor,
                                      width: 1,
                                    )
                                  : BorderSide.none,
                              bottom: !isLastRow
                                  ? const BorderSide(
                                      color: DesignSystem.borderColor,
                                      width: 1,
                                    )
                                  : BorderSide.none,
                            ),
                          ),
                          child: cell,
                        ),
                      );
                    },
                  ).toList(),
                ),
              );
            },
          ).toList(),
        ],
      ),
    );
  }
}

/// Table Row Component
/// For easier table creation with uniform styling
class TableRowData {
  final List<Widget> cells;
  final EdgeInsetsGeometry? padding;

  TableRowData({
    required this.cells,
    this.padding,
  });
}

/// Table Cell Text Component
/// Standard formatted text for table cells
class TableCell extends StatelessWidget {
  final String text;
  final TextAlign textAlign;
  final int? maxLines;

  const TableCell({
    Key? key,
    required this.text,
    this.textAlign = TextAlign.left,
    this.maxLines,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: DesignSystem.tableBodyText,
      textAlign: textAlign,
      maxLines: maxLines,
      overflow: TextOverflow.ellipsis,
    );
  }
}

/// Table Action Button Component
/// Standard button for table actions (Edit, Delete, etc.)
class TableActionButton extends StatelessWidget {
  final String label;
  final VoidCallback onPressed;
  final bool isPrimary;
  final double? width;

  const TableActionButton({
    Key? key,
    required this.label,
    required this.onPressed,
    this.isPrimary = true,
    this.width = 80,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width,
      height: 32,
      child: isPrimary
          ? ElevatedButton(
              onPressed: onPressed,
              style: ElevatedButton.styleFrom(
                backgroundColor: DesignSystem.headerColor,
                foregroundColor: Colors.white,
                elevation: 0,
                padding: const EdgeInsets.symmetric(
                  horizontal: DesignSystem.spacing8,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(
                    DesignSystem.borderRadiusSmall,
                  ),
                  side: const BorderSide(
                    color: DesignSystem.borderColor,
                    width: 1,
                  ),
                ),
              ),
              child: Text(
                label,
                style: const TextStyle(fontSize: 12),
              ),
            )
          : OutlinedButton(
              onPressed: onPressed,
              style: OutlinedButton.styleFrom(
                foregroundColor: DesignSystem.textColor,
                side: const BorderSide(
                  color: DesignSystem.borderColor,
                  width: 1,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(
                    DesignSystem.borderRadiusSmall,
                  ),
                ),
                padding: const EdgeInsets.symmetric(
                  horizontal: DesignSystem.spacing8,
                ),
              ),
              child: Text(
                label,
                style: const TextStyle(fontSize: 12),
              ),
            ),
    );
  }
}
