// Test Firebase Cloud Functions pre Gemini API
// Spustiť: dart test_firebase_functions.dart
//
// POZNÁMKA:
// - Pre emulator: Uistite sa, že beží: firebase emulators:start --only functions
// - Pre produkciu: Najprv nasaďte funkciu: firebase deploy --only functions
// - Zmeňte useEmulator na false pre testovanie produkcie

import 'dart:convert';
import 'dart:io';

const String projectId = 'bizagent-live-2026';
const String functionName = 'generateContent';

// Zvoľte, či používať emulator alebo produkciu
const bool useEmulator = true; // Zmeňte na false pre produkciu

final String functionUrl = useEmulator
    ? 'http://localhost:5001/$projectId/us-central1/$functionName'
    : 'https://us-central1-$projectId.cloudfunctions.net/$functionName';

void main() async {
  print('🧪 Test Gemini Cloud Function');
  print('============================');
  print('');
  print('📋 Projekt: $projectId');
  print('🔗 URL: $functionUrl');
  print('🌐 Režim: ${useEmulator ? "Emulator (localhost:5001)" : "Produkcia"}');
  print('');

  const testPrompt = 'Napíš krátku odpoveď v slovenčine: Čo je BizAgent?';

  // Firebase callable functions očakávajú data priamo v root objekte
  final testData = {
    'prompt': testPrompt,
    'model': 'gemini-1.5-flash'
  };

  print('💬 Prompt: "$testPrompt"');
  print('');

  try {
    final client = HttpClient();
    final uri = Uri.parse(functionUrl);
    final request = await client.postUrl(uri);
    
    // Firebase callable functions očakávajú data v root objekte
    final requestBody = {'data': testData};
    final jsonString = jsonEncode(requestBody);
    final bodyBytes = utf8.encode(jsonString);
    
    request.headers.set('Content-Type', 'application/json');
    request.headers.set('Content-Length', bodyBytes.length.toString());
    request.add(bodyBytes);

    final response = await request.close();
    final responseBody = await response.transform(utf8.decoder).join();

    print('📊 Status: ${response.statusCode}');
    print('');

    if (response.statusCode == 200) {
      try {
        final result = jsonDecode(responseBody);
        print('✅ ÚSPECH!');
        print('');
        print('📝 Odpoveď:');
        print(result['result']?['text'] ?? result['text'] ?? responseBody);
      } catch (e) {
        print('⚠️  Neočakávaný formát odpovede:');
        print(responseBody);
      }
    } else {
      print('❌ CHYBA');
      print('');
      print('Status Code: ${response.statusCode}');
      print('');
      
      // Skús parsovať ako JSON
      try {
        final error = jsonDecode(responseBody);
        print('Chybová správa:');
        print(error['error']?['message'] ?? error['message'] ?? responseBody);
      } catch (e) {
        // Ak nie je JSON, zobraz raw odpoveď
        print('Odpoveď:');
        print(responseBody);
        
        // Ak je to 404 a emulator, možno funkcia nie je nasadená
        if (response.statusCode == 404 && useEmulator) {
          print('');
          print('💡 Tip: Skontrolujte, či je Firebase Emulator spustený:');
          print('   firebase emulators:start --only functions');
          print('');
          print('   Alebo použite produkciu (zmeňte useEmulator na false)');
        }
      }
    }

    client.close();
  } catch (e) {
    print('❌ CHYBA PRI VOLANÍ');
    print('');
    print(e.toString());
    exit(1);
  }
}
