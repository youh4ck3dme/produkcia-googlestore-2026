class TaxDeadlineModel {
  final String title;
  final DateTime date;
  final String description;
  final bool isMajor;

  TaxDeadlineModel({
    required this.title,
    required this.date,
    required this.description,
    this.isMajor = false,
  });
}
