# 🚀 Bezpečný Backend pre Gemini AI

Aby bola aplikácia **"Tip Top"** pripravená pre Google Play/App Store a API kľúč bol v bezpečí, používame **Firebase Cloud Functions**. Kľúč nie je v aplikácii, ale na zabezpečenom serveri Google.

## 📋 Predpoklady

1. **Blaze Plan (Pay as you go)**
   - Musíte prepnúť projekt na **Blaze Plan** v [Firebase Console](https://console.firebase.google.com/project/bizagent-pwa-1768727460/overview) (vľavo dole).
   - *Prečo?* Cloud Functions vyžadujú Blaze pre prístup k externým sieťam a Google API.
   - *Cena?* Prvých 2 milióny volaní mesačne je zadarmo. Reálne nebudete platiť nič.

## 🔐 1. Nastavenie API Kľúčov (Secret Manager)

Namiesto vkladania kľúčov do súborov ich bezpečne uložíme do cloudu:

### Automatické nastavenie (ak máte kľúče v `.env`)

```bash
cd /Users/youh4ck3dme/Downloads/BizAgent-produkcia-google-play

# Nastavenie všetkých secrets naraz
echo "AIzaSyC_QQolZums9xyC7w4fqPT24_zhXBHCxjE" | firebase functions:secrets:set GEMINI_API_KEY
echo "ia_7b78c4d4ecfc53bf11599130dabfed3f36ea872b193f0eda" | firebase functions:secrets:set ICOATLAS_API_KEY
echo "6LfwZ1YsAAAAAB_vwAcbBl0SFk-NxfRap8vZjnSb" | firebase functions:secrets:set RECAPTCHA_API_KEY
```

### Manuálne nastavenie

1. Otvorte terminál v root adresári projektu.
2. Spustite príkaz:
   ```bash
   firebase functions:secrets:set GEMINI_API_KEY
   ```
3. Keď vás vyzve (Enter a value...), vložte váš **Gemini API Key**.
4. Opakujte pre ostatné kľúče:
   ```bash
   firebase functions:secrets:set ICOATLAS_API_KEY
   firebase functions:secrets:set RECAPTCHA_API_KEY
   ```

## 🚀 2. Nasadenie Backendu (Funkcie)

### Použitie deploy skriptu (odporúčané)

```bash
cd /Users/youh4ck3dme/Downloads/BizAgent-produkcia-google-play
./deploy_functions.sh
```

### Manuálne nasadenie

```bash
cd functions
npm install
npm run build
cd ..
firebase deploy --only functions
```

*(Tento proces môže trvať pár minút, inštaluje Node.js závislosti).*

**Dôležité:** 
- Firebase Functions vyžadujú Node.js verziu 20 (nie 25!)
- `.env` súbor je potrebný počas deployu (používa sa pre `defineString`)
- Secrets sa použijú automaticky v produkcii

## 🌐 3. Nasadenie Web Aplikácie

1. Vybuildujte a nasaďte frontend (už bez kľúča):
   ```bash
   flutter build web --release
   firebase deploy --only hosting
   ```

## ✅ Hotovo!
Teraz aplikácia pošle požiadavku na server → server bezpečne zavolá Gemini API s tajným kľúčom → a vráti výsledok.
Toto je najbezpečnejší "Enterprise" spôsob.
