import 'dart:convert';

class NotificationRouteMapper {
  NotificationRouteMapper._();

  static String? routeFor(Map<String, dynamic> data) {
    final route = data['route']?.toString();
    if (route == null || route.isEmpty) return null;

    if (route.contains('/brand/application-details/')) {
      final id = _paramId(data) ?? _extractId(route);
      return id == null ? null : '/brand/application/$id';
    }
    if (route.contains('/brand/collaboration-details/')) {
      final id = _paramId(data) ?? _extractId(route);
      return id == null ? null : '/brand/collaboration/$id';
    }
    if (route.contains('/creator/collaboration-details/')) {
      final id = _paramId(data) ?? _extractId(route);
      return id == null ? null : '/creator/collaboration/$id';
    }
    if (route == '/creator/applications') return route;
    if (route == '/brand/announcements') return route;

    return route;
  }

  static String? _extractId(String route) {
    final match = RegExp(r'/(\d+)(?:\?|$)').firstMatch(route);
    return match?.group(1);
  }

  static String? _paramId(Map<String, dynamic> data) {
    final params = data['params'];
    if (params is Map) return params['id']?.toString();
    if (params is String && params.isNotEmpty) {
      try {
        final decoded = jsonDecode(params);
        if (decoded is Map) return decoded['id']?.toString();
      } catch (_) {}
    }
    return null;
  }
}
