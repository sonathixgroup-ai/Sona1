// lib/presentation/thix_event/admin/providers/admin_state.dart
enum AdminStatus { initial, loading, loadingMore, success, empty, error }

class AdminPaginatedState<T> {
  final List<T> items;
  final AdminStatus status;
  final String? error;
  final bool hasMore;
  final int currentPage;

  const AdminPaginatedState({
    this.items = const [],
    this.status = AdminStatus.initial,
    this.error,
    this.hasMore = true,
    this.currentPage = 0,
  });

  AdminPaginatedState<T> copyWith({
    List<T>? items,
    AdminStatus? status,
    String? error,
    bool? hasMore,
    int? currentPage,
  }) {
    return AdminPaginatedState(
      items: items?? this.items,
      status: status?? this.status,
      error: error?? this.error,
      hasMore: hasMore?? this.hasMore,
      currentPage: currentPage?? this.currentPage,
    );
  }

  bool get isLoading => status == AdminStatus.loading;
  bool get isLoadingMore => status == AdminStatus.loadingMore;
  bool get isEmpty => items.isEmpty && status == AdminStatus.success;
}
