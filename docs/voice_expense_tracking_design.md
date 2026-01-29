# Voice-First Expense Tracking - Implementation Plan

## 🎯 **Overview**
Implement voice-powered expense entry to allow users to quickly add expenses by speaking naturally (e.g., "Kúpil som kávu za 3,50€ v Starbuckse"). This reduces manual data entry by 3x and improves user experience significantly.

## 🏗️ **Technical Architecture**

### **Core Components:**
1. **VoiceCaptureService** - Web Speech API wrapper
2. **ExpenseParserService** - AI-powered text parsing
3. **VoiceExpenseScreen** - Main UI component
4. **OfflineVoiceQueue** - Background processing

### **Tech Stack:**
- **Frontend:** Flutter Web + Web Speech API
- **AI:** Gemini Service for parsing
- **Storage:** Local storage for offline queue
- **State:** Riverpod for reactive updates

## 🎨 **UI/UX Design**

### **Main Voice Entry Screen:**
```
┌─────────────────────────────────────┐
│           🎙️ Voice Expense          │
│                                     │
│   [Tap to Speak] Button             │
│   (Large circular microphone)       │
│                                     │
│   "Say something like:"             │
│   "Kúpil som kávu za 3,50€"         │
│                                     │
│   ───────────────────────────────── │
│                                     │
│   Recent Expenses:                  │
│   • Káva - 3,50€ (dnes)            │
│   • Obed - 12,90€ (vcera)          │
│                                     │
└─────────────────────────────────────┘
```

### **Voice Processing Flow:**
1. **Listening State:** Pulsing microphone animation
2. **Processing State:** "Spracovávam..." with loading indicator
3. **Confirmation State:** Parsed expense with edit options
4. **Success State:** "Uložené ✓" with haptic feedback

### **Key UX Features:**
- **Wake word detection:** Start listening on "pridať výdavok" or "expense"
- **Continuous listening:** Process multiple expenses in one session
- **Visual feedback:** Real-time transcription display
- **Error recovery:** Easy retry options for failed parsing

## 🔧 **Implementation Details**

### **1. VoiceCaptureService**
```dart
class VoiceCaptureService {
  final SpeechToText _speech = SpeechToText();

  Future<String?> listenForExpense({
    Duration timeout = const Duration(seconds: 30),
    String language = 'sk-SK',
  }) async {
    // Initialize speech recognition
    final available = await _speech.initialize();
    if (!available) return null;

    String recognizedText = '';
    _speech.listen(
      onResult: (result) => recognizedText = result.recognizedWords,
      listenFor: timeout,
      localeId: language,
    );

    // Wait for completion or timeout
    await Future.delayed(timeout);
    _speech.stop();

    return recognizedText.isNotEmpty ? recognizedText : null;
  }
}
```

### **2. ExpenseParserService**
```dart
class ExpenseParserService {
  final GeminiService _gemini;

  Future<ParsedExpense?> parseExpenseText(String text) async {
    final prompt = '''
    Parsuj nasledujúci text o výdavku a vráť JSON:

    TEXT: "$text"

    VRÁŤ JSON vo formáte:
    {
      "description": "popis výdavku",
      "amount": 0.0,
      "category": "kategória",
      "date": "YYYY-MM-DD",
      "merchant": "obchodník (voliteľné)",
      "confidence": 0.0-1.0
    }

    Slovenský kontext - rozpoznaj bežné výrazy ako:
    - "kúpil som", "zaplatil som", "dal som"
    - meny v €, Sk, koruny
    - slovenské názvy obchodov
    ''';

    try {
      final response = await _gemini.analyzeJson(text, '''
      {
        "description": "string",
        "amount": "number",
        "category": "string",
        "date": "string",
        "merchant": "string",
        "confidence": "number"
      }
      ''');

      return ParsedExpense.fromJson(response);
    } catch (e) {
      return null;
    }
  }
}
```

### **3. Data Models**
```dart
class ParsedExpense {
  final String description;
  final double amount;
  final String category;
  final DateTime date;
  final String? merchant;
  final double confidence;

  ParsedExpense({
    required this.description,
    required this.amount,
    required this.category,
    required this.date,
    this.merchant,
    required this.confidence,
  });

  factory ParsedExpense.fromJson(Map<String, dynamic> json) {
    return ParsedExpense(
      description: json['description'],
      amount: json['amount'],
      category: json['category'],
      date: DateTime.parse(json['date']),
      merchant: json['merchant'],
      confidence: json['confidence'],
    );
  }
}

class VoiceExpenseSession {
  final String id;
  final DateTime startedAt;
  final List<String> rawTranscriptions;
  final List<ParsedExpense> parsedExpenses;
  final bool isCompleted;

  VoiceExpenseSession({
    required this.id,
    required this.startedAt,
    this.rawTranscriptions = const [],
    this.parsedExpenses = const [],
    this.isCompleted = false,
  });
}
```

### **4. Main Voice Expense Screen**
```dart
class VoiceExpenseScreen extends ConsumerStatefulWidget {
  const VoiceExpenseScreen({super.key});

  @override
  ConsumerState<VoiceExpenseScreen> createState() => _VoiceExpenseScreenState();
}

class _VoiceExpenseScreenState extends ConsumerState<VoiceExpenseScreen> {
  bool _isListening = false;
  String _currentTranscription = '';
  ParsedExpense? _parsedExpense;

  Future<void> _startListening() async {
    setState(() => _isListening = true);

    final voiceService = ref.read(voiceCaptureServiceProvider);
    final transcription = await voiceService.listenForExpense();

    if (transcription != null) {
      setState(() {
        _currentTranscription = transcription;
        _isListening = false;
      });

      await _parseExpense(transcription);
    } else {
      setState(() => _isListening = false);
      // Show error message
    }
  }

  Future<void> _parseExpense(String text) async {
    final parserService = ref.read(expenseParserServiceProvider);
    final parsed = await parserService.parseExpenseText(text);

    setState(() => _parsedExpense = parsed);
  }

  Future<void> _saveExpense() async {
    if (_parsedExpense == null) return;

    final expense = ExpenseModel(
      id: const Uuid().v4(),
      userId: ref.read(authStateProvider).value!.id,
      amount: _parsedExpense!.amount,
      description: _parsedExpense!.description,
      category: _parsedExpense!.category,
      date: _parsedExpense!.date,
      merchant: _parsedExpense!.merchant,
      createdAt: DateTime.now(),
      voiceTranscribed: true,
    );

    await ref.read(expensesControllerProvider.notifier).addExpense(expense);

    // Reset state
    setState(() {
      _currentTranscription = '';
      _parsedExpense = null;
    });

    // Show success message
    BizSnackbar.showSuccess(context, 'Výdavok uložený cez hlas!');
  }
}
```

## 📱 **Integration Points**

### **Navigation:**
- Add to expenses tab: "🎙️ Hlasový výdavok"
- Quick action button in expense list
- Integration with existing expense creation flow

### **Offline Support:**
- Queue voice transcriptions when offline
- Process when back online
- Local storage for pending expenses

### **Analytics:**
```dart
// Track voice usage
ref.read(analyticsServiceProvider).logVoiceExpenseStarted();
ref.read(analyticsServiceProvider).logVoiceExpenseCompleted(success: true);
```

## 🧪 **Testing Strategy**

### **Unit Tests:**
- VoiceCaptureService mock tests
- ExpenseParserService parsing accuracy
- Offline queue functionality

### **Integration Tests:**
- Full voice-to-expense flow
- Error handling scenarios
- Network connectivity changes

### **User Testing:**
- Accuracy of Slovak speech recognition
- Natural language parsing success rate
- Time savings vs manual entry

## 📈 **Success Metrics**

### **Primary:**
- **Adoption Rate:** % users who try voice input
- **Accuracy Rate:** % correctly parsed expenses
- **Time Savings:** Average time per expense entry

### **Secondary:**
- **Session Length:** How long users spend in voice mode
- **Error Recovery:** % failed parsings that get corrected
- **Retention:** Impact on user engagement

## 🚀 **Implementation Phases**

### **Phase 1: Core Functionality (2 weeks)**
- Basic voice capture
- Simple text parsing
- Expense creation integration
- Basic UI/UX

### **Phase 2: Polish & Features (1 week)**
- Advanced AI parsing
- Offline support
- Error handling improvements
- Analytics integration

### **Phase 3: Optimization (1 week)**
- Performance optimization
- Slovak language tuning
- Accessibility improvements
- A/B testing

## 💡 **Advanced Features (Future)**
- **Continuous Conversation:** "Pridaj kávu 3.50 a obed 12.90"
- **Category Learning:** AI learns user-specific categories
- **Smart Suggestions:** "Obvykle platíš 3.20 za kávu, je to správne?"
- **Receipt Photo + Voice:** Combine visual and voice data

---

**Estimated Development Time:** 4 weeks
**Priority:** High (Quick win, high user value)
**Risk Level:** Medium (Browser API compatibility)
