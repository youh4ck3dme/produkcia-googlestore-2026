import 'package:flutter/material.dart';
import '../../../core/ui/biz_theme.dart';
import '../../../core/services/tax_calculation_service.dart';
import '../../../core/models/soft_delete_model.dart';

enum InvoiceStatus { draft, sent, paid, overdue, cancelled }

extension InvoiceStatusX on InvoiceStatus {
  String toSlovak() {
    switch (this) {
      case InvoiceStatus.draft:
        return 'Návrh';
      case InvoiceStatus.sent:
        return 'Odoslaná';
      case InvoiceStatus.paid:
        return 'Zaplatená';
      case InvoiceStatus.overdue:
        return 'Po splatnosti';
      case InvoiceStatus.cancelled:
        return 'Zrušená';
    }
  }

  Color color(BuildContext context) {
    switch (this) {
      case InvoiceStatus.draft:
        return BizTheme.gray400;
      case InvoiceStatus.sent:
        return BizTheme.slovakBlue;
      case InvoiceStatus.paid:
        return BizTheme.successGreen;
      case InvoiceStatus.overdue:
        return BizTheme.nationalRed;
      case InvoiceStatus.cancelled:
        return BizTheme.gray600;
    }
  }
}

class InvoiceItemModel {
  final String title; // Changed from description for consistency
  final double amount; // Changed from quantity * unitPrice for NET amount
  final double vatRate;

  InvoiceItemModel({
    required this.title,
    required this.amount, // NET amount (bez DPH)
    required this.vatRate,
  });

  // For backward compatibility - create from old format
  factory InvoiceItemModel.fromOldFormat({
    required String description,
    required double quantity,
    required double unitPrice,
    double vatRate = 0.0,
  }) {
    return InvoiceItemModel(
      title: description,
      amount: quantity * unitPrice, // NET amount
      vatRate: vatRate,
    );
  }

  // Legacy getters for backward compatibility
  String get description => title;
  double get quantity => 1.0; // Simplified
  double get unitPrice => amount;
  double get subtotal => amount; // NET = subtotal
  double get vatAmount =>
      amount * vatRate; // raw, use TaxLine for proper rounding
  double get totalWithVat => amount + vatAmount;
  double get total => amount;

  // Tax calculation method
  TaxLine toTaxLine(TaxCalculationService tax) {
    return tax.calcLine(baseAmount: amount, vatRate: vatRate);
  }

  factory InvoiceItemModel.fromMap(Map<String, dynamic> map) {
    // Support both old and new formats
    final hasOldFormat =
        map.containsKey('description') && map.containsKey('quantity');

    if (hasOldFormat) {
      return InvoiceItemModel.fromOldFormat(
        description: map['description'] ?? '',
        quantity: (map['quantity'] ?? 0).toDouble(),
        unitPrice: (map['unitPrice'] ?? 0).toDouble(),
        vatRate: (map['vatRate'] ?? 0.0).toDouble(),
      );
    } else {
      // New format
      return InvoiceItemModel(
        title: map['title'] ?? map['description'] ?? '',
        amount: (map['amount'] ?? 0).toDouble(),
        vatRate: (map['vatRate'] ?? 0.0).toDouble(),
      );
    }
  }

  Map<String, dynamic> toMap() {
    return {
      'description': description,
      'quantity': quantity,
      'unitPrice': unitPrice,
      'vatRate': vatRate,
    };
  }
}

class InvoiceModel extends SoftDeleteModel {
  final String number;
  final String clientName;
  final String? clientAddress;
  final String? clientIco;
  final String? clientDic;
  final String? clientIcDph;
  final DateTime dateIssued;
  final DateTime dateDue;
  final List<InvoiceItemModel> items;
  final double totalAmount;
  final InvoiceStatus status;
  final String? pdfUrl;
  final String? variableSymbol;
  final String? constantSymbol;
  final DateTime? paymentDate;
  final String? paymentMethod;
  final bool isNumberProvisional;

  InvoiceModel({
    required super.id,
    required super.userId,
    required super.createdAt,
    super.deletedAt,
    super.deleteReason,
    required this.number,
    required this.clientName,
    this.clientAddress,
    this.clientIco,
    this.clientDic,
    this.clientIcDph,
    required this.dateIssued,
    required this.dateDue,
    required this.items,
    required this.totalAmount,
    required this.status,
    this.pdfUrl,
    this.variableSymbol,
    this.constantSymbol,
    this.paymentDate,
    this.paymentMethod,
    this.isNumberProvisional = false,
  });

  // VAT Calculations
  double get totalBeforeVat =>
      items.fold(0, (sum, item) => sum + item.subtotal);
  double get totalVat => items.fold(0, (sum, item) => sum + item.vatAmount);
  double get grandTotal => totalBeforeVat + totalVat;

  Map<double, double> get vatBreakdown {
    final breakdown = <double, double>{};
    for (var item in items) {
      breakdown[item.vatRate] = (breakdown[item.vatRate] ?? 0) + item.vatAmount;
    }
    return breakdown;
  }

  @override
  InvoiceModel copyWith({
    String? id,
    String? userId,
    DateTime? createdAt,
    DateTime? deletedAt,
    String? deleteReason,
    String? number,
    String? clientName,
    String? clientAddress,
    String? clientIco,
    String? clientDic,
    String? clientIcDph,
    DateTime? dateIssued,
    DateTime? dateDue,
    List<InvoiceItemModel>? items,
    double? totalAmount,
    InvoiceStatus? status,
    String? pdfUrl,
    String? variableSymbol,
    String? constantSymbol,
    DateTime? paymentDate,
    String? paymentMethod,
    bool? isNumberProvisional,
  }) {
    return InvoiceModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      createdAt: createdAt ?? this.createdAt,
      deletedAt: deletedAt,
      deleteReason: deleteReason,
      number: number ?? this.number,
      clientName: clientName ?? this.clientName,
      clientAddress: clientAddress ?? this.clientAddress,
      clientIco: clientIco ?? this.clientIco,
      clientDic: clientDic ?? this.clientDic,
      clientIcDph: clientIcDph ?? this.clientIcDph,
      dateIssued: dateIssued ?? this.dateIssued,
      dateDue: dateDue ?? this.dateDue,
      items: items ?? this.items,
      totalAmount: totalAmount ?? this.totalAmount,
      status: status ?? this.status,
      pdfUrl: pdfUrl ?? this.pdfUrl,
      variableSymbol: variableSymbol ?? this.variableSymbol,
      constantSymbol: constantSymbol ?? this.constantSymbol,
      paymentDate: paymentDate ?? this.paymentDate,
      paymentMethod: paymentMethod ?? this.paymentMethod,
      isNumberProvisional: isNumberProvisional ?? this.isNumberProvisional,
    );
  }

  factory InvoiceModel.fromMap(Map<String, dynamic> map, String id) {
    return InvoiceModel(
      id: id,
      userId: map['userId'] ?? '',
      createdAt: map['createdAt'] != null
          ? DateTime.parse(map['createdAt'])
          : DateTime.parse(map['dateIssued']), // fallback for old data
      deletedAt: map['deletedAt'] != null
          ? DateTime.parse(map['deletedAt'])
          : null,
      deleteReason: map['deleteReason'],
      number: map['number'] ?? '',
      clientName: map['clientName'] ?? '',
      clientAddress: map['clientAddress'],
      clientIco: map['clientIco'],
      clientDic: map['clientDic'],
      clientIcDph: map['clientIcDph'],
      dateIssued: DateTime.parse(map['dateIssued']),
      dateDue: DateTime.parse(map['dateDue']),
      items: (map['items'] as List<dynamic>?)
              ?.map((x) => InvoiceItemModel.fromMap(x))
              .toList() ??
          [],
      totalAmount: (map['totalAmount'] ?? 0).toDouble(),
      status: InvoiceStatus.values.firstWhere(
        (e) => e.name == (map['status'] ?? 'draft'),
        orElse: () => InvoiceStatus.draft,
      ),
      pdfUrl: map['pdfUrl'],
      variableSymbol: map['variableSymbol'],
      constantSymbol: map['constantSymbol'],
      paymentDate: map['paymentDate'] != null
          ? DateTime.parse(map['paymentDate'])
          : null,
      paymentMethod: map['paymentMethod'],
      isNumberProvisional: map['isNumberProvisional'] ?? false,
    );
  }

  @override
  Map<String, dynamic> toFirestore() {
    return {
      ...super.toFirestore(),
      'number': number,
      'clientName': clientName,
      'clientAddress': clientAddress,
      'clientIco': clientIco,
      'clientDic': clientDic,
      'clientIcDph': clientIcDph,
      'dateIssued': dateIssued.toIso8601String(),
      'dateDue': dateDue.toIso8601String(),
      'items': items.map((x) => x.toMap()).toList(),
      'totalAmount': totalAmount,
      'status': status.name,
      'pdfUrl': pdfUrl,
      'variableSymbol': variableSymbol,
      'constantSymbol': constantSymbol,
      'paymentDate': paymentDate?.toIso8601String(),
      'paymentMethod': paymentMethod,
      'isNumberProvisional': isNumberProvisional,
    };
  }

  // Legacy toMap for backward compatibility
  Map<String, dynamic> toMap() {
    return toFirestore();
  }
}
