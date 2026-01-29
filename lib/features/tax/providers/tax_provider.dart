import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/tax_service.dart';
import '../models/tax_deadline_model.dart';
import '../../settings/providers/settings_provider.dart';

final taxServiceProvider = Provider((ref) => TaxService());

final upcomingTaxDeadlinesProvider = Provider<List<TaxDeadlineModel>>((ref) {
  final settingsAsync = ref.watch(settingsProvider);
  final service = ref.watch(taxServiceProvider);

  // If settings are loading or error, return empty list or handle gracefully
  // Here we assume if settings are present, we calculate.
  return settingsAsync.maybeWhen(
    data: (settings) => service.getUpcomingDeadlines(settings),
    orElse: () => [],
  );
});
