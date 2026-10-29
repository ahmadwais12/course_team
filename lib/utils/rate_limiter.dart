import 'dart:collection';

class RateLimiter {
  static final instance = RateLimiter._();
  RateLimiter._();

  final _requests = <String, Queue<DateTime>>{};
  final _limits = <String, RateLimit>{};

  // Set rate limit for an endpoint
  void setLimit(String endpoint, {required int maxRequests, required Duration window}) {
    _limits[endpoint] = RateLimit(maxRequests, window);
  }

  // Check if request is allowed
  bool isAllowed(String endpoint, {String? userId}) {
    final key = userId != null ? '$endpoint:$userId' : endpoint;
    final limit = _limits[endpoint];
    
    if (limit == null) return true;

    final now = DateTime.now();
    final queue = _requests.putIfAbsent(key, () => Queue<DateTime>());

    // Remove expired requests
    while (queue.isNotEmpty && now.difference(queue.first) > limit.window) {
      queue.removeFirst();
    }

    // Check if limit exceeded
    if (queue.length >= limit.maxRequests) {
      return false;
    }

    queue.add(now);
    return true;
  }

  // Get remaining requests
  int getRemainingRequests(String endpoint, {String? userId}) {
    final key = userId != null ? '$endpoint:$userId' : endpoint;
    final limit = _limits[endpoint];
    
    if (limit == null) return -1;

    final queue = _requests[key];
    if (queue == null) return limit.maxRequests;

    final now = DateTime.now();
    final validRequests = queue.where((time) => now.difference(time) <= limit.window).length;
    
    return limit.maxRequests - validRequests;
  }

  // Reset limits for endpoint
  void reset(String endpoint, {String? userId}) {
    final key = userId != null ? '$endpoint:$userId' : endpoint;
    _requests.remove(key);
  }

  // Clear all limits
  void clearAll() {
    _requests.clear();
  }
}

class RateLimit {
  final int maxRequests;
  final Duration window;

  RateLimit(this.maxRequests, this.window);
}

// Middleware for rate limiting
class RateLimitMiddleware {
  static Future<T> execute<T>(
    String endpoint,
    Future<T> Function() request, {
    String? userId,
  }) async {
    if (!RateLimiter.instance.isAllowed(endpoint, userId: userId)) {
      throw RateLimitException('Rate limit exceeded for $endpoint');
    }

    return await request();
  }
}

class RateLimitException implements Exception {
  final String message;
  RateLimitException(this.message);

  @override
  String toString() => message;
}
