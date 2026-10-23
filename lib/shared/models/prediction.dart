import '../../core/errors/safe_exception.dart';

class ScoredLabel {
  final String label;
  final double score;
  const ScoredLabel(this.label, this.score);
  Map<String, dynamic> toJson() => {'label': label, 'score': score};
  factory ScoredLabel.fromJson(Map<String, dynamic> j) =>
      ScoredLabel(j['label'] as String, (j['score'] as num).toDouble());
}

enum PredictionStatus { accepted, lowConfidence }

/// A classification result. [score] is the model's raw output score
/// (softmax-style); it is NOT a calibrated probability.
class Prediction {
  final String label;
  final double score;
  final List<ScoredLabel> top;
  final bool ambiguous;
  final double inferenceMs;
  final DateTime timestamp;
  final String modelVersion;
  final bool labelsVerified;
  final bool preprocessVerified;
  final List<String> qualityWarnings;
  final PredictionStatus status;

  const Prediction({
    required this.label,
    required this.score,
    required this.top,
    required this.ambiguous,
    required this.inferenceMs,
    required this.timestamp,
    required this.modelVersion,
    required this.labelsVerified,
    required this.preprocessVerified,
    required this.qualityWarnings,
    required this.status,
  });

  bool get accepted => status == PredictionStatus.accepted;

  /// Parses the backend JSON strictly; anything malformed is an error, never a guess.
  factory Prediction.fromApi(Map<String, dynamic> j, double threshold) {
    try {
      final top = (j['top'] as List)
          .map((e) => ScoredLabel.fromJson(e as Map<String, dynamic>))
          .toList();
      if (top.isEmpty) throw const FormatException('empty top list');
      final score = (j['score'] as num).toDouble();
      if (score.isNaN || score < 0 || score > 1) {
        throw const FormatException('score out of range');
      }
      return Prediction(
        label: j['label'] as String,
        score: score,
        top: top,
        ambiguous: j['ambiguous'] == true,
        inferenceMs: (j['inferenceMs'] as num).toDouble(),
        timestamp: DateTime.tryParse(j['timestamp'] as String? ?? '')?.toLocal() ??
            DateTime.now(),
        modelVersion: j['modelVersion'] as String? ?? 'unknown',
        labelsVerified: j['labelsVerified'] == true,
        preprocessVerified: j['preprocessVerified'] == true,
        qualityWarnings:
            ((j['qualityWarnings'] as List?) ?? const []).cast<String>(),
        status: score >= threshold
            ? PredictionStatus.accepted
            : PredictionStatus.lowConfidence,
      );
    } catch (e) {
      throw SafeException(SafeErrorCode.invalidResponse,
          'The server returned an unexpected result.', e);
    }
  }
}
