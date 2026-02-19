import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class CacheService {
  static Future<void> cache(String key, dynamic data) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('cache_$key', jsonEncode({
      'data': data,
      'timestamp': DateTime.now().toIso8601String(),
    }));
  }

  static Future<T?> getCached<T>(String key, {Duration maxAge = const Duration(hours: 1)}) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString('cache_$key');
    if (raw == null) return null;
    final parsed = jsonDecode(raw);
    final ts = DateTime.parse(parsed['timestamp']);
    if (DateTime.now().difference(ts) > maxAge) return null;
    return parsed['data'] as T;
  }

  static Future<void> queueAction(Map<String, dynamic> action) async {
    final prefs = await SharedPreferences.getInstance();
    final queue = prefs.getStringList('offline_queue') ?? [];
    queue.add(jsonEncode(action));
    await prefs.setStringList('offline_queue', queue);
  }

  static Future<List<Map<String, dynamic>>> getQueue() async {
    final prefs = await SharedPreferences.getInstance();
    final queue = prefs.getStringList('offline_queue') ?? [];
    return queue.map((e) => jsonDecode(e) as Map<String, dynamic>).toList();
  }

  static Future<void> clearQueue() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('offline_queue');
  }
}
