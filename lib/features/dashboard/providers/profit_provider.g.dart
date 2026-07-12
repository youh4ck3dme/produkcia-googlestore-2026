// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'profit_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(profitMetrics)
final profitMetricsProvider = ProfitMetricsProvider._();

final class ProfitMetricsProvider extends $FunctionalProvider<
        AsyncValue<ProfitMetrics>, ProfitMetrics, FutureOr<ProfitMetrics>>
    with $FutureModifier<ProfitMetrics>, $FutureProvider<ProfitMetrics> {
  ProfitMetricsProvider._()
      : super(
          from: null,
          argument: null,
          retry: null,
          name: r'profitMetricsProvider',
          isAutoDispose: true,
          dependencies: null,
          $allTransitiveDependencies: null,
        );

  @override
  String debugGetCreateSourceHash() => _$profitMetricsHash();

  @$internal
  @override
  $FutureProviderElement<ProfitMetrics> $createElement(
          $ProviderPointer pointer) =>
      $FutureProviderElement(pointer);

  @override
  FutureOr<ProfitMetrics> create(Ref ref) {
    return profitMetrics(ref);
  }
}

String _$profitMetricsHash() => r'4f2cfcb860c0753e07f8060b9ecd3a95d36189ad';
