import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart'
    deferred as ml show TextRecognizer, TextRecognitionScript, InputImage;
import 'package:image_picker/image_picker.dart';

final ocrServiceProvider = Provider<OcrService>((ref) {
  return OcrService();
});

class ParsedReceipt {
  final String? totalAmount;
  final String? date;
  final String? vendorId; // IČO
  final String originalText;
  final String? imagePath; // Local path to image

  ParsedReceipt({
    this.totalAmount,
    this.date,
    this.vendorId,
    required this.originalText,
    this.imagePath,
  });
}

class OcrService {
  // Use dynamic to avoid "Deferred types can't be used in variable declarations" error
  dynamic _textRecognizer;
  ImagePicker? _picker;

  Future<void> _ensureInitialized() async {
    if (_textRecognizer == null) {
      await ml.loadLibrary();
      _textRecognizer =
          ml.TextRecognizer(script: ml.TextRecognitionScript.latin);
    }
    _picker ??= ImagePicker();
  }

  Future<ParsedReceipt?> scanReceipt(ImageSource source) async {
    // 1. Web Guard
    if (kIsWeb) {
      debugPrint('⚠️ OCR is not supported on Web (ML Kit limitation).');
      // Return dummy receipt to prevent UI freeze/crash, or handle as error
      // Ideally show a Snackar, but here we just return safe empty/dummy data
      // so the app continues flow (e.g. user fills manually).
      return ParsedReceipt(
        originalText:
            "OCR skenovanie nie je dostupné vo webovej verzii.\nProsím, vyplňte údaje ručne alebo použite mobilnú aplikáciu.",
        totalAmount: null,
        date: null,
        vendorId: null,
      );
    }

    try {
      await _ensureInitialized();

      final pickedFile = await _picker!.pickImage(source: source);
      if (pickedFile == null) return null;

      final inputImage = ml.InputImage.fromFilePath(pickedFile.path);
      final recognizedText = await _textRecognizer!.processImage(inputImage);
      final text = recognizedText.text;

      return parseReceipt(text, imagePath: pickedFile.path);
    } catch (e) {
      debugPrint('Error scanning receipt: $e');
      return null;
    }
  }

  ParsedReceipt parseReceipt(String text, {String? imagePath}) {
    String? amount;
    String? date;
    String? vendorId;

    final lines = text.split('\n');

    // Regex Patterns
    final amountPattern = RegExp(
      r'(?:Celkom|Spolu|Suma|Total|Úhrada)[\s:.]*(\d+[\.,]\d{2})',
      caseSensitive: false,
    );
    // Matches DD.MM.YYYY or YYYY-MM-DD
    final datePattern = RegExp(
        r'(\d{1,2}[\.-]\d{1,2}[\.-]\d{4})|(\d{4}[\.-]\d{1,2}[\.-]\d{1,2})');
    final icoPattern =
        RegExp(r'(?:IČO|ICO)[\s:.]*(\d{8})', caseSensitive: false);

    for (final line in lines) {
      if (amount == null) {
        final amountMatch = amountPattern.firstMatch(line);
        if (amountMatch != null) {
          amount = amountMatch.group(1)?.replaceAll(',', '.');
        }
      }

      if (date == null) {
        final dateMatch = datePattern.firstMatch(line);
        if (dateMatch != null) {
          // Use group(0) to get the whole matched string, regardless of which alternative matched
          date = dateMatch.group(0);
        }
      }

      if (vendorId == null) {
        final icoMatch = icoPattern.firstMatch(line);
        if (icoMatch != null) {
          vendorId = icoMatch.group(1);
        }
      }
    }

    // Fallback search in full text if not found in lines
    if (amount == null) {
      // Look for standalone prices at the end of receipt often largest number
      // This is a naive heuristic, can be improved.
    }

    return ParsedReceipt(
      totalAmount: amount,
      date: date,
      vendorId: vendorId,
      originalText: text,
      imagePath: imagePath,
    );
  }

  void dispose() {
    _textRecognizer?.close();
  }
}
