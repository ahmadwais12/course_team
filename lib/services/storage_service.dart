import 'package:hive_flutter/hive_flutter.dart';

class StorageService {
  static final StorageService instance = StorageService._();
  StorageService._();

  late Box _box;

  Future<void> init() async {
    await Hive.initFlutter();
    _box = await Hive.openBox('dreamflow_cache');
  }

  Future<void> save(String key, dynamic value) async => await _box.put(key, value);
  
  T? get<T>(String key) => _box.get(key) as T?;
  
  Future<void> delete(String key) async => await _box.delete(key);
  
  Future<void> clear() async => await _box.clear();

  // Offline cache
  Future<void> cacheData(String module, List<Map<String, dynamic>> data) async {
    await save('${module}_cache', data);
    await save('${module}_timestamp', DateTime.now().toIso8601String());
  }

  List<Map<String, dynamic>>? getCachedData(String module) {
    final data = get<List>('${module}_cache');
    return data?.cast<Map<String, dynamic>>();
  }

  bool isCacheValid(String module, {Duration maxAge = const Duration(hours: 1)}) {
    final timestamp = get<String>('${module}_timestamp');
    if (timestamp == null) return false;
    final cacheTime = DateTime.parse(timestamp);
    return DateTime.now().difference(cacheTime) < maxAge;
  }
}
