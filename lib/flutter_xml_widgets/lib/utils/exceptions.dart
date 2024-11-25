/// Custom exception for unregistered widget tags
class UnknownWidgetException implements Exception {
  final String tag;

  UnknownWidgetException(this.tag);

  @override
  String toString() {
    return 'UnknownWidgetException: The widget tag "$tag" is not registered in the WidgetRegistry.';
  }
}
