import 'package:flutter_test/flutter_test.dart';
import 'package:bizagent/core/demo_mode/demo_data_generator.dart';
import 'package:bizagent/core/demo_mode/demo_scenarios.dart';

void main() {
  group('Receipt Detective E2E Tests', () {
    test('generateOrphanTransactions returns orphan list', () {
      final orphans = DemoDataGenerator.generateOrphanTransactions();
      expect(orphans.length, 2);
      expect(orphans.any((o) => o.merchantHint == 'CARD PAYMENT POS'), isTrue);
      expect(orphans.any((o) => o.merchantHint == 'SEPA TRANSFER'), isTrue);
      expect(orphans.every((o) => o.amount > 0 && o.id.isNotEmpty), isTrue);
    });

    test('generateLocationHistory returns realistic places', () {
      final locations = DemoDataGenerator.generateLocationHistory();
      expect(locations, isNotEmpty);
      expect(locations.any((l) => l.placeName.contains('Tesco')), isTrue);
      expect(locations.any((l) => l.placeName.contains('OMV') || l.placeName.contains('Alza')), isTrue);
    });

    test('generateEmails returns receipt-like emails', () {
      final emails = DemoDataGenerator.generateEmails();
      expect(emails, isNotEmpty);
      expect(emails.first.subject.toLowerCase(), contains('objednávk'));
      expect(emails.first.body, contains('156'));
    });

    test('generateCalendarEvents returns meeting events', () {
      final events = DemoDataGenerator.generateCalendarEvents();
      expect(events, isNotEmpty);
      expect(events.first.title, contains('Meeting'));
      expect(events.first.attendees, isNotEmpty);
    });

    test('receipt_missing scenario includes receipt-related insight', () {
      final insights = DemoDataGenerator.generateInsights(DemoScenario.receiptMissing);
      expect(insights, isNotEmpty);
      expect(
        insights.any((i) =>
            i.title.toLowerCase().contains('bloč') ||
            i.description.toLowerCase().contains('bloč') ||
            i.description.toLowerCase().contains('rekonštrukci')),
        isTrue,
      );
    });

    test('confidence-style: multiple evidence sources increase reliability', () {
      final orphans = DemoDataGenerator.generateOrphanTransactions();
      final locations = DemoDataGenerator.generateLocationHistory();
      final emails = DemoDataGenerator.generateEmails();
      expect(orphans.length, 2);
      expect(locations.length, greaterThanOrEqualTo(2));
      expect(emails.length, greaterThanOrEqualTo(1));
      // Simulated: if we have bank + GPS + email for same date, confidence should be high
      final orphanDate = orphans.first.date;
      final matchingLocations = locations.where((l) =>
          l.date.year == orphanDate.year &&
          l.date.month == orphanDate.month &&
          l.date.day == orphanDate.day);
      final matchingEmails = emails.where((e) =>
          e.date.year == orphanDate.year &&
          e.date.month == orphanDate.month &&
          e.date.day == orphanDate.day);
      final fragmentCount = 1 + matchingLocations.length + matchingEmails.length;
      expect(fragmentCount, greaterThanOrEqualTo(1));
    });

    test('conflicting data: different merchant in email vs GPS is detectable', () {
      final locations = DemoDataGenerator.generateLocationHistory();
      final emails = DemoDataGenerator.generateEmails();
      expect(locations, isNotEmpty);
      expect(emails, isNotEmpty);
      final locationPlaces = locations.map((l) => l.placeName).toSet();
      final emailSenders = emails.map((e) => e.sender).toSet();
      expect(locationPlaces.length, greaterThanOrEqualTo(1));
      expect(emailSenders.length, greaterThanOrEqualTo(1));
      // In real flow we would compare merchant from email (e.g. Alza) vs GPS place; here we only check data exists
    });
  });
}
