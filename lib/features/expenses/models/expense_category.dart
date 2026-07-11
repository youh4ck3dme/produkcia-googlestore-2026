import 'package:flutter/material.dart';

import '../../../core/i18n/app_strings.dart';
import '../../../core/i18n/l10n.dart';

/// Kategórie výdavkov pre BizAgent
/// Obsahuje 30+ kategórií prispôsobených pre slovenský trh
enum ExpenseCategory {
  // 🚗 DOPRAVA
  fuel, // Palivo
  parking, // Parkovanie
  carMaintenance, // Servis auta
  carWash, // Umývanie auta
  toll, // Diaľničné poplatky
  taxi, // Taxi/Uber/Bolt

  // 🏢 KANCELÁRIA
  officeSupplies, // Kancelárske potreby
  software, // Software a licencie
  equipment, // Zariadenie a technika
  furniture, // Nábytok

  // 📱 KOMUNIKÁCIA
  phone, // Telefón
  internet, // Internet
  postage, // Poštovné

  // ✈️ CESTOVNÉ
  accommodation, // Ubytovanie
  meals, // Stravovanie
  flights, // Letenky
  trainTickets, // Vlakové lístky
  publicTransport, // MHD

  // 🛡️ POISTENIE
  healthInsurance, // Zdravotné poistenie
  carInsurance, // Poistenie auta
  liabilityInsurance, // Poistenie zodpovednosti

  // 💼 SLUŽBY
  accounting, // Účtovníctvo
  legal, // Právne služby
  marketing, // Marketing a reklama
  consulting, // Konzultácie

  // 🏠 PREVÁDZKOVÉ NÁKLADY
  rent, // Nájom
  electricity, // Elektrina
  water, // Voda
  heating, // Kúrenie

  // 📚 VZDELÁVANIE
  training, // Školenia
  books, // Knihy a časopisy
  courses, // Kurzy

  // 🍽️ REPREZENTÁCIA
  clientMeals, // Obedy s klientmi
  gifts, // Darčeky

  // 🔧 OSTATNÉ
  bankFees, // Bankové poplatky
  other, // Ostatné
}

const _l10nKeys = <ExpenseCategory, AppStr>{
  ExpenseCategory.fuel: AppStr.expenseCatFuel,
  ExpenseCategory.parking: AppStr.expenseCatParking,
  ExpenseCategory.carMaintenance: AppStr.expenseCatCarMaintenance,
  ExpenseCategory.carWash: AppStr.expenseCatCarWash,
  ExpenseCategory.toll: AppStr.expenseCatToll,
  ExpenseCategory.taxi: AppStr.expenseCatTaxi,
  ExpenseCategory.officeSupplies: AppStr.expenseCatOfficeSupplies,
  ExpenseCategory.software: AppStr.expenseCatSoftware,
  ExpenseCategory.equipment: AppStr.expenseCatEquipment,
  ExpenseCategory.furniture: AppStr.expenseCatFurniture,
  ExpenseCategory.phone: AppStr.expenseCatPhone,
  ExpenseCategory.internet: AppStr.expenseCatInternet,
  ExpenseCategory.postage: AppStr.expenseCatPostage,
  ExpenseCategory.accommodation: AppStr.expenseCatAccommodation,
  ExpenseCategory.meals: AppStr.expenseCatMeals,
  ExpenseCategory.flights: AppStr.expenseCatFlights,
  ExpenseCategory.trainTickets: AppStr.expenseCatTrainTickets,
  ExpenseCategory.publicTransport: AppStr.expenseCatPublicTransport,
  ExpenseCategory.healthInsurance: AppStr.expenseCatHealthInsurance,
  ExpenseCategory.carInsurance: AppStr.expenseCatCarInsurance,
  ExpenseCategory.liabilityInsurance: AppStr.expenseCatLiabilityInsurance,
  ExpenseCategory.accounting: AppStr.expenseCatAccounting,
  ExpenseCategory.legal: AppStr.expenseCatLegal,
  ExpenseCategory.marketing: AppStr.expenseCatMarketing,
  ExpenseCategory.consulting: AppStr.expenseCatConsulting,
  ExpenseCategory.rent: AppStr.expenseCatRent,
  ExpenseCategory.electricity: AppStr.expenseCatElectricity,
  ExpenseCategory.water: AppStr.expenseCatWater,
  ExpenseCategory.heating: AppStr.expenseCatHeating,
  ExpenseCategory.training: AppStr.expenseCatTraining,
  ExpenseCategory.books: AppStr.expenseCatBooks,
  ExpenseCategory.courses: AppStr.expenseCatCourses,
  ExpenseCategory.clientMeals: AppStr.expenseCatClientMeals,
  ExpenseCategory.gifts: AppStr.expenseCatGifts,
  ExpenseCategory.bankFees: AppStr.expenseCatBankFees,
  ExpenseCategory.other: AppStr.expenseCatOther,
};

/// Extension pre ExpenseCategory s helper metódami
extension ExpenseCategoryExtension on ExpenseCategory {
  AppStr get l10nKey => _l10nKeys[this]!;

  /// Lokalizovaný názov kategórie (preferovať v UI).
  String label(BuildContext context) => context.t(l10nKey);

  /// Slovenský názov kategórie (pre služby bez BuildContext).
  String get displayName {
    switch (this) {
      // Doprava
      case ExpenseCategory.fuel:
        return 'Palivo';
      case ExpenseCategory.parking:
        return 'Parkovanie';
      case ExpenseCategory.carMaintenance:
        return 'Servis auta';
      case ExpenseCategory.carWash:
        return 'Umývanie auta';
      case ExpenseCategory.toll:
        return 'Diaľničné poplatky';
      case ExpenseCategory.taxi:
        return 'Taxi';

      // Kancelária
      case ExpenseCategory.officeSupplies:
        return 'Kancelárske potreby';
      case ExpenseCategory.software:
        return 'Software';
      case ExpenseCategory.equipment:
        return 'Zariadenie';
      case ExpenseCategory.furniture:
        return 'Nábytok';

      // Komunikácia
      case ExpenseCategory.phone:
        return 'Telefón';
      case ExpenseCategory.internet:
        return 'Internet';
      case ExpenseCategory.postage:
        return 'Poštovné';

      // Cestovné
      case ExpenseCategory.accommodation:
        return 'Ubytovanie';
      case ExpenseCategory.meals:
        return 'Stravovanie';
      case ExpenseCategory.flights:
        return 'Letenky';
      case ExpenseCategory.trainTickets:
        return 'Vlakové lístky';
      case ExpenseCategory.publicTransport:
        return 'MHD';

      // Poistenie
      case ExpenseCategory.healthInsurance:
        return 'Zdravotné poistenie';
      case ExpenseCategory.carInsurance:
        return 'Poistenie auta';
      case ExpenseCategory.liabilityInsurance:
        return 'Poistenie zodpovednosti';

      // Služby
      case ExpenseCategory.accounting:
        return 'Účtovníctvo';
      case ExpenseCategory.legal:
        return 'Právne služby';
      case ExpenseCategory.marketing:
        return 'Marketing';
      case ExpenseCategory.consulting:
        return 'Konzultácie';

      // Prevádzkové náklady
      case ExpenseCategory.rent:
        return 'Nájom';
      case ExpenseCategory.electricity:
        return 'Elektrina';
      case ExpenseCategory.water:
        return 'Voda';
      case ExpenseCategory.heating:
        return 'Kúrenie';

      // Vzdelávanie
      case ExpenseCategory.training:
        return 'Školenia';
      case ExpenseCategory.books:
        return 'Knihy';
      case ExpenseCategory.courses:
        return 'Kurzy';

      // Reprezentácia
      case ExpenseCategory.clientMeals:
        return 'Obedy s klientmi';
      case ExpenseCategory.gifts:
        return 'Darčeky';

      // Ostatné
      case ExpenseCategory.bankFees:
        return 'Bankové poplatky';
      case ExpenseCategory.other:
        return 'Ostatné';
    }
  }

  /// Ikona pre kategóriu
  IconData get icon {
    switch (this) {
      // Doprava
      case ExpenseCategory.fuel:
        return Icons.local_gas_station;
      case ExpenseCategory.parking:
        return Icons.local_parking;
      case ExpenseCategory.carMaintenance:
        return Icons.build;
      case ExpenseCategory.carWash:
        return Icons.local_car_wash;
      case ExpenseCategory.toll:
        return Icons.toll;
      case ExpenseCategory.taxi:
        return Icons.local_taxi;

      // Kancelária
      case ExpenseCategory.officeSupplies:
        return Icons.inventory_2;
      case ExpenseCategory.software:
        return Icons.computer;
      case ExpenseCategory.equipment:
        return Icons.devices;
      case ExpenseCategory.furniture:
        return Icons.chair;

      // Komunikácia
      case ExpenseCategory.phone:
        return Icons.phone;
      case ExpenseCategory.internet:
        return Icons.wifi;
      case ExpenseCategory.postage:
        return Icons.mail;

      // Cestovné
      case ExpenseCategory.accommodation:
        return Icons.hotel;
      case ExpenseCategory.meals:
        return Icons.restaurant;
      case ExpenseCategory.flights:
        return Icons.flight;
      case ExpenseCategory.trainTickets:
        return Icons.train;
      case ExpenseCategory.publicTransport:
        return Icons.directions_bus;

      // Poistenie
      case ExpenseCategory.healthInsurance:
        return Icons.health_and_safety;
      case ExpenseCategory.carInsurance:
        return Icons.car_crash;
      case ExpenseCategory.liabilityInsurance:
        return Icons.shield;

      // Služby
      case ExpenseCategory.accounting:
        return Icons.calculate;
      case ExpenseCategory.legal:
        return Icons.gavel;
      case ExpenseCategory.marketing:
        return Icons.campaign;
      case ExpenseCategory.consulting:
        return Icons.business_center;

      // Prevádzkové náklady
      case ExpenseCategory.rent:
        return Icons.home;
      case ExpenseCategory.electricity:
        return Icons.bolt;
      case ExpenseCategory.water:
        return Icons.water_drop;
      case ExpenseCategory.heating:
        return Icons.thermostat;

      // Vzdelávanie
      case ExpenseCategory.training:
        return Icons.school;
      case ExpenseCategory.books:
        return Icons.menu_book;
      case ExpenseCategory.courses:
        return Icons.cast_for_education;

      // Reprezentácia
      case ExpenseCategory.clientMeals:
        return Icons.dinner_dining;
      case ExpenseCategory.gifts:
        return Icons.card_giftcard;

      // Ostatné
      case ExpenseCategory.bankFees:
        return Icons.account_balance;
      case ExpenseCategory.other:
        return Icons.more_horiz;
    }
  }

  /// Farba pre kategóriu
  Color get color {
    switch (this) {
      // Doprava - Blue
      case ExpenseCategory.fuel:
      case ExpenseCategory.parking:
      case ExpenseCategory.carMaintenance:
      case ExpenseCategory.carWash:
      case ExpenseCategory.toll:
      case ExpenseCategory.taxi:
        return Colors.blue;

      // Kancelária - Purple
      case ExpenseCategory.officeSupplies:
      case ExpenseCategory.software:
      case ExpenseCategory.equipment:
      case ExpenseCategory.furniture:
        return Colors.purple;

      // Komunikácia - Green
      case ExpenseCategory.phone:
      case ExpenseCategory.internet:
      case ExpenseCategory.postage:
        return Colors.green;

      // Cestovné - Orange
      case ExpenseCategory.accommodation:
      case ExpenseCategory.meals:
      case ExpenseCategory.flights:
      case ExpenseCategory.trainTickets:
      case ExpenseCategory.publicTransport:
        return Colors.orange;

      // Poistenie - Red
      case ExpenseCategory.healthInsurance:
      case ExpenseCategory.carInsurance:
      case ExpenseCategory.liabilityInsurance:
        return Colors.red;

      // Služby - Amber
      case ExpenseCategory.accounting:
      case ExpenseCategory.legal:
      case ExpenseCategory.marketing:
      case ExpenseCategory.consulting:
        return Colors.amber;

      // Prevádzkové - Brown
      case ExpenseCategory.rent:
      case ExpenseCategory.electricity:
      case ExpenseCategory.water:
      case ExpenseCategory.heating:
        return Colors.brown;

      // Vzdelávanie - Indigo
      case ExpenseCategory.training:
      case ExpenseCategory.books:
      case ExpenseCategory.courses:
        return Colors.indigo;

      // Reprezentácia - Pink
      case ExpenseCategory.clientMeals:
      case ExpenseCategory.gifts:
        return Colors.pink;

      // Ostatné - Grey
      case ExpenseCategory.bankFees:
      case ExpenseCategory.other:
        return Colors.grey;
    }
  }

  /// Skupina kategórie (pre filtrovanie)
  String get group {
    switch (this) {
      case ExpenseCategory.fuel:
      case ExpenseCategory.parking:
      case ExpenseCategory.carMaintenance:
      case ExpenseCategory.carWash:
      case ExpenseCategory.toll:
      case ExpenseCategory.taxi:
        return 'Doprava';

      case ExpenseCategory.officeSupplies:
      case ExpenseCategory.software:
      case ExpenseCategory.equipment:
      case ExpenseCategory.furniture:
        return 'Kancelária';

      case ExpenseCategory.phone:
      case ExpenseCategory.internet:
      case ExpenseCategory.postage:
        return 'Komunikácia';

      case ExpenseCategory.accommodation:
      case ExpenseCategory.meals:
      case ExpenseCategory.flights:
      case ExpenseCategory.trainTickets:
      case ExpenseCategory.publicTransport:
        return 'Cestovné';

      case ExpenseCategory.healthInsurance:
      case ExpenseCategory.carInsurance:
      case ExpenseCategory.liabilityInsurance:
        return 'Poistenie';

      case ExpenseCategory.accounting:
      case ExpenseCategory.legal:
      case ExpenseCategory.marketing:
      case ExpenseCategory.consulting:
        return 'Služby';

      case ExpenseCategory.rent:
      case ExpenseCategory.electricity:
      case ExpenseCategory.water:
      case ExpenseCategory.heating:
        return 'Prevádzkové náklady';

      case ExpenseCategory.training:
      case ExpenseCategory.books:
      case ExpenseCategory.courses:
        return 'Vzdelávanie';

      case ExpenseCategory.clientMeals:
      case ExpenseCategory.gifts:
        return 'Reprezentácia';

      case ExpenseCategory.bankFees:
      case ExpenseCategory.other:
        return 'Ostatné';
    }
  }
}

/// Helper pre konverziu String -> ExpenseCategory
ExpenseCategory? expenseCategoryFromString(String? value) {
  if (value == null) return null;
  try {
    return ExpenseCategory.values.firstWhere(
      (e) => e.name == value,
    );
  } catch (e) {
    return null;
  }
}

/// Zoznam všetkých kategórií zoskupených podľa skupiny
Map<String, List<ExpenseCategory>> get groupedCategories {
  final Map<String, List<ExpenseCategory>> grouped = {};

  for (final category in ExpenseCategory.values) {
    final group = category.group;
    if (!grouped.containsKey(group)) {
      grouped[group] = [];
    }
    grouped[group]!.add(category);
  }

  return grouped;
}
