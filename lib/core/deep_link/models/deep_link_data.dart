/// Represents parsed deep link data
class DeepLinkData {
  final DeepLinkType type;
  final String? id;
  final Map<String, String> queryParams;
  final String rawUrl;
  final DeepLinkSource source;

  DeepLinkData({
    required this.type,
    this.id,
    this.queryParams = const {},
    required this.rawUrl,
    required this.source,
  });

  bool get hasValidId => id != null && id!.isNotEmpty;

  @override
  String toString() {
    return 'DeepLinkData(type: $type, id: $id, params: $queryParams, source: $source)';
  }
}

enum DeepLinkType {
  student,
  teacher,
  payment,
  announcement,
  event,
  attendance,
  grade,
  course,
  classInfo,
  invoice,
  receipt,
  staff,
  notification,
  profile,
  settings,
  unknown,
}

enum DeepLinkSource {
  coldStart,
  background,
  foreground,
}
