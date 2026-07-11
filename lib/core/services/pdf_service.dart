import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:intl/intl.dart';
import 'package:bizagent/features/invoices/models/invoice_model.dart';
import '../../features/settings/models/user_settings_model.dart';
import 'pay_by_square_service.dart';
import 'tax_calculation_service.dart';

final pdfServiceProvider = Provider<PdfService>((ref) {
  return PdfService();
});

/// Arguments wrapper for the isolate task
class InvoiceGenerationArgs {
  final InvoiceModel invoice;
  final UserSettingsModel settings;
  final ByteData fontRegularData;
  final ByteData fontBoldData;

  InvoiceGenerationArgs({
    required this.invoice,
    required this.settings,
    required this.fontRegularData,
    required this.fontBoldData,
  });
}

class PdfService {
  Future<Uint8List> generateInvoice(
      InvoiceModel invoice, UserSettingsModel settings) async {
    // Pre-load fonts in the main isolate to avoid platform channel issues in background isolate
    final fontRegular = await PdfGoogleFonts.interRegular();
    final fontBold = await PdfGoogleFonts.interBold();

    final args = InvoiceGenerationArgs(
      invoice: invoice,
      settings: settings,
      fontRegularData: (fontRegular as pw.TtfFont).data,
      fontBoldData: (fontBold as pw.TtfFont).data,
    );

    // Offload heavy PDF generation to a background isolate
    return compute(_generateInvoiceTask, args);
  }
}

/// Top-level function running in a separate isolate
Future<Uint8List> _generateInvoiceTask(InvoiceGenerationArgs args) async {
  final invoice = args.invoice;
  final settings = args.settings;

  final pdf = pw.Document();

  // Reconstruct fonts from bytes
  final font = pw.Font.ttf(args.fontRegularData);
  final fontBold = pw.Font.ttf(args.fontBoldData);

  final currency = NumberFormat.currency(locale: 'sk_SK', symbol: '€');
  final dateFormat = DateFormat('dd.MM.yyyy');
  final tax = TaxCalculationService();
  final isVatPayer = settings.isVatPayer;
  final taxLines =
      invoice.items.map((item) => item.toTaxLine(tax)).toList(growable: false);
  final taxTotals = tax.calcTotals(taxLines);

  pdf.addPage(
    pw.Page(
      pageFormat: PdfPageFormat.a4,
      margin: const pw.EdgeInsets.all(40),
      theme: pw.ThemeData.withFont(
        base: font,
        bold: fontBold,
      ),
      build: (pw.Context context) {
        return pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            // HEADER
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Text('FAKTÚRA',
                    style: pw.TextStyle(
                        fontSize: 24,
                        fontWeight: pw.FontWeight.bold,
                        color: PdfColors.blue800)),
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.end,
                  children: [
                    pw.Text('Číslo: ${invoice.number}',
                        style: pw.TextStyle(
                            fontWeight: pw.FontWeight.bold, fontSize: 14)),
                    if (invoice.variableSymbol != null)
                      pw.Text(
                          'Variabilný symbol: ${invoice.variableSymbol ?? ""}'),
                    if (invoice.constantSymbol != null)
                      pw.Text(
                          'Konštantný symbol: ${invoice.constantSymbol ?? ""}'),
                  ],
                ),
              ],
            ),
            pw.Divider(thickness: 2, color: PdfColors.blue800),
            pw.SizedBox(height: 20),

            // PARTIES
            pw.Row(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                // Dodavatel
                pw.Expanded(
                  child: pw.Container(
                    padding: const pw.EdgeInsets.all(10),
                    decoration: pw.BoxDecoration(
                      border: pw.Border.all(color: PdfColors.grey400),
                      borderRadius:
                          const pw.BorderRadius.all(pw.Radius.circular(4)),
                    ),
                    child: pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Text('DODÁVATEĽ:',
                            style: pw.TextStyle(
                                fontWeight: pw.FontWeight.bold,
                                fontSize: 10,
                                color: PdfColors.grey700)),
                        pw.SizedBox(height: 4),
                        pw.Text(
                            settings.companyName.isEmpty
                                ? 'Moja Firma'
                                : settings.companyName,
                            style: pw.TextStyle(
                                fontWeight: pw.FontWeight.bold, fontSize: 12)),
                        pw.Text(settings.companyAddress,
                            style: const pw.TextStyle(fontSize: 10)),
                        pw.SizedBox(height: 8),
                        if (settings.companyIco.isNotEmpty)
                          pw.Text('IČO: ${settings.companyIco}',
                              style: const pw.TextStyle(fontSize: 10)),
                        if (settings.companyDic.isNotEmpty)
                          pw.Text('DIČ: ${settings.companyDic}',
                              style: const pw.TextStyle(fontSize: 10)),
                        if (settings.companyIcDph.isNotEmpty)
                          pw.Text('IČ DPH: ${settings.companyIcDph}',
                              style: const pw.TextStyle(fontSize: 10)),
                        pw.SizedBox(height: 8),
                        if (settings.registerInfo.isNotEmpty)
                          pw.Text(settings.registerInfo,
                              style: const pw.TextStyle(
                                  fontSize: 8, color: PdfColors.grey700)),
                        pw.SizedBox(height: 8),
                        pw.Text('BANKOVÉ SPOJENIE:',
                            style: pw.TextStyle(
                                fontWeight: pw.FontWeight.bold,
                                fontSize: 10,
                                color: PdfColors.grey700)),
                        pw.Text('IBAN: ${settings.bankAccount}',
                            style: const pw.TextStyle(fontSize: 10)),
                        if (settings.swift.isNotEmpty)
                          pw.Text('SWIFT: ${settings.swift}',
                              style: const pw.TextStyle(fontSize: 10)),
                      ],
                    ),
                  ),
                ),
                pw.SizedBox(width: 20),
                // Odberatel
                pw.Expanded(
                  child: pw.Container(
                    padding: const pw.EdgeInsets.all(10),
                    decoration: pw.BoxDecoration(
                      border: pw.Border.all(color: PdfColors.grey400),
                      borderRadius:
                          const pw.BorderRadius.all(pw.Radius.circular(4)),
                    ),
                    child: pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Text('ODBERATEĽ:',
                            style: pw.TextStyle(
                                fontWeight: pw.FontWeight.bold,
                                fontSize: 10,
                                color: PdfColors.grey700)),
                        pw.SizedBox(height: 4),
                        pw.Text(invoice.clientName,
                            style: pw.TextStyle(
                                fontWeight: pw.FontWeight.bold, fontSize: 12)),
                        if (invoice.clientAddress != null)
                          pw.Text(invoice.clientAddress!,
                              style: const pw.TextStyle(fontSize: 10)),
                        pw.SizedBox(height: 8),
                        if (invoice.clientIco != null &&
                            invoice.clientIco!.isNotEmpty)
                          pw.Text('IČO: ${invoice.clientIco}',
                              style: const pw.TextStyle(fontSize: 10)),
                        if (invoice.clientDic != null &&
                            invoice.clientDic!.isNotEmpty)
                          pw.Text('DIČ: ${invoice.clientDic}',
                              style: const pw.TextStyle(fontSize: 10)),
                        if (invoice.clientIcDph != null &&
                            invoice.clientIcDph!.isNotEmpty)
                          pw.Text('IČ DPH: ${invoice.clientIcDph}',
                              style: const pw.TextStyle(fontSize: 10)),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            pw.SizedBox(height: 20),

            // DATES
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text(
                          'Dátum vystavenia: ${dateFormat.format(invoice.dateIssued)}',
                          style: const pw.TextStyle(fontSize: 10)),
                      pw.Text(
                          'Dátum dodania: ${dateFormat.format(invoice.dateSupply)}',
                          style: const pw.TextStyle(fontSize: 10)),
                    ]),
                pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.end,
                    children: [
                      pw.Text(
                          'Dátum splatnosti: ${dateFormat.format(invoice.dateDue)}',
                          style: pw.TextStyle(
                              fontSize: 10, fontWeight: pw.FontWeight.bold)),
                      pw.Text('Forma úhrady: Prevodom',
                          style: const pw.TextStyle(fontSize: 10)),
                    ]),
              ],
            ),
            pw.SizedBox(height: 20),

            if (!isVatPayer)
              pw.Padding(
                padding: const pw.EdgeInsets.only(bottom: 8),
                child: pw.Text(
                  'Dodávateľ nie je platiteľom dane z pridanej hodnoty.',
                  style: pw.TextStyle(
                    fontSize: 9,
                    fontStyle: pw.FontStyle.italic,
                    color: PdfColors.grey700,
                  ),
                ),
              ),

            // ITEMS TABLE
            pw.TableHelper.fromTextArray(
              context: context,
              border: null,
              headerStyle: pw.TextStyle(
                  fontWeight: pw.FontWeight.bold,
                  fontSize: 10,
                  color: PdfColors.white),
              headerDecoration:
                  const pw.BoxDecoration(color: PdfColors.blue800),
              cellStyle: const pw.TextStyle(fontSize: 10),
              cellHeight: 25,
              cellAlignments: isVatPayer
                  ? {
                      0: pw.Alignment.centerLeft,
                      1: pw.Alignment.centerRight,
                      2: pw.Alignment.centerRight,
                      3: pw.Alignment.centerRight,
                      4: pw.Alignment.centerRight,
                      5: pw.Alignment.centerRight,
                    }
                  : {
                      0: pw.Alignment.centerLeft,
                      1: pw.Alignment.centerRight,
                      2: pw.Alignment.centerRight,
                      3: pw.Alignment.centerRight,
                    },
              columnWidths: isVatPayer
                  ? {
                      0: const pw.FlexColumnWidth(4),
                      1: const pw.FlexColumnWidth(1),
                      2: const pw.FlexColumnWidth(2),
                      3: const pw.FlexColumnWidth(1),
                      4: const pw.FlexColumnWidth(1.5),
                      5: const pw.FlexColumnWidth(2),
                    }
                  : {
                      0: const pw.FlexColumnWidth(4),
                      1: const pw.FlexColumnWidth(1),
                      2: const pw.FlexColumnWidth(2),
                      3: const pw.FlexColumnWidth(2),
                    },
              headers: isVatPayer
                  ? [
                      'Popis',
                      'Mn.',
                      'J.cena bez DPH',
                      'DPH %',
                      'DPH €',
                      'Spolu',
                    ]
                  : ['Popis', 'Mn.', 'J.cena', 'Spolu'],
              data: List<List<String>>.generate(invoice.items.length, (index) {
                final item = invoice.items[index];
                final line = taxLines[index];
                if (isVatPayer) {
                  return [
                    item.description,
                    item.quantity.toString(),
                    currency.format(line.base),
                    TaxCalculationService.vatRateLabel(line.vatRate),
                    currency.format(line.vatAmount),
                    currency.format(line.total),
                  ];
                }
                return [
                  item.description,
                  item.quantity.toString(),
                  currency.format(line.base),
                  currency.format(line.base),
                ];
              }),
            ),
            pw.Divider(),

            // RECAPITULATION
            pw.Row(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                // Left side: Signature & QR
                pw.Expanded(
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.SizedBox(height: 20),
                      pw.Text('Faktúra slúži zároveň ako dodací list.',
                          style: const pw.TextStyle(
                              fontSize: 8, color: PdfColors.grey600)),
                      pw.Text('Vyhotovil: ${settings.companyName}',
                          style: const pw.TextStyle(
                              fontSize: 8, color: PdfColors.grey600)),
                      pw.SizedBox(height: 30),
                      pw.Container(
                        width: 150,
                        decoration: const pw.BoxDecoration(
                            border: pw.Border(
                                top: pw.BorderSide(color: PdfColors.grey400))),
                        child: pw.Center(
                            child: pw.Text('Podpis a pečiatka',
                                style: const pw.TextStyle(fontSize: 8))),
                      ),
                      pw.SizedBox(height: 20),
                      // QR Payment (PAY by square)
                      if (settings.showQrOnInvoice &&
                          (settings.iban?.isNotEmpty ?? false))
                        _buildQrPaymentBlock(
                          iban: settings.iban!,
                          beneficiaryName: settings.companyName,
                          amountEur: invoice.grandTotal,
                          variableSymbol: invoice.variableSymbol,
                          message: 'Faktura ${invoice.number}',
                          swift: settings.swift,
                          dateDue: invoice.dateDue,
                        ),
                    ],
                  ),
                ),

                // Right side: VAT Breakdown & Grand Total
                pw.Expanded(
                  child: pw.Column(
                    children: [
                      if (isVatPayer)
                        pw.Container(
                          margin: const pw.EdgeInsets.only(bottom: 10),
                          child: pw.TableHelper.fromTextArray(
                            border: pw.TableBorder.all(
                                color: PdfColors.grey300, width: 0.5),
                            headerStyle: pw.TextStyle(
                                fontSize: 8, fontWeight: pw.FontWeight.bold),
                            cellStyle: const pw.TextStyle(fontSize: 8),
                            headers: ['Sadzba', 'Základ', 'DPH', 'Spolu'],
                            data: taxTotals.vatBreakdown.entries.map((entry) {
                              final rate = entry.key;
                              final vat = entry.value;
                              final base = taxLines
                                  .where((line) => line.vatRate == rate)
                                  .fold<double>(
                                    0,
                                    (sum, line) => sum + line.base,
                                  );
                              return [
                                TaxCalculationService.vatRateLabel(rate),
                                currency.format(base),
                                currency.format(vat),
                                currency.format(base + vat),
                              ];
                            }).toList(),
                          ),
                        ),

                      // GRAND TOTAL
                      pw.Container(
                        padding: const pw.EdgeInsets.all(10),
                        color: PdfColors.blue50,
                        child: pw.Column(
                          children: [
                            pw.Row(
                                mainAxisAlignment:
                                    pw.MainAxisAlignment.spaceBetween,
                                children: [
                                  pw.Text(
                                      isVatPayer
                                          ? 'Základ celkom:'
                                          : 'Suma celkom:',
                                      style: const pw.TextStyle(fontSize: 10)),
                                  pw.Text(
                                      currency.format(taxTotals.baseTotal),
                                      style: const pw.TextStyle(fontSize: 10)),
                                ]),
                            if (isVatPayer)
                              pw.Row(
                                  mainAxisAlignment:
                                      pw.MainAxisAlignment.spaceBetween,
                                  children: [
                                    pw.Text('DPH celkom:',
                                        style:
                                            const pw.TextStyle(fontSize: 10)),
                                    pw.Text(
                                        currency.format(taxTotals.vatTotal),
                                        style:
                                            const pw.TextStyle(fontSize: 10)),
                                  ]),
                            pw.Divider(color: PdfColors.blue800),
                            pw.Row(
                                mainAxisAlignment:
                                    pw.MainAxisAlignment.spaceBetween,
                                children: [
                                  pw.Text('K ÚHRADE:',
                                      style: pw.TextStyle(
                                          fontWeight: pw.FontWeight.bold,
                                          fontSize: 14)),
                                  pw.Text(currency.format(taxTotals.grandTotal),
                                      style: pw.TextStyle(
                                          fontWeight: pw.FontWeight.bold,
                                          fontSize: 14,
                                          color: PdfColors.blue800)),
                                ]),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        );
      },
    ),
  );

  return pdf.save();
}

pw.Widget _buildQrPaymentBlock({
  required String iban,
  required String beneficiaryName,
  required double amountEur,
  required String? variableSymbol,
  required String? message,
  required String swift,
  required DateTime dateDue,
}) {
  // Generate PAY by square string (Slovak Standard)
  final payload = PayBySquareService.generateString(
    iban: iban,
    swift: swift.isEmpty ? 'UNKNOWNSWIFT' : swift,
    amount: amountEur,
    variableSymbol: variableSymbol ?? '',
    recipientName: beneficiaryName,
    note: message,
    dateDue: DateFormat('yyyy-MM-dd').format(dateDue),
  );

  return pw.Container(
    padding: const pw.EdgeInsets.all(12),
    decoration: pw.BoxDecoration(
      border: pw.Border.all(color: PdfColors.grey300),
      borderRadius: pw.BorderRadius.circular(10),
    ),
    child: pw.Row(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Container(
          width: 92,
          height: 92,
          child: pw.BarcodeWidget(
            barcode: pw.Barcode.qrCode(),
            data: payload,
            drawText: false,
          ),
        ),
        pw.SizedBox(width: 12),
        pw.Expanded(
          child: pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text('PAY by square',
                  style: pw.TextStyle(
                      fontSize: 12, fontWeight: pw.FontWeight.bold)),
              pw.SizedBox(height: 4),
              pw.Text('Naskenujte v bankovej appke.',
                  style: const pw.TextStyle(fontSize: 10)),
              pw.SizedBox(height: 8),
              pw.Text('IBAN: $iban', style: const pw.TextStyle(fontSize: 9)),
              if (variableSymbol != null && variableSymbol.trim().isNotEmpty)
                pw.Text('VS: ${variableSymbol.trim()}',
                    style: const pw.TextStyle(fontSize: 9)),
              pw.Text('Suma: ${amountEur.toStringAsFixed(2)} €',
                  style: const pw.TextStyle(fontSize: 9)),
            ],
          ),
        ),
      ],
    ),
  );
}
