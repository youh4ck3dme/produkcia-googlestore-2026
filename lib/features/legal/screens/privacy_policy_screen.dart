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
                fontSize: 22.4,
                fontWeight: FontWeight.bold,
                color: BizTheme.slovakBlue,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Platné od: 11. júla 2026 • V súlade s GDPR',
              style: GoogleFonts.roboto(
                fontSize: 11.2,
                color: BizTheme.gray600,
              ),
            ),
            const SizedBox(height: 24),
            _buildSection(
              '1. Prevádzkovateľ',
              'Prevádzkovateľom aplikácie BizAgent je:\n\nBizAgent s.r.o.\nKontakt: support@bizagent.sk\nGDPR: gdpr@bizagent.sk\n\nÚdaje o sídle a registrácii spoločnosti sú dostupné na vyžiadanie na uvedenej emailovej adrese.',
            ),
            _buildSection(
              '2. Aké údaje spracovávame',
              'V aplikácii BizAgent spracovávame nasledujúce údaje:\n\n• Vaše identifikačné údaje (meno, IČO, DIČ, adresa)\n• Údaje o faktúrach a klientoch\n• Údaje o výdavkoch a príjmoch\n• Autentifikačné údaje (email, heslo – hashované cez Supabase Auth)\n• Fotografie účteniek (nahraté do Supabase Storage; text z bločkov spracovaný lokálne cez Google ML Kit OCR)\n• AI prompty a história BizBot chatu (uložená v Supabase)\n• Technické údaje (anonymné analytické udalosti cez Firebase Analytics)',
            ),
            _buildSection(
              '3. Účel spracovania',
              'Vaše údaje spracovávame na:\n\n• Poskytovanie služieb aplikácie BizAgent\n• Evidenciu fakturácie a výdavkov\n• AI asistenciu (analýza dát, generovanie odpovedí)\n• Správu predplatného a in-app nákupov\n• Komunikáciu s vami\n• Zabezpečenie a zlepšenie našich služieb\n• Plnenie zákonných povinností',
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
              'Vaše údaje môžeme zdieľať s:\n\n• Supabase Inc. (EÚ, eu-central-1) – autentifikácia, databáza, úložisko, Edge Functions\n• Mistral AI a Google (Gemini) – spracovanie AI promptov (len pri aktívnom používaní AI funkcií)\n• Google ML Kit – OCR na zariadení\n• Google Firebase Analytics – anonymné štatistiky\n• Apple App Store / Google Play – spracovanie platieb\n• Google Firebase / Firestore (obmedzené legacy) – cache IČO, kategorizácia výdavkov\n• icoatlas.sk (voliteľné) – vyhľadávanie v obchodnom registri\n• Úradmi (len v prípade zákonnej povinnosti)\n\nVaše údaje NEZDIEĽAME s tretími stranami na marketingové účely.',
            ),
            _buildSection(
              '7. AI funkcie',
              'AI funkcie (BizBot, daňový asistent, generátor e-mailov, analýzy) spracovávajú vaše textové dotazy a relevantný obchodný kontext cez Supabase Edge Function, ktorá forwarduje prompty na Mistral AI (primárne) alebo Google Gemini (záložne). História BizBot chatu je uložená v Supabase do zmazania účtu. Odpovede AI sú iba informatívne a nenahrádzajú odborné poradenstvo.',
            ),
            _buildSection(
              '8. Predplatné a in-app nákupy',
              'Aplikácia ponúka voliteľné platené plány (sub_pro_monthly, sub_pro_year, sub_business_monthly, one_time_starter) spracované cez Apple App Store alebo Google Play Billing. Platobné údaje spracúva výhradne platforma obchodu; BizAgent neukladá údaje o platobnej karte.',
            ),
            _buildSection(
              '9. Vaše práva a vymazanie účtu',
              'Máte právo:\n\n• Na prístup k svojim údajom\n• Na opravu nesprávnych údajov\n• Na vymazanie údajov ("právo na zabudnutie")\n• Na obmedzenie spracovania\n• Na prenosnosť údajov\n• Namietať proti spracovaniu\n• Podať sťažnosť na Úrad na ochranu osobných údajov SR\n\nÚčet môžete vymazať:\n• V aplikácii: Nastavenia → Zmazať účet a všetky dáta (okamžite)\n• E-mailom: support@bizagent.sk\n• Web: https://bizagent.sk/delete-account.html',
            ),
            _buildSection(
              '10. Zabezpečenie',
              'Vaše údaje sú:\n\n• Šifrované počas prenosu (TLS/SSL)\n• Uložené na serveroch Supabase v EÚ (eu-central-1)\n• Chránené autentifikáciou a Row Level Security (RLS)\n• Edge Functions vyžadujú platnú prihlásenú reláciu',
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
                        fontSize: 11.2,
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
              fontSize: 14.4,
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
