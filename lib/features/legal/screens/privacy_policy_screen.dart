import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/ui/biz_theme.dart';

class PrivacyPolicyScreen extends StatelessWidget {
  const PrivacyPolicyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Ochrana osobných údajov (GDPR)'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Zásady ochrany osobných údajov',
              style: GoogleFonts.roboto(
                fontSize: 22.4, // Reduced by 20% (28 * 0.8)
                fontWeight: FontWeight.bold,
                color: BizTheme.slovakBlue,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Platné od: 21. januára 2026 • V súlade s GDPR',
              style: GoogleFonts.roboto(
                fontSize: 11.2, // Reduced by 20% (14 * 0.8)
                color: BizTheme.gray600,
              ),
            ),
            const SizedBox(height: 24),
            _buildSection(
              '1. Prevádzkovateľ',
              'Prevádzkovateľom aplikácie BizAgent je:\n\nBizAgent s.r.o.\nKontakt: support@bizagent.sk\n\nÚdaje o sídle a registrácii spoločnosti sú dostupné na vyžiadanie na uvedenej emailovej adrese.',
            ),
            _buildSection(
              '2. Aké údaje spracovávame',
              'V aplikácii BizAgent spracovávame nasledujúce údaje:\n\n• Vaše identifikačné údaje (meno, IČO, DIČ, adresa)\n• Údaje o faktúrach a klientoch\n• Údaje o výdavkoch a príjmoch\n• Fotografie účteniek (spracované lokálne pomocou Google ML Kit OCR)\n• Autentifikačné údaje (email, heslo - hashované)\n• Technické údaje (IP adresa, typ zariadenia)',
            ),
            _buildSection(
              '3. Účel spracovania',
              'Vaše údaje spracovávame na:\n\n• Poskytovanie služieb aplikácie BizAgent\n• Evidenciu fakturácie a výdavkov\n• Komunikáciu s vami\n• Zabezpečenie a zlepšenie našich služieb\n• Plnenie zákonných povinností',
            ),
            _buildSection(
              '4. Právny základ',
              'Údaje spracovávame na základe:\n\n• Vášho súhlasu (Čl. 6 ods. 1 písm. a) GDPR)\n• Plnenia zmluvy (Čl. 6 ods. 1 písm. b) GDPR)\n• Oprávneného záujmu (Čl. 6 ods. 1 písm. f) GDPR)',
            ),
            _buildSection(
              '5. Uchovávanie údajov',
              'Vaše údaje uchovávame:\n\n• Po dobu používania aplikácie\n• Archívne údaje podľa zákonných lehôt (napr. 10 rokov pre účtovné doklady)\n• Do odvolania súhlasu alebo vymazania účtu',
            ),
            _buildSection(
              '6. Zdieľanie údajov',
              'Vaše údaje môžeme zdieľať s:\n\n• Firebase/Google Cloud (hosting a databáza)\n• Google AI (Gemini) - len pre AI funkcie\n• Google ML Kit - OCR spracovanie fotografií účteniek (lokálne na zariadení)\n• Úrady (len v prípade zákonnej povinnosti)\n\nVaše údaje NEZDIEĽAME s tretími stranami na marketingové účely.',
            ),
            _buildSection(
              '7. Vaše práva',
              'Máte právo:\n\n• Na prístup k svojim údajom\n• Na opravu nesprávnych údajov\n• Na vymazanie údajov ("právo na zabudnutie")\n• Na obmedzenie spracovania\n• Na prenosnosť údajov\n• Namietať proti spracovaniu\n• Podať sťažnosť na Úrad na ochranu osobných údajov SR',
            ),
            _buildSection(
              '8. Zabezpečenie',
              'Vaše údaje sú:\n\n• Šifrované počas prenosu (TLS/SSL)\n• Uložené na bezpečných serveroch Google Cloud\n• ChránenéFirebaseAutentifikáciou\n• Pravidelne zálohované',
            ),
            _buildSection(
              '9. Cookies a analytika',
              'Aplikácia používa:\n\n• Firebase Analytics (anonymné štatistiky používania)\n• Nevyhnutné cookies na autentifikáciu\n\nAI funkcie (Gemini) spracovávajú vaše dotazy, ale neuchovávajú históriu.',
            ),
            _buildSection(
              '10. Zmeny zásad',
              'O zmenách týchto zásad vás budeme informovať v aplikácii. Odporúčame ich pravidelne kontrolovať.',
            ),
            _buildSection(
              '11. Kontaktujte nás',
              'V prípade otázok o ochrane vašich údajov:\n\nEmail: gdpr@bizagent.sk\nEmail (všeobecný): support@bizagent.sk\n\nOdpovieme do 30 dní od doručenia vašej žiadosti.',
            ),
            const SizedBox(height: 32),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: BizTheme.successGreen.withValues(alpha: 0.05),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: BizTheme.successGreen.withValues(alpha: 0.2)),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.lock,
                    color: BizTheme.successGreen,
                    size: 24,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Vaše súkromie je pre nás prioritou. Všetky údaje sú chránené podľa európskych štandardov GDPR.',
                      style: GoogleFonts.roboto(
                        fontSize: 11.2, // Reduced by 20% (14 * 0.8)
                        color: BizTheme.gray700,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSection(String title, String content) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: GoogleFonts.roboto(
              fontSize: 14.4, // Reduced by 20% (18 * 0.8)
              fontWeight: FontWeight.bold,
              color: BizTheme.gray900,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            content,
            style: GoogleFonts.roboto(
              fontSize: 15,
              height: 1.6,
              color: BizTheme.gray700,
            ),
          ),
        ],
      ),
    );
  }
}
