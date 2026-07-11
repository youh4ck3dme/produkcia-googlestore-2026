# Google Play Store - Release Checklist

## Pre-Release Requirements

### 1. App Bundle (AAB)

```bash
# Build signed AAB
flutter build appbundle --release

# Output: build/app/outputs/bundle/release/app-release.aab
# Size target: <50MB
```

**Verify AAB:**
```bash
bundletool build-apks --bundle=app-release.aab --output=test.apks
bundletool install-apks --apks=test.apks
# Test na real device
```

### 2. App Signing

**Upload keystore info to Play Console:**
- Go to: Release → Setup → App integrity
- Enroll in Play App Signing
- Upload release keystore (one-time)

**Key info needed:**
```
Keystore alias: bizagent
Key validity: 10000 days
Key algorithm: RSA 2048-bit
```

### 3. Version Management

**pubspec.yaml:**
```yaml
version: 1.0.0+1
#        │ │ │  └─ versionCode (Android)
#        └─┴─┴──── versionName
```

**Increment rules:**
- versionCode: +1 každý release (never reuse!)
- versionName: Semantic versioning (MAJOR.MINOR.PATCH)

## Store Listing

### App Information

**App name:** BizAgent - Fakturácia pre SZČO  
**Short description (80 chars):**
```
Jednoduché fakturácie, výdavky a accounting pre slovenských podnikateľov
```

**Full description (4000 chars):**
```
🚀 BizAgent - Tvoj digitálny asistent pre podnikanie

Kompletné riešenie pre faktúry, výdavky a accounting, špeciálne navrhnuté pre slovenských SZČO a malé firmy.

✨ KĽÚČOVÉ FUNKCIE

📄 FAKTÚRY
• Automatické číslovanie faktúr (2026/001, 2026/002...)
• Podpora DPH (0%, 10%, 20%)
• QR platba na faktúre (EPC-QR kód)
• PDF export pripravený na tlač
• Variabilný symbol automaticky z čísla faktúry

💰 VÝDAVKY
• Skenovanie bločkov pomocou AI
• Automatické rozpoznávanie sumy
• Priraďovanie k projektom
• Fotodokumentácia výdavkov

🏦 BANK IMPORT
• Import výpisov z banky (CSV)
• Automatické párovanie s faktúrami
• Overenie platby podľa VS a sumy
• Podpora slovenských bánk

📊 EXPORT PRE ÚČTOVNÍKA
• ZIP balík s faktúrami (PDF)
• Fotky výdavkov
• CSV súhrn pre import do účtovníctva
• JSON backup všetkých dát

💼 PRE SZČO
• Sledovanie príjmov a výdavkov
• Prehľad DPH (pre platcov DPH)
• Pripomienky daňových termínov
• GDPR compliant

🔐 BEZPEČNOSŤ
• Dáta zabezpečené Firebase
• Prístup len pre vlastníka
• Privacy policy v slovenčine
• Žiadne zdieľanie dát s tretími stranami

📱 FUNKCIE
• Tmavý režim
• Offline mód (pripravuje sa)
• Automatické zálohovanie
• Pull-to-refresh na aktualizáciu dát

🇸🇰 SLOVENSKY DIZAJN
• Plná podpora slovenčiny
• IČO, DIČ, IČ DPH validácia
• IBAN SK formát
• QR platby podľa SR štandardov

📈 IDEÁLNE PRE:
✓ SZČO (živnostníkov)
✓ Freelancerov
✓ Malé firmy (s.r.o.)
✓ Účtovníkov
✓ Kohokoľvek, kto fakturuje

💡 PREČO BIZAGENT?
• Žiadne mesačné poplatky
• Jednoduchý a prehľadný
• Špeciálne pre SK trh
• Rýchla podpora v slovenčine

📞 PODPORA
Email: youh4ck3dme@gmail.com
Web: https://bizagent.sk

🔒 Privacy Policy: https://bizagent.sk/privacy-policy.html

Vyskúšaj BizAgent ešte dnes a zjednoduš si podnikanie! 🚀
```

**Category:** Business / Productivity  
**Tags:** faktúry, invoicing, accounting, SZČO, živnosť, DPH, QR platba

### Graphics Assets

#### App Icon
- **Size:** 512x512 px (PNG, 32-bit)
- **Format:** High-res icon
- **Design:** Blue gradient with "BA" logo
- **Upload:** Play Console → Store presence → App icon

#### Feature Graphic
- **Size:** 1024x500 px
- **Content:** "BizAgent - Fakturácia jednoducho"
- **Colors:** Brand colors (#2563EB blue)

#### Screenshots

**Required:** Min 2, Max 8 per device type

**Phone (Portrait):**
1. Dashboard s quick actions
2. Invoice creation screen
3. Invoice detail s QR kódom
4. Expense list s swipe-to-delete
5. Bank import screen
6. Settings screen

**Specs:**
- Min: 320px
- Max: 3840px  
- Aspect ratio: 16:9 to 2:1
- Format: PNG or JPEG

**Screenshot checklist:**
- [ ] Dark mode screenshots
- [ ] Demo data (not real customer info)
- [ ] Slovak language
- [ ] No personal data visible

#### Promotional Video (Optional)

- **Length:** 30-120 seconds
- **Content:** Quick app tour
- **YouTube link:** Upload to YouTube → Add link in Play Console

### Content Rating

**Questionnaire answers:**
- Violence: No
- Sexual content: No
- Profanity: No
- Drugs/Alcohol: No
- User-generated content: No
- Personal info sharing: Yes (business data)
- Location sharing: No

**Expected rating:** Everyone / PEGI 3

### Privacy Policy

**Required:** Yes (collects user data)

**URL:** `https://bizagent.sk/privacy-policy.html`

**Must include:**
- What data is collected (email, company info, invoices, expenses)
- How data is used (app functionality)
- How data is secured (Firebase, user-scoped)
- User rights (GDPR: access, deletion)
- Contact info (email)

**Languages:** Slovak (primary), English

### Data Safety Section

**Data collected:**

| Type | Purpose | Optional/Required |
|------|---------|-------------------|
| Email | Authentication | Required |
| Company info | Invoices | Required |
| Financial data | Tracking | Required |
| Photos | Expense receipts | Optional |

**Data security:**
- ✅ Data encrypted in transit (HTTPS)
- ✅ Data encrypted at rest (Firebase)
- ✅ User can request data deletion
- ✅ Data not shared with third parties
- ✅ Data not sold

**Answers:**
1. Does your app collect or share user data? **Yes**
2. Is data encrypted in transit? **Yes**
3. Can users request data deletion? **Yes**
4. Do you have a privacy policy? **Yes**

## Release Tracks

### Internal Testing (Alpha)

**Purpose:** Team testing pre-release  
**Audience:** 5-10 testers  
**Duration:** 1-2 days

**Testers:**
```
youh4ck3dme@gmail.com
test1@example.com
test2@example.com
```

**Checklist:**
- [ ] AAB uploaded
- [ ] Testers added
- [ ] Release notes in SK + EN
- [ ] Email sent to testers

### Closed Testing (Beta)

**Purpose:** Broader testing group  
**Audience:** 50-100 beta testers  
**Duration:** 1 week

**Feedback collection:**
- Google Form: Link in release notes
- In-app feedback button
- Email: youh4ck3dme@gmail.com

### Production

**Rollout strategy:**
1. **Day 1:** 10% rollout
2. **Day 3:** 25% (if crash-free >99%)
3. **Day 5:** 50% (if no critical bugs)
4. **Day 7:** 100% full rollout

**Monitoring:**
- Crashlytics crash-free users: >99%
- ANR rate: <0.5%
- Play Console vitals: Green
- User reviews: >4.0 stars

## Release Notes

**Format:** SK + EN translations

**Slovak (SK):**
```
Verzia 1.0.0

🎉 Prvé vydanie BizAgent!

✨ Nové funkcie:
• Vytváranie faktúr s automatickým číslovaním
• QR platba na faktúrach
• Skenovanie bločkov pomocou AI
• Import výpisov z banky
• Export pre účtovníčku (ZIP)
• Tmavý režim

🔧 Vylepšenia:
• Pull-to-refresh na aktualizáciu
• Vizuálny feedback pri akciách
• Vylepšená validácia emailu

Viac info: https://github.com/youh4ck3dme/BizAgent
```

**English (EN):**
```
Version 1.0.0

🎉 First release of BizAgent!

✨ Features:
• Invoice creation with auto-numbering
• QR payment on invoices
• AI receipt scanning
• Bank CSV import
• Accountant export (ZIP)
• Dark mode

🔧 Improvements:
• Pull-to-refresh
• Visual feedback
• Better email validation

More: https://github.com/youh4ck3dme/BizAgent
```

## Pre-Launch Checklist

### Technical

- [ ] All tests passing (17/17)
- [ ] No analyzer warnings
- [ ] APK size <50MB
- [ ] Min SDK: 21 (Android 5.0)
- [ ] Target SDK: 34 (Android 14)
- [ ] ProGuard rules configured
- [ ] Crashlytics integrated
- [ ] Analytics events defined

### Content

- [ ] App name finalized
- [ ] Description proofread (SK + EN)
- [ ] Screenshots prepared (6-8 images)
- [ ] Feature graphic created
- [ ] App icon 512x512 ready
- [ ] Privacy policy published
- [ ] Contact email verified

### Legal

- [ ] Privacy policy URL working
- [ ] Terms of Service (if needed)
- [ ] GDPR compliance verified
- [ ] Content rating completed
- [ ] Data safety answers submitted

### Marketing

- [ ] Landing page live (optional)
- [ ] Social media posts scheduled
- [ ] Email announcement draft
- [ ] Press kit prepared
- [ ] Launch date set

## Post-Launch

### Week 1

- [ ] Monitor Crashlytics daily
- [ ] Respond to reviews (<24h)
- [ ] Check vitals (ANR, crashes)
- [ ] Track installs/uninstalls
- [ ] Gather user feedback

### Week 2-4

- [ ] Analyze user behavior (Analytics)
- [ ] Plan hotfix if needed
- [ ] Prepare next version roadmap
- [ ] Update screenshots if needed
- [ ] A/B test store listing

## App Store Optimization (ASO)

### Keywords (SK)

Primary:
- faktúry
- fakturácia
- SZČO
- živnosť
- účtovníctvo

Secondary:
- DPH
- QR platba
- bloček
- export
- účtovník

### Competitor Analysis

**Similar apps:**
- Faktúroid
- iDoklad
- Superfaktura
- Invoice Simple

**Differentiation:**
- ✅ Slovak-first (nie len preklad)
- ✅ QR payment support
- ✅ Bank CSV import
- ✅ OCR receipt scanning
- ✅ Offline capable (coming soon)

## Support & Feedback

**In-app feedback:**
- Settings → "Poslať feedback"
- Link to: mailto:youh4ck3dme@gmail.com?subject=BizAgent%20Feedback

**Review prompts:**
- After 5 invoices created
- After 10 expenses added
- After successful export

**Target:** 4.5+ stars average

## Useful Links

- **Play Console:** https://play.google.com/console
- **Firebase Console:** https://console.firebase.google.com
- **App Bundle Explorer:** Play Console → Release → App bundle explorer
- **Pre-launch Report:** Automatic testing on real devices
- **Vitals:** Crashes, ANRs, battery usage

## Emergency Contacts

- **Play Console support:** Via Help in console
- **Firebase support:** Firebase Console → Support
- **Critical bugs:** youh4ck3dme@gmail.com (URGENT in subject)
