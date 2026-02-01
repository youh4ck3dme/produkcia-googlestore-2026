# 🔐 Demo Účet - Informácie

## 📧 Údaje Demo Účtu

**Email:** `bizbizagent@bizbizagent.com`  
**Password:** *(NEUKLADAŤ do repozitára)*  
**Provider:** Email/Password (nie Google Sign-In!)

### Kde držať heslo bezpečne (lokálne)

1. Skopíruj šablónu:
   - `DEMO_ACCOUNT_SECRETS.example.txt` → `DEMO_ACCOUNT_SECRETS.txt`
2. Doplň `DEMO_PASSWORD=...`
3. Súbor `DEMO_ACCOUNT_SECRETS.txt` je v `.gitignore` (necommitne sa).

## 🚀 Rýchle Vytvorenie

### Krok 1: Otvor Firebase Console
👉 [https://console.firebase.google.com/project/bizagent-live-2026/authentication/users](https://console.firebase.google.com/project/bizagent-live-2026/authentication/users)

### Krok 2: Vytvor Účet
1. Klikni **"Add User"** (alebo **"Pridať používateľa"**)
2. Email: `bizbizagent@bizbizagent.com`
3. Password: *(použi hodnotu z `DEMO_ACCOUNT_SECRETS.txt`)*
4. **Zruš zaškrtnutie** "Send email verification"
5. Klikni **"Add User"**

### Krok 3: Overenie
✅ V stĺpci **"Provider"** musí byť ikona obálky (📧 Email), nie G (Google)

## 📝 Použitie

### Pre Google Play Console
Pri vypĺňaní **App Access** sekcie:
- **Username:** `bizbizagent@bizbizagent.com`
- **Password:** *(použi lokálne uložené demo heslo; neuvádzaj v repozitári)*

### Pre Testovanie
Skús sa prihlásiť v aplikácii s týmito údajmi.

## 📚 Ďalšia Dokumentácia

- [DEMO_ACCOUNT_SETUP.md](./docs/DEMO_ACCOUNT_SETUP.md) - Podrobný návod
- [GOOGLE_PLAY_SUBMISSION.md](./docs/GOOGLE_PLAY_SUBMISSION.md) - Google Play submission guide
- [RELEASE_CHECKLIST.md](./docs/RELEASE_CHECKLIST.md) - Pre-launch checklist

## 🔧 Skripty

- `./create_demo_account.sh` - Zobrazí inštrukcie na vytvorenie účtu
- `./create_demo_account.js` - Node.js skript (vyžaduje Firebase Admin SDK)
