/// Offset pagination for bounded mobile lists. Stable order must include id.
class PageRequest {
  final int offset;
  final int size;
  const PageRequest({this.offset = 0, this.size = 30});
  void validate() {
    if (offset < 0 || size < 1 || size > 100) {
      throw ArgumentError('offset >= 0; size between 1 and 100');
    }
  }

  int get end => offset + size - 1;
}
