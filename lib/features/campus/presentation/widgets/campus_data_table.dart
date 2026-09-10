import 'package:flutter/material.dart';

import '../theme/campus_theme_tokens.dart';

class CampusColumn {
  final String title;
  final double? width;
  final int flex;
  final Alignment alignment;

  const CampusColumn({
    required this.title,
    this.width,
    this.flex = 1,
    this.alignment = Alignment.centerLeft,
  });
}

class CampusDataTable extends StatelessWidget {
  final List<CampusColumn> columns;
  final int rowCount;
  final Widget Function(BuildContext context, int index) rowBuilder;
  final Widget? emptyWidget;

  const CampusDataTable({
    super.key,
    required this.columns,
    required this.rowCount,
    required this.rowBuilder,
    this.emptyWidget,
  });

  @override
  Widget build(BuildContext context) {
    if (rowCount == 0 && emptyWidget != null) {
      return emptyWidget!;
    }

    return Container(
      decoration: BoxDecoration(
        color: CampusTokens.campusSurface,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: CampusTokens.campusDivider),
        boxShadow: CampusTokens.subtleCardShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header Row
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
            decoration: const BoxDecoration(
              color: CampusTokens.campusSurfaceSubtle,
              borderRadius: BorderRadius.vertical(top: Radius.circular(9)),
              border: Border(
                bottom: BorderSide(color: CampusTokens.campusDivider, width: 1),
              ),
            ),
            child: Row(
              children: columns.map((col) {
                final text = Text(
                  col.title.toUpperCase(),
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.8,
                    color: CampusTokens.campusGraphiteSecondary,
                  ),
                );
                if (col.width != null) {
                  return SizedBox(
                    width: col.width,
                    child: Align(alignment: col.alignment, child: text),
                  );
                }
                return Expanded(
                  flex: col.flex,
                  child: Align(alignment: col.alignment, child: text),
                );
              }).toList(),
            ),
          ),
          // Data Rows
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: rowCount,
            separatorBuilder: (context, index) =>
                const Divider(color: CampusTokens.campusDivider, height: 1),
            itemBuilder: (context, index) {
              return Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 14,
                ),
                child: rowBuilder(context, index),
              );
            },
          ),
        ],
      ),
    );
  }
}
