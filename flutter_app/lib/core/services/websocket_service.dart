import 'dart:async';
import 'dart:convert';
import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

import 'api_service.dart';

enum WebSocketConnectionStatus {
  disconnected,
  connecting,
  connected,
  reconnecting,
}

class WebSocketService {
  static final WebSocketService _instance = WebSocketService._internal();
  factory WebSocketService() => _instance;
  WebSocketService._internal();

  WebSocketChannel? _channel;
  StreamSubscription? _subscription;
  Timer? _reconnectTimer;
  String? _socketId;
  String? _currentCollaborationSubscription;
  int _reconnectAttempts = 0;

  final Set<String> _pendingPrivateChannels = {};
  final Set<String> _subscribedChannels = {};
  final Map<String, int> _channelReferences = {};

  final _messageController = StreamController<Map<String, dynamic>>.broadcast();
  final _notificationController =
      StreamController<Map<String, dynamic>>.broadcast();
  final _readReceiptController =
      StreamController<Map<String, dynamic>>.broadcast();
  final _connectionStatusController =
      StreamController<WebSocketConnectionStatus>.broadcast();
  WebSocketConnectionStatus _connectionStatus =
      WebSocketConnectionStatus.disconnected;

  Stream<Map<String, dynamic>> get messages => _messageController.stream;
  Stream<Map<String, dynamic>> get notifications =>
      _notificationController.stream;
  Stream<Map<String, dynamic>> get readReceipts =>
      _readReceiptController.stream;
  Stream<WebSocketConnectionStatus> get connectionStatus =>
      _connectionStatusController.stream;

  Function(Map<String, dynamic>)? onMessageReceived;
  Function(Map<String, dynamic>)? onNotificationReceived;
  Function(Map<String, dynamic>)? onReadReceiptReceived;

  Future<void> init() async {
    if (_channel != null) return;
    _reconnectTimer?.cancel();
    _reconnectTimer = null;

    final host = dotenv.env['REVERB_HOST'] ?? '72.62.20.218';
    final port = int.tryParse(dotenv.env['REVERB_PORT'] ?? '8089') ?? 8089;
    final key = dotenv.env['REVERB_APP_KEY'] ?? 'm0g4g5qg8z7y6w5v4u3t';
    final scheme = dotenv.env['REVERB_SCHEME'] == 'https' ? 'wss' : 'ws';

    final uri = Uri(
      scheme: scheme,
      host: host,
      port: port,
      path: '/app/$key',
      queryParameters: {
        'protocol': '7',
        'client': 'flutter',
        'version': '1.0.0',
        'flash': 'false',
      },
    );

    try {
      _emitConnectionStatus(
        _reconnectAttempts > 0
            ? WebSocketConnectionStatus.reconnecting
            : WebSocketConnectionStatus.connecting,
      );
      debugPrint('WebSocket connecting to $uri');
      _channel = WebSocketChannel.connect(uri);
      _subscription = _channel!.stream.listen(
        _handleRawEvent,
        onError: (error) {
          debugPrint('WebSocket error: $error');
          _resetConnection();
        },
        onDone: () {
          debugPrint('WebSocket closed');
          _resetConnection();
        },
      );
    } catch (e) {
      debugPrint('WebSocket init error: $e');
      _resetConnection();
    }
  }

  Future<void> subscribeToCollaboration(int collaborationId) async {
    await init();

    final channelName = 'private-collaboration.$collaborationId';
    if (_currentCollaborationSubscription == channelName) return;

    if (_currentCollaborationSubscription != null) {
      await _unsubscribe(_currentCollaborationSubscription!);
    }

    _currentCollaborationSubscription = channelName;
    await _subscribePrivate(channelName);
  }

  Future<void> unsubscribeFromCollaboration() async {
    if (_currentCollaborationSubscription != null) {
      await _unsubscribe(_currentCollaborationSubscription!);
      _currentCollaborationSubscription = null;
    }
  }

  Future<void> subscribeToCollaborationUpdates(Iterable<int> ids) async {
    await init();
    for (final id in ids) {
      await _subscribePrivate('private-collaboration.$id');
    }
  }

  Future<void> unsubscribeFromCollaborationUpdates(Iterable<int> ids) async {
    for (final id in ids) {
      await _unsubscribe('private-collaboration.$id');
    }
  }

  Future<void> subscribeToUserNotifications(int userId) async {
    await init();
    await _subscribePrivate('private-App.Models.User.$userId');
  }

  Future<void> _subscribePrivate(String channelName) async {
    final existingReferences = _channelReferences[channelName] ?? 0;
    _channelReferences[channelName] = existingReferences + 1;

    if (existingReferences > 0) return;

    await _ensureSubscribed(channelName);
  }

  Future<void> _ensureSubscribed(String channelName) async {
    if (_subscribedChannels.contains(channelName)) return;

    if (_socketId == null) {
      _pendingPrivateChannels.add(channelName);
      return;
    }

    try {
      final auth = await ApiService().authorizePusherChannel(
        _socketId!,
        channelName,
      );
      final data = <String, dynamic>{
        'channel': channelName,
        'auth': auth['auth'],
      };
      if (auth['channel_data'] != null) {
        data['channel_data'] = auth['channel_data'];
      }

      _send('pusher:subscribe', data);
      _subscribedChannels.add(channelName);
      _pendingPrivateChannels.remove(channelName);
      debugPrint('Subscribed to WebSocket channel $channelName');
    } catch (e) {
      debugPrint('WebSocket subscribe error for $channelName: $e');
      _pendingPrivateChannels.add(channelName);
    }
  }

  Future<void> _unsubscribe(String channelName) async {
    final references = _channelReferences[channelName];
    if (references == null) return;

    if (references > 1) {
      _channelReferences[channelName] = references - 1;
      return;
    }

    _channelReferences.remove(channelName);
    _pendingPrivateChannels.remove(channelName);

    if (!_subscribedChannels.contains(channelName)) return;

    _send('pusher:unsubscribe', {'channel': channelName});
    _subscribedChannels.remove(channelName);
    debugPrint('Unsubscribed from WebSocket channel $channelName');
  }

  void _send(String event, Map<String, dynamic> data) {
    _channel?.sink.add(jsonEncode({'event': event, 'data': data}));
  }

  void _handleRawEvent(dynamic raw) {
    try {
      final event = jsonDecode(raw.toString());
      if (event is! Map<String, dynamic>) return;

      final eventName = event['event']?.toString();
      if (eventName == 'pusher:connection_established') {
        _handleConnectionEstablished(event['data']);
        return;
      }

      if (eventName == 'pusher_internal:subscription_succeeded') return;

      final data = _decodeEventData(event['data']);
      if (data == null) return;

      if (_isMessageEvent(eventName)) {
        final message = _asMap(data['message'] ?? data);
        if (message != null) {
          _messageController.add(message);
          onMessageReceived?.call(message);
        }
      }

      if (_isNotificationEvent(eventName)) {
        final notification = _asMap(data['notification'] ?? data);
        if (notification != null) {
          _notificationController.add(notification);
          onNotificationReceived?.call(notification);
        }
      }

      if (_isReadReceiptEvent(eventName)) {
        _readReceiptController.add(data);
        onReadReceiptReceived?.call(data);
      }
    } catch (e) {
      debugPrint('Failed to handle websocket event: $e');
    }
  }

  Future<void> _handleConnectionEstablished(dynamic data) async {
    final decoded = _decodeEventData(data);
    _socketId = decoded?['socket_id']?.toString();
    ApiService().setSocketId(_socketId);
    _reconnectAttempts = 0;
    _emitConnectionStatus(WebSocketConnectionStatus.connected);
    debugPrint('WebSocket connected with socket id $_socketId');

    final channels = <String>{
      ..._channelReferences.keys,
      ..._pendingPrivateChannels,
    };
    _pendingPrivateChannels.clear();

    for (final channelName in channels) {
      await _ensureSubscribed(channelName);
    }
  }

  Map<String, dynamic>? _decodeEventData(dynamic data) {
    if (data == null) return null;
    if (data is Map<String, dynamic>) return data;
    if (data is Map) return Map<String, dynamic>.from(data);
    if (data is String && data.isNotEmpty) {
      final decoded = jsonDecode(data);
      return _asMap(decoded);
    }
    return null;
  }

  Map<String, dynamic>? _asMap(dynamic data) {
    if (data is Map<String, dynamic>) return data;
    if (data is Map) return Map<String, dynamic>.from(data);
    return null;
  }

  bool _isMessageEvent(String? eventName) {
    return eventName == 'message.new' ||
        eventName == '.message.new' ||
        eventName == 'App\\\\Events\\\\NewMessageEvent' ||
        eventName == 'NewMessageEvent';
  }

  bool _isReadReceiptEvent(String? eventName) {
    return eventName == 'message.read' ||
        eventName == '.message.read' ||
        eventName == 'App\\\\Events\\\\MessageReadEvent' ||
        eventName == 'MessageReadEvent';
  }

  bool _isNotificationEvent(String? eventName) {
    return eventName == 'notification.new' ||
        eventName == '.notification.new' ||
        eventName == 'App\\\\Events\\\\NewNotificationEvent' ||
        eventName == 'NewNotificationEvent';
  }

  void _resetConnection() {
    _subscription?.cancel();
    _subscription = null;
    _channel = null;
    _socketId = null;
    ApiService().setSocketId(null);
    _pendingPrivateChannels.addAll(_channelReferences.keys);
    _subscribedChannels.clear();
    _emitConnectionStatus(
      _channelReferences.isEmpty
          ? WebSocketConnectionStatus.disconnected
          : WebSocketConnectionStatus.reconnecting,
    );
    _scheduleReconnect();
  }

  void _emitConnectionStatus(WebSocketConnectionStatus status) {
    if (_connectionStatus == status) return;
    _connectionStatus = status;
    _connectionStatusController.add(status);
  }

  void _scheduleReconnect() {
    if (_channelReferences.isEmpty || _reconnectTimer != null) return;

    final seconds = min(30, pow(2, _reconnectAttempts).toInt());
    _reconnectAttempts += 1;
    _reconnectTimer = Timer(Duration(seconds: seconds), () {
      _reconnectTimer = null;
      init();
    });
  }
}
