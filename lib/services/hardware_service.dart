import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../core/errors/safe_exception.dart';

/// PROPOSED protocol v1 (see docs/ESP32_PROTOCOL.md). Firmware is NOT implemented.
/// Newline-delimited JSON: {"v":1,"id":<int>,"type":"<TYPE>", ...}
enum HwMessageType { ping, pong, status, arm, disarm, ack, error }

class HwMessage {
  final int id;
  final HwMessageType type;
  final Map<String, dynamic> data;
  const HwMessage(this.id, this.type, [this.data = const {}]);

  String encode() =>
      jsonEncode({'v': 1, 'id': id, 'type': type.name.toUpperCase(), ...data});

  /// Throws [SafeException] on any invalid message.
  static HwMessage decode(String raw) {
    try {
      final j = jsonDecode(raw.trim()) as Map<String, dynamic>;
      if (j['v'] != 1) throw const FormatException('unsupported version');
      final t = HwMessageType.values
          .firstWhere((e) => e.name.toUpperCase() == j['type']);
      final data = Map<String, dynamic>.from(j)
        ..removeWhere((k, _) => k == 'v' || k == 'id' || k == 'type');
      return HwMessage(j['id'] as int, t, data);
    } catch (e) {
      throw SafeException(
          SafeErrorCode.hardware, 'Invalid message from device.', e);
    }
  }
}

enum HwState { disconnected, connecting, connected, error }

abstract class HardwareTransport {
  Future<List<String>> discover();
  Future<void> connect(String deviceId);
  Future<void> disconnect();

  /// Sends a message and waits for the device's reply.
  Future<HwMessage> request(HwMessage m, {Duration timeout});
}

/// Development transport: behaves like a device that is reachable. It never
/// reports a real connection; the UI labels it "Simulated".
class MockHardwareTransport implements HardwareTransport {
  bool _connected = false;
  bool failNext = false;
  @override
  Future<List<String>> discover() async => ['mock-safe-device'];
  @override
  Future<void> connect(String deviceId) async => _connected = true;
  @override
  Future<void> disconnect() async => _connected = false;
  @override
  Future<HwMessage> request(HwMessage m,
      {Duration timeout = const Duration(seconds: 2)}) async {
    if (!_connected || failNext) {
      failNext = false;
      _connected = false;
      throw SafeException(SafeErrorCode.hardware, 'Device disconnected.');
    }
    switch (m.type) {
      case HwMessageType.ping:
        return HwMessage(m.id, HwMessageType.pong);
      case HwMessageType.arm:
      case HwMessageType.disarm:
        return HwMessage(m.id, HwMessageType.ack);
      default:
        return HwMessage(m.id, HwMessageType.error, {'reason': 'unsupported'});
    }
  }
}

/// Wi-Fi transport over HTTP to an ESP32 at http://<ip>/safe (proposed).
/// UNTESTED against real hardware.
class WifiHttpTransport implements HardwareTransport {
  String? _base;
  @override
  Future<List<String>> discover() async => []; // mDNS discovery not implemented
  @override
  Future<void> connect(String deviceId) async => _base = 'http://$deviceId';
  @override
  Future<void> disconnect() async => _base = null;
  @override
  Future<HwMessage> request(HwMessage m,
      {Duration timeout = const Duration(seconds: 3)}) async {
    final base = _base;
    if (base == null) {
      throw SafeException(SafeErrorCode.hardware, 'Device disconnected.');
    }
    try {
      final r = await http
          .post(Uri.parse('$base/safe'), body: m.encode())
          .timeout(timeout);
      return HwMessage.decode(r.body);
    } on TimeoutException catch (e) {
      throw SafeException(SafeErrorCode.hardware, 'Device did not respond.', e);
    } on SafeException {
      rethrow;
    } catch (e) {
      throw SafeException(SafeErrorCode.hardware, 'Device unreachable.', e);
    }
  }
}

/// BLE transport: NOT IMPLEMENTED (needs flutter_blue_plus and firmware GATT design).
class BleTransportPlaceholder implements HardwareTransport {
  Never _no() => throw SafeException(
      SafeErrorCode.hardware, 'Bluetooth transport is not implemented yet.');
  @override
  Future<List<String>> discover() async => _no();
  @override
  Future<void> connect(String deviceId) async => _no();
  @override
  Future<void> disconnect() async {}
  @override
  Future<HwMessage> request(HwMessage m, {Duration timeout = const Duration(seconds: 3)}) async => _no();
}

/// High-level hardware API. Connection state only becomes `connected` after
/// a PONG from the transport. Output is never triggered by a prediction:
/// [arm] must be called from an explicit user action.
class HardwareService {
  final HardwareTransport transport;
  HwState state = HwState.disconnected;
  String? lastError;
  int _id = 0;
  HardwareService(this.transport);

  bool get isSimulated => transport is MockHardwareTransport;

  Future<void> connect(String deviceId) async {
    state = HwState.connecting;
    lastError = null;
    try {
      await transport.connect(deviceId);
      final r = await _send(HwMessageType.ping);
      if (r.type != HwMessageType.pong) {
        throw SafeException(SafeErrorCode.hardware, 'Unexpected reply from device.');
      }
      state = HwState.connected;
    } on SafeException catch (e) {
      state = HwState.error;
      lastError = e.userMessage;
      await transport.disconnect();
    }
  }

  Future<void> disconnect() async {
    await transport.disconnect();
    state = HwState.disconnected;
  }

  /// Requires an explicit user authorization flag from the UI layer.
  Future<bool> arm({required bool userAuthorized, int durationSeconds = 5}) async {
    if (!userAuthorized) {
      throw SafeException(SafeErrorCode.hardware, 'Explicit user authorization required.');
    }
    if (state != HwState.connected) {
      throw SafeException(SafeErrorCode.hardware, 'Device is not connected.');
    }
    final r = await _send(HwMessageType.arm,
        {'seconds': durationSeconds.clamp(1, 10)}); // hardware must also enforce limits
    return r.type == HwMessageType.ack;
  }

  Future<HwMessage> _send(HwMessageType t, [Map<String, dynamic> data = const {}]) async {
    const retries = 2;
    for (var attempt = 0;; attempt++) {
      try {
        return await transport.request(HwMessage(++_id, t, data));
      } on SafeException catch (e) {
        if (attempt >= retries || t == HwMessageType.arm) {
          // never auto-retry an output command
          state = HwState.disconnected;
          lastError = e.userMessage;
          rethrow;
        }
      }
    }
  }
}
