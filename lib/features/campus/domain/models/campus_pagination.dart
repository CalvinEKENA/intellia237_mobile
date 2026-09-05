/// Generic pagination and cursor contract for large institutional collections.
class CampusPage<T> {
  final List<T> items;
  final int totalCount;
  final int pageIndex;
  final int pageSize;

  const CampusPage({
    required this.items,
    required this.totalCount,
    required this.pageIndex,
    required this.pageSize,
  });

  bool get hasNextPage => (pageIndex * pageSize) < totalCount;
  bool get hasPreviousPage => pageIndex > 1;
  int get totalPages => (totalCount / pageSize).ceil();

  static CampusPage<T> empty<T>() =>
      CampusPage<T>(items: const [], totalCount: 0, pageIndex: 1, pageSize: 20);
}
