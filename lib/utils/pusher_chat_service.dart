import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:booking_system_flutter/utils/configs.dart';
import 'package:http/http.dart' as http;
import 'package:nb_utils/nb_utils.dart';
import 'package:pusher_channels_flutter/pusher_channels_flutter.dart';

/// Wraps a Pusher private-channel subscription for a single chat conversation.
/// Falls back gracefully if the connection fails — the polling timer in the
/// screen continues to work as a safety net.
class PusherChatService {
  PusherChatService._();

  static final PusherChatService instance = PusherChatService._();

  PusherChannelsFlutter? _pusher;
  String? _currentChannel;
  bool _connected = false;

  /// [onMessage] is called with the raw Map payload whenever a new message
  /// arrives over the WebSocket.
  Future<void> subscribe({
    required int conversationId,
    required String bearerToken,
    required void Function(Map<String, dynamic> payload) onMessage,
  }) async {
    if (PUSHER_APP_KEY.isEmpty) return; // credentials not configured yet

    await dispose(); // clean up any previous subscription

    try {
      _pusher = PusherChannelsFlutter.getInstance();
      _currentChannel = 'private-chat.$conversationId';

      await _pusher!.init(
        apiKey: PUSHER_APP_KEY,
        cluster: PUSHER_APP_CLUSTER,
        onConnectionStateChange: (current, previous) {
          _connected = current == 'CONNECTED';
          log('Pusher: $previous → $current');
        },
        onError: (message, code, error) {
          log('Pusher error [$code]: $message $error');
        },
        onEvent: (event) {
          if (event.eventName == 'ChatMessageSent' &&
              event.channelName == _currentChannel) {
            try {
              final data = jsonDecode(event.data as String) as Map<String, dynamic>;
              onMessage(data);
            } catch (e) {
              log('Pusher event parse error: $e');
            }
          }
        },
        // Custom authorizer: POST to Laravel broadcasting/auth with Bearer token
        onAuthorizer: (channelName, socketId, options) async {
          try {
            final res = await http.post(
              Uri.parse('$DOMAIN_URL/broadcasting/auth'),
              headers: {
                HttpHeaders.authorizationHeader: 'Bearer $bearerToken',
                HttpHeaders.contentTypeHeader: 'application/x-www-form-urlencoded',
              },
              body: {
                'channel_name': channelName,
                'socket_id': socketId,
              },
            );
            return jsonDecode(res.body);
          } catch (e) {
            log('Pusher auth error: $e');
            return {};
          }
        },
      );

      await _pusher!.connect();
      await _pusher!.subscribe(channelName: _currentChannel!);
    } catch (e) {
      log('PusherChatService.subscribe error: $e');
      _connected = false;
    }
  }

  bool get isConnected => _connected;

  Future<void> dispose() async {
    try {
      if (_currentChannel != null) {
        await _pusher?.unsubscribe(channelName: _currentChannel!);
      }
      await _pusher?.disconnect();
    } catch (_) {}
    _pusher = null;
    _currentChannel = null;
    _connected = false;
  }
}
