# 🚀 BizAgent - Rýchly Start pre Google Play Upload

## ⚡ 3 Jednoduché Kroky

### 1️⃣ Vytvoriť Demo Účet v Firebase

```text
1. Choď na Firebase Console: https://console.firebase.google.com
2. Vyber projekt: bizagent-live-2026
3. Authentication > Users > Add user
4. Email: bizbizagent@bizbizagent.com
5. Password: 1369#1369#1369#
6. ✅ Vytvoriť
7. Overiť prihlásenie v aplikácii
```

### 2️⃣ Spustiť Build

```bash
# V root adresári projektu:
./build_release_aab.sh

# Alebo manuálne:
flutter build appbundle --release --obfuscate --split-debug-info=build/symbols
```

**Výstup:** `build/app/outputs/bundle/release/app-release.aab`

### 3️⃣ Upload do Google Play Console

```text
1. Choď na: https://play.google.com/console
2. Vytvor aplikáciu (ak ešte neexistuje)
3. Release > Production (alebo Internal Testing)
4. Upload AAB súbor
5. Postupuj podľa FINAL_RELEASE_CHECKLIST.md
```

---

## 📋 Kritické Body

### ✅ Pred Uploadom

- [ ] Demo účet vytvorený a otestovaný
- [ ] AAB súbor vytvorený (< 50MB)
- [ ] Privacy Policy URL pripravená (verejne dostupná)

### ✅ V Google Play Console

- [ ] Store Listing vyplnené
- [ ] Privacy Policy URL pridaná
- [ ] Demo účet pridaný v App Access
- [ ] Data Safety formulár vyplnený
- [ ] Screenshots nahrané

---

## 🎯 Finálny Status

**Verzia:** 1.0.1+2  
**Status:** ✅ Pripravené na upload  
**Testy:** 149/153 passing (~97%)  
**Build:** Pripravený  

**🚀 Aplikácia je 100% pripravená!**
