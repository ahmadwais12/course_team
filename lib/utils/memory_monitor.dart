import 'package:flutter/foundation.dart';
import 'dart:developer' as developer;

class MemoryMonitor {
  static final instance = MemoryMonitor._();
  MemoryMonitor._();

  final _allocations = <String, int>{};
  bool _isMonitoring = false;

  void startMonitoring() {
    if (_isMonitoring) return;
    _isMonitoring = true;
    
    if (kDebugMode) {
      developer.log('Memory monitoring started');
    }
  }

  void stopMonitoring() {
    _isMonitoring = false;
    if (kDebugMode) {
      developer.log('Memory monitoring stopped');
    }
  }

  void trackAllocation(String key) {
    if (!_isMonitoring) return;
    _allocations[key] = (_allocations[key] ?? 0) + 1;
  }

  void trackDeallocation(String key) {
    if (!_isMonitoring) return;
    if (_allocations.containsKey(key)) {
      _allocations[key] = _allocations[key]! - 1;
      if (_allocations[key]! <= 0) {
        _allocations.remove(key);
      }
    }
  }

  Map<String, int> getLeaks() {
    final leaks = <String, int>{};
    _allocations.forEach((key, value) {
      if (value > 0) {
        leaks[key] = value;
      }
    });
    return leaks;
  }

  void printReport() {
    if (kDebugMode) {
      developer.log('=== Memory Report ===');
      final leaks = getLeaks();
      if (leaks.isEmpty) {
        developer.log('No memory leaks detected');
      } else {
        leaks.forEach((key, count) {
          developer.log('$key: $count allocations');
        });
      }
    }
  }

  void reset() {
    _allocations.clear();
  }
}

// Mixin for automatic tracking
mixin MemoryTrackable {
  void onMemoryAllocate() {
    MemoryMonitor.instance.trackAllocation(runtimeType.toString());
  }

  void onMemoryDeallocate() {
    MemoryMonitor.instance.trackDeallocation(runtimeType.toString());
  }
}
