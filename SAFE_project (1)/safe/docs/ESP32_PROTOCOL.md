# SAFE ↔ ESP32 protocol (PROPOSED v1 — firmware NOT implemented)

Transport-independent. One JSON object per message, UTF-8, newline-terminated.

```
{"v":1,"id":7,"type":"PING"}             app → device
{"v":1,"id":7,"type":"PONG"}             device → app
{"v":1,"id":8,"type":"ARM","seconds":5}  app → device (explicit user action only)
{"v":1,"id":8,"type":"ACK"}              device → app
{"v":1,"id":9,"type":"DISARM"}           app → device
{"v":1,"id":9,"type":"ERROR","reason":"..."}
```

Wi-Fi transport (`WifiHttpTransport`, not tested on hardware): `POST http://<esp32-ip>/safe`, body = one message, response body = the reply.
BLE transport: not implemented (`BleTransportPlaceholder`); needs `flutter_blue_plus` and a GATT design.

## Firmware work still required
- Reply PONG to PING and ACK/ERROR to ARM/DISARM.
- Hardware-side interlocks: hard maximum output duration, cooldown between activations, auto-disarm on connection loss, output off at boot, physical enable switch recommended.
- Firmware must enforce its own limits; the app only clamps `seconds` to 1–10.

## Safety rules enforced in the app
- "Connected" only after a PONG.
- `HardwareService.arm` requires `userAuthorized: true` and a connected device, and is never auto-retried.
- No code path links a prediction to `arm`.
- Effectiveness and safety of ultrasonic deterrence for any animal species are not established.
