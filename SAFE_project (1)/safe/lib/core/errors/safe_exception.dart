enum SafeErrorCode {
  modelUnavailable,
  invalidImage,
  network,
  timeout,
  invalidResponse,
  inferenceFailed,
  permissionDenied,
  hardware,
}

class SafeException implements Exception {
  final SafeErrorCode code;
  final String userMessage;
  final Object? technical;
  SafeException(this.code, this.userMessage, [this.technical]);
  @override
  String toString() => 'SafeException($code): $userMessage [$technical]';
}
