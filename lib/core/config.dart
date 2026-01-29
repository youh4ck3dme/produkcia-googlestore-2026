class BizConfig {
  static const String appName = 'BizAgent';
  
  // Monetization Product IDs (Google Play)
  static const String productProMonthly = 'sub_pro_monthly';
  static const String productProYearly = 'sub_pro_year';
  static const String productBusinessMonthly = 'sub_business_monthly';
  static const String productOneTimeStarter = 'one_time_starter';
  
  static const List<String> allProducts = [
    productProMonthly,
    productProYearly,
    productBusinessMonthly,
    productOneTimeStarter,
  ];

  // Feature Limits (Free Tier)
  static const int freeInvoiceLimitMonthly = 3;
  static const int freeAiUsageLimit = 1; // 1 analysis
  static const int freeIcoLookupLimit = 5;
}
