import 'package:flutter/material.dart';
import '../theme/studio_theme.dart';

class StudioTableColumn<T> {
  const StudioTableColumn({
    required this.header,
    required this.cellBuilder,
    this.flex = 1,
    this.width,
    this.isSortable = false,
    this.comparator,
  });

  final String header;
  final Widget Function(T item) cellBuilder;
  final int flex;
  final double? width;
  final bool isSortable;
  final int Function(T a, T b)? comparator;
}

class StudioDataTable<T> extends StatefulWidget {
  const StudioDataTable({
    super.key,
    required this.columns,
    required this.items,
    this.isLoading = false,
    this.emptyMessage = 'Aucune donnée disponible.',
    this.onRowTap,
    this.searchHint = 'Rechercher...',
    this.filterPredicate,
    this.actionsBuilder,
    this.itemsPerPage = 15,
  });

  final List<StudioTableColumn<T>> columns;
  final List<T> items;
  final bool isLoading;
  final String emptyMessage;
  final void Function(T item)? onRowTap;
  final String searchHint;
  final bool Function(T item, String query)? filterPredicate;
  final Widget Function(T item)? actionsBuilder;
  final int itemsPerPage;

  @override
  State<StudioDataTable<T>> createState() => _StudioDataTableState<T>();
}

class _StudioDataTableState<T> extends State<StudioDataTable<T>> {
  final _searchController = TextEditingController();
  int? _sortColumnIndex;
  bool _sortAscending = true;
  int _currentPage = 0;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<T> get _filteredAndSortedItems {
    final query = _searchController.text.trim().toLowerCase();
    var list = widget.items.where((item) {
      if (query.isEmpty || widget.filterPredicate == null) return true;
      return widget.filterPredicate!(item, query);
    }).toList();

    if (_sortColumnIndex != null && _sortColumnIndex! < widget.columns.length) {
      final col = widget.columns[_sortColumnIndex!];
      if (col.comparator != null) {
        list.sort((a, b) {
          final res = col.comparator!(a, b);
          return _sortAscending ? res : -res;
        });
      }
    }
    return list;
  }

  @override
  Widget build(BuildContext context) {
    final displayItems = _filteredAndSortedItems;
    final totalPages = (displayItems.length / widget.itemsPerPage).ceil().clamp(
      1,
      9999,
    );
    final startIndex = _currentPage * widget.itemsPerPage;
    final pageItems = displayItems
        .skip(startIndex)
        .take(widget.itemsPerPage)
        .toList();

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: StudioColors.borderLight),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Filter & Search bar
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: const BoxDecoration(
              border: Border(
                bottom: BorderSide(color: StudioColors.borderLight),
              ),
            ),
            child: Row(
              children: [
                SizedBox(
                  width: 320,
                  height: 38,
                  child: TextField(
                    controller: _searchController,
                    decoration: InputDecoration(
                      hintText: widget.searchHint,
                      prefixIcon: const Icon(Icons.search_rounded, size: 18),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 12,
                      ),
                    ),
                    onChanged: (_) => setState(() => _currentPage = 0),
                  ),
                ),
                const Spacer(),
                Text(
                  '${displayItems.length} élément(s)',
                  style: const TextStyle(
                    fontSize: 12,
                    color: StudioColors.textSecondaryLight,
                  ),
                ),
              ],
            ),
          ),

          // Table Header
          Container(
            height: 44,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            decoration: const BoxDecoration(
              color: StudioColors.backgroundLight,
              border: Border(
                bottom: BorderSide(color: StudioColors.borderLight),
              ),
            ),
            child: Row(
              children: [
                for (var i = 0; i < widget.columns.length; i++) ...[
                  _buildHeaderCell(widget.columns[i], i),
                ],
                if (widget.actionsBuilder != null)
                  const SizedBox(
                    width: 100,
                    child: Text(
                      'Actions',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: StudioColors.navyPrimary,
                      ),
                    ),
                  ),
              ],
            ),
          ),

          // Table Body
          Expanded(
            child: widget.isLoading
                ? const Center(child: CircularProgressIndicator())
                : displayItems.isEmpty
                ? Center(
                    child: Text(
                      widget.emptyMessage,
                      style: const TextStyle(
                        color: StudioColors.textSecondaryLight,
                      ),
                    ),
                  )
                : ListView.separated(
                    itemCount: pageItems.length,
                    separatorBuilder: (_, _) => const Divider(
                      height: 1,
                      color: StudioColors.borderLight,
                    ),
                    itemBuilder: (context, index) {
                      final item = pageItems[index];
                      return InkWell(
                        onTap: widget.onRowTap != null
                            ? () => widget.onRowTap!(item)
                            : null,
                        hoverColor: StudioColors.navyPrimary.withValues(
                          alpha: 0.03,
                        ),
                        child: Container(
                          height: 48,
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          child: Row(
                            children: [
                              for (final col in widget.columns) ...[
                                _buildCell(col, item),
                              ],
                              if (widget.actionsBuilder != null)
                                SizedBox(
                                  width: 100,
                                  child: widget.actionsBuilder!(item),
                                ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
          ),

          // Pagination Footer
          Container(
            height: 48,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            decoration: const BoxDecoration(
              border: Border(top: BorderSide(color: StudioColors.borderLight)),
            ),
            child: Row(
              children: [
                Text(
                  'Page ${_currentPage + 1} sur $totalPages',
                  style: const TextStyle(
                    fontSize: 12,
                    color: StudioColors.textSecondaryLight,
                  ),
                ),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.chevron_left_rounded),
                  onPressed: _currentPage > 0
                      ? () => setState(() => _currentPage--)
                      : null,
                ),
                IconButton(
                  icon: const Icon(Icons.chevron_right_rounded),
                  onPressed: _currentPage < totalPages - 1
                      ? () => setState(() => _currentPage++)
                      : null,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeaderCell(StudioTableColumn<T> col, int index) {
    final content = InkWell(
      onTap: col.isSortable
          ? () {
              setState(() {
                if (_sortColumnIndex == index) {
                  _sortAscending = !_sortAscending;
                } else {
                  _sortColumnIndex = index;
                  _sortAscending = true;
                }
              });
            }
          : null,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            col.header,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: StudioColors.navyPrimary,
            ),
          ),
          if (col.isSortable && _sortColumnIndex == index) ...[
            const SizedBox(width: 4),
            Icon(
              _sortAscending
                  ? Icons.arrow_upward_rounded
                  : Icons.arrow_downward_rounded,
              size: 14,
              color: StudioColors.navyPrimary,
            ),
          ],
        ],
      ),
    );

    if (col.width != null) {
      return SizedBox(width: col.width, child: content);
    }
    return Expanded(flex: col.flex, child: content);
  }

  Widget _buildCell(StudioTableColumn<T> col, T item) {
    if (col.width != null) {
      return SizedBox(width: col.width, child: col.cellBuilder(item));
    }
    return Expanded(flex: col.flex, child: col.cellBuilder(item));
  }
}
