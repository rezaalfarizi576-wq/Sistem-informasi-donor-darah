import '../../core/network/websocket_client.dart';

class TrackingRepository {
  final WebSocketClient _wsClient;

  TrackingRepository({WebSocketClient? wsClient}) : _wsClient = wsClient ?? WebSocketClient();

  Stream<dynamic>? get locationStream => _wsClient.stream;

  void startTracking(String requestId) {
    _wsClient.connect(requestId);
  }

  void updateLocation(double latitude, double longitude) {
    _wsClient.sendLocation(latitude, longitude);
  }

  void stopTracking() {
    _wsClient.disconnect();
  }
}
