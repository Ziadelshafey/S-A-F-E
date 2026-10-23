import 'prediction.dart';

class HistoryEntry {
  final String id;
  final DateTime timestamp;
  final String label;
  final double score;
  final List<ScoredLabel> top;
  final String? feedback; // e.g. "incorrect"

  const HistoryEntry({
    required this.id,
    required this.timestamp,
    required this.label,
    required this.score,
    required this.top,
    this.feedback,
  });

  factory HistoryEntry.fromPrediction(Prediction p, {String? feedback}) =>
      HistoryEntry(
        id: p.timestamp.microsecondsSinceEpoch.toString(),
        timestamp: p.timestamp,
        label: p.label,
        score: p.score,
        top: p.top,
        feedback: feedback,
      );

  HistoryEntry withFeedback(String f) => HistoryEntry(
      id: id, timestamp: timestamp, label: label, score: score, top: top, feedback: f);

  Map<String, dynamic> toJson() => {
        'id': id,
        'timestamp': timestamp.toIso8601String(),
        'label': label,
        'score': score,
        'top': top.map((e) => e.toJson()).toList(),
        'feedback': feedback,
      };

  factory HistoryEntry.fromJson(Map<String, dynamic> j) => HistoryEntry(
        id: j['id'] as String,
        timestamp: DateTime.parse(j['timestamp'] as String),
        label: j['label'] as String,
        score: (j['score'] as num).toDouble(),
        top: ((j['top'] as List?) ?? const [])
            .map((e) => ScoredLabel.fromJson(e as Map<String, dynamic>))
            .toList(),
        feedback: j['feedback'] as String?,
      );
}
