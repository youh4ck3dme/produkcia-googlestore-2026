import 'dart:typed_data';

class ExportPeriod {
  final DateTime from;
  final DateTime to;
  final String label;

  const ExportPeriod({
    required this.from,
    required this.to,
    this.label = '',
  });

  static ExportPeriod thisMonth(DateTime now) {
    final from = DateTime(now.year, now.month, 1);
    final to =
        DateTime(now.year, now.month + 1, 1).subtract(const Duration(days: 1));
    return ExportPeriod(from: from, to: to, label: 'This month');
  }

  static ExportPeriod lastMonth(DateTime now) {
    final prev = DateTime(now.year, now.month - 1, 1);
    final from = DateTime(prev.year, prev.month, 1);
    final to = DateTime(prev.year, prev.month + 1, 1)
        .subtract(const Duration(days: 1));
    return ExportPeriod(from: from, to: to, label: 'Last month');
  }

  static ExportPeriod thisYear(DateTime now) {
    final from = DateTime(now.year, 1, 1);
    final to = DateTime(now.year, 12, 31);
    return ExportPeriod(from: from, to: to, label: 'This year');
  }
}

class ExportProgress {
  final double percent;
  final bool pdfDone;
  final bool photosDone;
  final bool csvDone;
  final bool jsonDone;
  final String message;

  const ExportProgress({
    required this.percent,
    required this.pdfDone,
    required this.photosDone,
    required this.csvDone,
    required this.jsonDone,
    required this.message,
  });

  factory ExportProgress.idle() => const ExportProgress(
        percent: 0,
        pdfDone: false,
        photosDone: false,
        csvDone: false,
        jsonDone: false,
        message: '',
      );

  factory ExportProgress.empty() => ExportProgress.idle();

  ExportProgress copyWith({
    double? percent,
    bool? pdfDone,
    bool? photosDone,
    bool? csvDone,
    bool? jsonDone,
    String? message,
  }) {
    return ExportProgress(
      percent: percent ?? this.percent,
      pdfDone: pdfDone ?? this.pdfDone,
      photosDone: photosDone ?? this.photosDone,
      csvDone: csvDone ?? this.csvDone,
      jsonDone: jsonDone ?? this.jsonDone,
      message: message ?? this.message,
    );
  }
}

class ExportResult {
  final String zipPath;
  final bool hasMissing;
  final List<String> missingItems;
  final DateTime? generatedAt;
  final Uint8List? zipBytes;

  const ExportResult({
    required this.zipPath,
    this.hasMissing = false,
    this.missingItems = const [],
    this.generatedAt,
    this.zipBytes,
  });
}

class ExportState {
  final bool isRunning;
  final ExportProgress progress;
  final ExportResult? result;
  final String? error;

  const ExportState({
    required this.isRunning,
    required this.progress,
    this.result,
    this.error,
  });

  factory ExportState.idle() =>
      ExportState(isRunning: false, progress: ExportProgress.idle());

  ExportState copyWith({
    bool? isRunning,
    ExportProgress? progress,
    ExportResult? result,
    String? error,
  }) {
    return ExportState(
      isRunning: isRunning ?? this.isRunning,
      progress: progress ?? this.progress,
      result: result ?? this.result,
      error: error,
    );
  }
}
