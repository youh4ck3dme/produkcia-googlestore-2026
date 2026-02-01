/// Demo scenáre pre prezentácie a testovanie BizAgent AI.
enum DemoScenario {
  /// Bežný SZČO, 6 mesiacov dát
  standard,

  /// Blíži sa k DPH limitu
  approachingVat,

  /// Nízky cashflow, potrebuje alert
  cashflowCrisis,

  /// Príležitosti na úsporu
  taxOptimization,

  /// Podozrivé transakcie
  anomalyDetection,

  /// Chýbajúce bločky na rekonštrukciu
  receiptMissing,
}
