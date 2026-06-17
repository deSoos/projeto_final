/// Holds all data produced during and after a breathing session.
class SessionData {
  final DateTime startTime;
  DateTime? endTime;

  int breathingCycles = 0;
  int totalInhales = 0;
  int totalExhales = 0;
  int tooFastWarnings = 0;
  int tremorWarnings = 0;

  SessionData({required this.startTime});

  Duration get duration {
    final end = endTime ?? DateTime.now();
    return end.difference(startTime);
  }

  int get durationMinutes => duration.inMinutes;
  int get durationSeconds => duration.inSeconds % 60;

  void finish() {
    endTime = DateTime.now();
  }

  Map<String, dynamic> toMap() => {
        'startTime': startTime.toIso8601String(),
        'endTime': endTime?.toIso8601String(),
        'durationSeconds': duration.inSeconds,
        'breathingCycles': breathingCycles,
        'totalInhales': totalInhales,
        'totalExhales': totalExhales,
        'tooFastWarnings': tooFastWarnings,
        'tremorWarnings': tremorWarnings,
      };
}

enum FeedbackMode { visual, haptic }