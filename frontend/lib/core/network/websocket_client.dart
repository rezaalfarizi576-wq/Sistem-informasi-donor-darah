import 'dart:async';
import 'dart:convert';
import 'package:web_socket_channel/web_socket_channel.dart';
import '../config/env_config.dart';

class WebSocketClient {
  WebSocketChannel? _channel;
  StreamController<dynamic>? _controller;

  Stream<dynamic>? get stream => _controller?.stream;

  void connect(String requestId) {
    disconnect();
    final url = Uri.parse('${EnvConfig.wsBaseUrl}/tracking/$requestId');
    _channel = WebSocketChannel.connect(url);
    _controller = StreamController<dynamic>.broadcast();

    _channel?.stream.listen(
      (message) {
        try {
          final decoded = jsonDecode(message);
          _controller?.add(decoded);
        } catch (e) {
          _controller?.add(message);
        }
      },
      onError: (error) {
        _controller?.addError(error);
      },
      onDone: () {
        _controller?.close();
      },
    );
  }

  void sendLocation(double latitude, double longitude) {
    if (_channel != null) {
      final payload = jsonEncode({
        'latitude': latitude,
        'longitude': longitude,
        'timestamp': DateTime.now().toIso8601String(),
      });
      _channel?.sink.add(payload);
    }
  }

  void disconnect() {
    _channel?.sink.close();
    _channel = null;
    _controller?.close();
    _controller = null;
  }
}
