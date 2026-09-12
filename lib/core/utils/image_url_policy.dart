String? safeProductImageUrl(String? rawUrl) {
  final value = rawUrl?.trim() ?? '';
  if (value.isEmpty) return null;

  final uri = Uri.tryParse(value);
  if (uri == null || uri.scheme.toLowerCase() != 'https') return null;
  if (uri.host.isEmpty || uri.userInfo.isNotEmpty) return null;
  return value;
}
