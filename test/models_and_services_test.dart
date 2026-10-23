import 'package:flutter_test/flutter_test.dart';
import 'package:safe/core/errors/safe_exception.dart';
import 'package:safe/services/animal_info_service.dart';
import 'package:safe/services/hardware_service.dart';
import 'package:safe/services/history_service.dart';
import 'package:safe/services/settings_service.dart';
import 'package:safe/shared/models/history_entry.dart';
import 'package:safe/shared/models/prediction.dart';
import 'package:shared_preferences/shared_preferences.dart';

Map<String, dynamic> api({double score = 0.8}) => {
      'label': 'Dog',
      'score': score,
      'top': [
        {'label': 'Dog', 'score': score},
        {'label': 'Wolf', 'score': 0.1},
        {'label': 'Fox', 'score': 0.05}
      ],
      'ambiguous': false,
      'inferenceMs': 42.0,
      'timestamp': '2026-10-24T10:00:00Z',
      'modelVersion': 'm.h5',
      'labelsVerified': false,
      'preprocessVerified': false,
      'qualityWarnings': []
    };

void main() {
  group('Prediction', () {
    test('accepted above threshold', () {
      expect(Prediction.fromApi(api(), 0.6).accepted, isTrue);
    });
    test('low confidence below threshold', () {
      expect(Prediction.fromApi(api(score: 0.4), 0.6).accepted, isFalse);
    });
    test('malformed response throws, never guesses', () {
      expect(() => Prediction.fromApi({'label': 'Dog'}, 0.6),
          throwsA(isA<SafeException>()));
      expect(() => Prediction.fromApi(api(score: 1.7), 0.6),
          throwsA(isA<SafeException>()));
    });
  });

  group('AnimalInfoService', () {
    final svc = AnimalInfoService.fromJsonString(
        '{"Dog":{"commonName":"Dog","group":"Mammal","safety":["x"]}}');
    test('case-insensitive lookup', () => expect(svc.lookup('dog')?.commonName, 'Dog'));
    test('missing fields are Unavailable, not invented',
        () => expect(svc.lookup('Dog')!.scientificName, 'Unavailable'));
    test('unknown label returns null', () => expect(svc.lookup('Dragon'), isNull));
  });

  group('Persistence', () {
    setUp(() => SharedPreferences.setMockInitialValues({}));
    test('history add / persist / delete / clear', () async {
      final h = await HistoryService.load();
      final e = HistoryEntry.fromPrediction(Prediction.fromApi(api(), 0.6));
      await h.add(e);
      expect((await HistoryService.load()).entries.length, 1);
      await h.delete(e.id);
      expect(h.entries, isEmpty);
      await h.add(e);
      await h.clear();
      expect((await HistoryService.load()).entries, isEmpty);
    });
    test('corrupted history does not crash', () async {
      SharedPreferences.setMockInitialValues({'history_v1': 'not json'});
      expect((await HistoryService.load()).entries, isEmpty);
    });
    test('settings persist; history saving is opt-in', () async {
      final s = await SettingsService.forTest();
      expect(s.saveHistory, isFalse);
      await s.setThreshold(0.7);
      await s.setApiUrl('http://192.168.1.5:8000');
      final s2 = await SettingsService.forTest();
      expect(s2.threshold, 0.7);
      expect(s2.apiUrl, 'http://192.168.1.5:8000');
    });
  });

  group('Hardware', () {
    test('encode/decode round trip', () {
      final m = HwMessage(3, HwMessageType.arm, {'seconds': 5});
      final d = HwMessage.decode(m.encode());
      expect(d.id, 3);
      expect(d.type, HwMessageType.arm);
      expect(d.data['seconds'], 5);
    });
    test('invalid messages rejected', () {
      for (final bad in [
        '',
        '{',
        '{"v":2,"id":1,"type":"PING"}',
        '{"v":1,"id":1,"type":"NOPE"}'
      ]) {
        expect(() => HwMessage.decode(bad), throwsA(isA<SafeException>()));
      }
    });
    test('connected only after pong; arm needs authorization', () async {
      final hw = HardwareService(MockHardwareTransport());
      expect(hw.state, HwState.disconnected);
      await hw.connect('x');
      expect(hw.state, HwState.connected);
      expect(() => hw.arm(userAuthorized: false), throwsA(isA<SafeException>()));
      expect(await hw.arm(userAuthorized: true), isTrue);
    });
    test('disconnection handled', () async {
      final t = MockHardwareTransport();
      final hw = HardwareService(t);
      await hw.connect('x');
      t.failNext = true;
      await expectLater(hw.arm(userAuthorized: true), throwsA(isA<SafeException>()));
      expect(hw.state, HwState.disconnected);
    });
    test('arm refused when not connected', () {
      final hw = HardwareService(MockHardwareTransport());
      expect(() => hw.arm(userAuthorized: true), throwsA(isA<SafeException>()));
    });
  });
}
