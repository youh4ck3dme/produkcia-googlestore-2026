import 'package:flutter_test/flutter_test.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:bizagent/features/expenses/models/expense_category.dart';
import 'package:bizagent/features/expenses/services/categorization_service.dart';

void main() {
  late CategorizationService service;

  setUp(() {
    final firestore = FakeFirebaseFirestore();
    service = CategorizationService(firestore);
  });

  group('CategorizationService - Doprava', () {
    test('rozpozná Slovnaft ako palivo', () {
      final (category, confidence) = service.suggestCategory('Slovnaft');
      expect(category, ExpenseCategory.fuel);
      expect(confidence, greaterThanOrEqualTo(90));
    });

    test('rozpozná Shell ako palivo', () {
      final (category, _) = service.suggestCategory('Shell Station');
      expect(category, ExpenseCategory.fuel);
    });

    test('rozpozná OMV ako palivo', () {
      final (category, _) = service.suggestCategory('OMV Benzínová pumpa');
      expect(category, ExpenseCategory.fuel);
    });

    test('rozpozná EPS ako parkovanie', () {
      final (category, confidence) = service.suggestCategory('EPS Parking');
      expect(category, ExpenseCategory.parking);
      expect(confidence, greaterThanOrEqualTo(85));
    });

    test('rozpozná SMS Ticket ako parkovanie', () {
      final (category, _) = service.suggestCategory('SMS ticket parkovanie');
      expect(category, ExpenseCategory.parking);
    });

    test('rozpozná autoservis', () {
      final (category, _) = service.suggestCategory('Autoservis Novák');
      expect(category, ExpenseCategory.carMaintenance);
    });

    test('rozpozná umývareň', () {
      final (category, _) = service.suggestCategory('Car Wash Premium');
      expect(category, ExpenseCategory.carWash);
    });

    test('rozpozná Uber ako taxi', () {
      final (category, _) = service.suggestCategory('Uber ride');
      expect(category, ExpenseCategory.taxi);
    });

    test('rozpozná Bolt ako taxi', () {
      final (category, _) = service.suggestCategory('Bolt taxi');
      expect(category, ExpenseCategory.taxi);
    });
  });

  group('CategorizationService - Stravovanie', () {
    test('rozpozná Tesco ako stravovanie', () {
      final (category, _) = service.suggestCategory('Tesco');
      expect(category, ExpenseCategory.meals);
    });

    test('rozpozná Kaufland ako stravovanie', () {
      final (category, _) = service.suggestCategory('Kaufland Bratislava');
      expect(category, ExpenseCategory.meals);
    });

    test('rozpozná Lidl ako stravovanie', () {
      final (category, _) = service.suggestCategory('LIDL SR');
      expect(category, ExpenseCategory.meals);
    });

    test('rozpozná reštauráciu', () {
      final (category, _) = service.suggestCategory('Pizzeria Napoli');
      expect(category, ExpenseCategory.meals);
    });

    test('rozpozná McDonald\'s', () {
      final (category, _) = service.suggestCategory('McDonald\'s');
      expect(category, ExpenseCategory.meals);
    });
  });

  group('CategorizationService - Komunikácia', () {
    test('rozpozná Orange ako telefón', () {
      final (category, confidence) =
          service.suggestCategory('Orange Slovensko');
      expect(category, ExpenseCategory.phone);
      expect(confidence, greaterThanOrEqualTo(90));
    });

    test('rozpozná Telekom ako telefón', () {
      final (category, _) = service.suggestCategory('Slovak Telekom');
      expect(category, ExpenseCategory.phone);
    });

    test('rozpozná O2 ako telefón', () {
      final (category, _) = service.suggestCategory('O2 Slovakia');
      expect(category, ExpenseCategory.phone);
    });

    test('rozpozná 4ka ako telefón', () {
      final (category, _) = service.suggestCategory('4ka');
      expect(category, ExpenseCategory.phone);
    });

    test('rozpozná internet providera', () {
      final (category, _) = service.suggestCategory('Slovanet Internet');
      expect(category, ExpenseCategory.internet);
    });
  });

  group('CategorizationService - Cestovné', () {
    test('rozpozná hotel', () {
      final (category, _) = service.suggestCategory('Hotel Tatra');
      expect(category, ExpenseCategory.accommodation);
    });

    test('rozpozná Booking.com', () {
      final (category, _) = service.suggestCategory('Booking.com');
      expect(category, ExpenseCategory.accommodation);
    });

    test('rozpozná Airbnb', () {
      final (category, _) = service.suggestCategory('Airbnb reservation');
      expect(category, ExpenseCategory.accommodation);
    });

    test('rozpozná Ryanair ako letenku', () {
      final (category, _) = service.suggestCategory('Ryanair');
      expect(category, ExpenseCategory.flights);
    });

    test('rozpozná Wizz Air ako letenku', () {
      final (category, _) = service.suggestCategory('Wizz Air');
      expect(category, ExpenseCategory.flights);
    });

    test('rozpozná ZSSK ako vlak', () {
      final (category, _) = service.suggestCategory('ZSSK');
      expect(category, ExpenseCategory.trainTickets);
    });

    test('rozpozná RegioJet ako vlak', () {
      final (category, _) = service.suggestCategory('RegioJet');
      expect(category, ExpenseCategory.trainTickets);
    });

    test('rozpozná MHD', () {
      final (category, _) = service.suggestCategory('DPB MHD');
      expect(category, ExpenseCategory.publicTransport);
    });
  });

  group('CategorizationService - Poistenie', () {
    test('rozpozná poisťovňu', () {
      final (category, _) =
          service.suggestCategory('Allianz Slovenská poisťovňa');
      expect(
          category,
          isIn([
            ExpenseCategory.healthInsurance,
            ExpenseCategory.carInsurance,
            ExpenseCategory.liabilityInsurance,
          ]));
    });

    test('rozpozná poistenie auta', () {
      final (category, _) =
          service.suggestCategory('Kooperativa Auto poistenie');
      expect(category, ExpenseCategory.carInsurance);
    });

    test('rozpozná zdravotné poistenie', () {
      final (category, _) =
          service.suggestCategory('Union zdravotná poisťovňa');
      expect(category, ExpenseCategory.healthInsurance);
    });
  });

  group('CategorizationService - Služby', () {
    test('rozpozná účtovníctvo', () {
      final (category, _) = service.suggestCategory('Účtovníctvo Novák s.r.o.');
      expect(category, ExpenseCategory.accounting);
    });

    test('rozpozná právne služby', () {
      final (category, _) =
          service.suggestCategory('Advokátska kancelária Novák');
      expect(category, ExpenseCategory.legal);
    });

    test('rozpozná marketing', () {
      final (category, _) = service.suggestCategory('Facebook Ads');
      expect(category, ExpenseCategory.marketing);
    });

    test('rozpozná Google Ads', () {
      final (category, _) = service.suggestCategory('Google Advertising');
      expect(category, ExpenseCategory.marketing);
    });
  });

  group('CategorizationService - Prevádzkové náklady', () {
    test('rozpozná nájom', () {
      final (category, _) =
          service.suggestCategory('Prenájom priestorov Bratislava');
      expect(category, ExpenseCategory.rent);
    });

    test('rozpozná elektrinu', () {
      final (category, _) = service.suggestCategory('ZSE Elektrina');
      expect(category, ExpenseCategory.electricity);
    });

    test('rozpozná vodu', () {
      final (category, _) =
          service.suggestCategory('BVS Vodárenská spoločnosť');
      expect(category, ExpenseCategory.water);
    });

    test('rozpozná plyn', () {
      final (category, _) = service.suggestCategory('SPP Plyn');
      expect(category, ExpenseCategory.heating);
    });
  });

  group('CategorizationService - Ostatné', () {
    test('rozpozná banku', () {
      final (category, _) = service.suggestCategory('Tatra banka poplatok');
      expect(category, ExpenseCategory.bankFees);
    });

    test('rozpozná VÚB', () {
      final (category, _) = service.suggestCategory('VÚB banka');
      expect(category, ExpenseCategory.bankFees);
    });

    test('rozpozná školenie', () {
      final (category, _) = service.suggestCategory('Školenie Excel');
      expect(category, ExpenseCategory.training);
    });

    test('rozpozná knihu', () {
      final (category, _) = service.suggestCategory('Martinus knihkupectvo');
      expect(category, ExpenseCategory.books);
    });

    test('neznámy dodávateľ vráti Other s nízkou istotou', () {
      final (category, confidence) =
          service.suggestCategory('Neznámy dodávateľ XYZ');
      expect(category, ExpenseCategory.other);
      expect(confidence, lessThan(50));
    });
  });

  group('CategorizationService - Case insensitive', () {
    test('funguje s veľkými písmenami', () {
      final (category, _) = service.suggestCategory('SLOVNAFT');
      expect(category, ExpenseCategory.fuel);
    });

    test('funguje s malými písmenami', () {
      final (category, _) = service.suggestCategory('slovnaft');
      expect(category, ExpenseCategory.fuel);
    });

    test('funguje so zmiešanými písmenami', () {
      final (category, _) = service.suggestCategory('SloVnaFt');
      expect(category, ExpenseCategory.fuel);
    });
  });

  group('CategorizationService - Confidence score', () {
    test('vysoká istota pre známych dodávateľov', () {
      final (_, confidence) = service.suggestCategory('Slovnaft');
      expect(confidence, greaterThanOrEqualTo(90));
    });

    test('nízka istota pre neznámych dodávateľov', () {
      final (_, confidence) = service.suggestCategory('Random Company 123');
      expect(confidence, lessThan(50));
    });
  });
}
