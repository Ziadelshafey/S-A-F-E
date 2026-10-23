import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;

import '../core/config/app_config.dart';
import '../core/errors/safe_exception.dart';
import '../shared/models/prediction.dart';
import 'settings_service.dart';

enum ModelStatus { loading, ready, unavailable }

class ModelHealth {
  final ModelStatus status;
  final String? detail;
  final bool labelsVerified;
  final bool preprocessVerified;
  final String? version;
  const ModelHealth(this.status,
      {this.detail,
      this.labelsVerified = false,
      this.preprocessVerified = false,
      this.version});
}

/// Talks to the SAFE inference backend (original Keras model, server-side).
/// Never fabricates a result: every failure becomes a [SafeException].
class ClassificationService {
  final SettingsService settings;
  final http.Client _client;
  bool _busy = false;

  ClassificationService(this.settings, {http.Client? client})
      : _client = client ?? http.Client();

  bool get busy => _busy;

  Uri _uri(String path) =>
      Uri.parse('${settings.apiUrl.replaceAll(RegExp(r'/+$'), '')}$path');

  Future<ModelHealth> checkHealth() async {
    try {
      final r = await _client.get(_uri('/health')).timeout(AppConfig.healthTimeout);
      final j = jsonDecode(r.body) as Map<String, dynamic>;
      final st = j['status'];
      if (r.statusCode == 200 && st == 'ready') {
        return ModelHealth(ModelStatus.ready,
            labelsVerified: j['labelsVerified'] == true,
            preprocessVerified: j['preprocessVerified'] == true,
            version: j['modelVersion'] as String?);
      }
      return ModelHealth(ModelStatus.unavailable,
          detail: (j['error'] as String?) ?? 'Model not loaded on server.');
    } on TimeoutException {
      return const ModelHealth(ModelStatus.unavailable, detail: 'Server timed out.');
    } catch (e) {
      return ModelHealth(ModelStatus.unavailable, detail: 'Server unreachable.');
    }
  }

  Future<Prediction> classify(File image) async {
    if (_busy) {
      throw SafeException(SafeErrorCode.inferenceFailed,
          'An analysis is already running.');
    }
    _busy = true;
    try {
      final req = http.MultipartRequest('POST', _uri('/predict'))
        ..files.add(await http.MultipartFile.fromPath('image', image.path));
      final streamed = await _client.send(req).timeout(AppConfig.requestTimeout);
      final r = await http.Response.fromStream(streamed);
      final body = jsonDecode(r.body);
      if (r.statusCode == 200) {
        return Prediction.fromApi(body as Map<String, dynamic>, settings.threshold);
      }
      final detail = (body is Map ? body['detail'] : null);
      final code = detail is Map ? detail['code'] : null;
      switch (code) {
        case 'model_unavailable':
          throw SafeException(SafeErrorCode.modelUnavailable,
              'The AI model is not available on the server.', r.body);
        case 'invalid_image':
          throw SafeException(SafeErrorCode.invalidImage,
              'This image cannot be used. Try another photo.', r.body);
        default:
          throw SafeException(SafeErrorCode.inferenceFailed,
              'Analysis failed. Please try again.', r.body);
      }
    } on SafeException {
      rethrow;
    } on TimeoutException catch (e) {
      throw SafeException(SafeErrorCode.timeout,
          'The server took too long to respond.', e);
    } on SocketException catch (e) {
      throw SafeException(SafeErrorCode.network,
          'Cannot reach the SAFE server. Check the address in Settings.', e);
    } on http.ClientException catch (e) {
      throw SafeException(SafeErrorCode.network,
          'Cannot reach the SAFE server. Check the address in Settings.', e);
    } on FormatException catch (e) {
      throw SafeException(SafeErrorCode.invalidResponse,
          'The server returned an unexpected result.', e);
    } finally {
      _busy = false;
    }
  }
}
