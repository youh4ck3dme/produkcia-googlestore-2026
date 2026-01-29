import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/ui/biz_theme.dart';

class TermsAndConditionsScreen extends StatelessWidget {
  const TermsAndConditionsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Obchodné podmienky'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Obchodné podmienky',
              style: GoogleFonts.roboto(
                fontSize: 22.4, // Reduced by 20% (28 * 0.8)
                fontWeight: FontWeight.bold,
                color: BizTheme.slovakBlue,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Platné od: 21. januára 2026',
              style: GoogleFonts.roboto(
                fontSize: 11.2, // Reduced by 20% (14 * 0.8)
                color: BizTheme.gray600,
              ),
            ),
            const SizedBox(height: 24),
            _buildSection(
              '1. Všeobecné ustanovenia',
              'BizAgent je aplikácia určená pre samostatne zárobkovo činné osoby (SZČO) a malé firmy na území Slovenskej republiky. Používaním tejto aplikácie akceptujete tieto obchodné podmienky.',
            ),
            _buildSection(
              '2. Služby',
              'Aplikácia poskytuje nástroje na:\n• Fakturáciu a evidenciu príjmov\n• Sledovanie výdavkov\n• Daňové kalkulácie a upomienky\n• AI asistenta pre podnikateľské otázky\n\nVšetky údaje sú spracovávané lokálne na vašom zariadení a synchronizované s Firebase Cloud (Google).',
            ),
            _buildSection(
              '3. Zodpovednosť',
              'Aplikácia slúži ako pomocný nástroj. Za správnosť daňových priznaní a dodržanie zákonných povinností zodpovedá výlučne používateľ. Odporúčame konzultovať všetky daňové záležitosti s odborníkom.',
            ),
            _buildSection(
              '4. Licencia',
              'Poskytujeme vám nevýhradnú, neprenosnú licenciu na používanie aplikácie BizAgent pre vaše podnikateľské účely. Nesmiem kopírovať, modifikovať alebo distribuovať aplikáciu bez nášho písomného súhlasu.',
            ),
            _buildSection(
              '5. Ukončenie služby',
              'Máte právo kedykoľvek prestať používať aplikáciu. Vaše dáta môžete exportovať pred ukončením.',
            ),
            _buildSection(
              '6. Zmeny podmienok',
              'Vyhradzujeme si právo zmeniť tieto podmienky. O zmenách vás budeme informovať prostredníctvom aplikácie.',
            ),
            _buildSection(
              '7. Kontakt',
              'V prípade akýchkoľvek otázok nás kontaktujte na: support@bizagent.sk',
            ),
            const SizedBox(height: 32),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: BizTheme.slovakBlue.withValues(alpha: 0.05),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: BizTheme.slovakBlue.withValues(alpha: 0.2)),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.verified_user,
                    color: BizTheme.slovakBlue,
                    size: 24,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Ďakujeme, že používate BizAgent. Vaše podnikanie je v bezpečných rukách.',
                      style: GoogleFonts.roboto(
                        fontSize: 11.2, // Reduced by 20% (14 * 0.8)
                        color: BizTheme.slovakBlue,
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
