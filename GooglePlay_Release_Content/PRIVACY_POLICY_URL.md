# 🔒 Odkaz na Zásady ochrany osobných údajov (Privacy Policy URL)

**Google Play vyžaduje verejne dostupnú URL.** Bez toho aplikáciu nezverejníte.

## Riešenia

1. **GitHub Pages (odporúčané)**  
   - Vytvor repozitár (napr. `bizagent-privacy`).  
   - Pridaj súbor `index.html` s textom z `docs/PRIVACY_POLICY.md` (preformátovaný do HTML).  
   - Zapni GitHub Pages v Settings.  
   - URL bude napr. `https://tvojusername.github.io/bizagent-privacy/`.

2. **Notion**  
   - Vlož text zásad do stránky, zverejni ju (Share → Publish to web).  
   - Použi vygenerovanú URL.

3. **Vlastná doména (bizagent.sk)**  
   - Ak máš doménu, umiestni tam stránku, napr. `https://bizagent.sk/privacy`.

4. **Firebase Hosting**  
   - Text je v `docs/PRIVACY_POLICY.md`.  
   - Nahraj na Firebase Hosting a použij URL.

## Čo zadať v Google Play Console

- **App content** → **Privacy policy** → **Privacy policy URL**  
- Vlož jednu z vyššie uvedených URL (musí byť dostupná bez prihlásenia).

## Overenie

- Otvor URL v režime inkognito – stránka sa musí načítať.  
- Text musí zodpovedať tomu, čo aplikácia zbiera (email, fotky pre OCR, finančné údaje).
