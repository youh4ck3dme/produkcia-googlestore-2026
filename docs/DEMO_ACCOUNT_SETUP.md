# 🔐 Demo Účet - Nastavenie

Tento dokument popisuje, ako vytvoriť a overiť demo účet pre Google Play review.

## 📋 Údaje Demo Účtu

- **Email:** `bizbizagent@bizbizagent.com`
- **Password:** `1369#1369#1369#`
- **Provider:** Email/Password (nie Google Sign-In!)

## 🚀 Vytvorenie Účtu

### Metóda 1: Manuálne cez Firebase Console (Odporúčané)

1. Choď na [Firebase Console](https://console.firebase.google.com/project/bizagent-live-2026/authentication/users)
2. Klikni na **"Add User"** (alebo **"Pridať používateľa"**)
3. Vyplň formulár:
   - **Email:** `bizbizagent@bizbizagent.com`
   - **Password:** `1369#1369#1369#`
   - **Send email verification:** ❌ (zruš zaškrtnutie - nie je potrebné pre demo účet)
4. Klikni **"Add User"**
5. **DÔLEŽITÉ:** Over, že v stĺpci **"Provider"** vidíš ikonu obálky (📧 Email), nie G (Google)

### Metóda 2: Pomocou Skriptu

```bash
# Zobraz inštrukcie
./create_demo_account.sh

# Alebo použij Node.js skript (ak máš Firebase Admin SDK)
node create_demo_account.js
```

**Poznámka:** Firebase CLI nepodporuje priame vytváranie používateľov, takže skript zobrazí manuálne inštrukcie.

## ✅ Overenie Účtu

### 1. V Firebase Console

1. Choď na [Firebase Console > Authentication > Users](https://console.firebase.google.com/project/bizagent-live-2026/authentication/users)
2. Nájdi user `bizbizagent@bizbizagent.com`
3. Over:
   - ✅ Účet existuje
   - ✅ Status je **"Enabled"**
   - ✅ Provider je **"password"** (nie "google.com")
   - ✅ Email je overený (alebo nie je potrebné pre demo)

### 2. Testovanie v Aplikácii

1. Spusti aplikáciu
2. Choď na prihlasovaciu obrazovku
3. Zadaj:
   - Email: `bizbizagent@bizbizagent.com`
   - Password: `1369#1369#1369#`
4. Klikni "Prihlásiť sa"
5. Over, že sa úspešne prihlásil

### 3. Testovanie v Firebase Console

1. Choď na [Firebase Console > Authentication > Users](https://console.firebase.google.com/project/bizagent-live-2026/authentication/users)
2. Nájdi user `bizbizagent@bizbizagent.com`
3. Klikni na tri bodky (⋮) vedľa účtu
4. Vyber **"Test User"** alebo **"Testovať používateľa"**
5. Over, že sa otvorí testovacia obrazovka

## 🔧 Riešenie Problémov

### Účet už existuje

Ak účet už existuje, môžeš:
1. **Aktualizovať heslo:**
   - Firebase Console > Authentication > Users
   - Klikni na účet
   - Klikni "Reset Password" alebo "Zmeniť heslo"
   - Nastav nové heslo: `1369#1369#1369#`

2. **Vymazať a vytvoriť znova:**
   - Firebase Console > Authentication > Users
   - Klikni na účet
   - Klikni "Delete User"
   - Vytvor nový účet podľa Metódy 1

### Provider je Google (nie Email/Password)

Ak vidíš v stĺpci "Provider" ikonu G (Google), účet bol vytvorený cez Google Sign-In.

**Riešenie:**
1. Vymazať účet
2. Vytvoriť nový účet manuálne cez Firebase Console
3. **DÔLEŽITÉ:** Použiť "Add User" (nie "Add Google User")

### Účet je disabled

Ak je účet disabled:
1. Firebase Console > Authentication > Users
2. Klikni na účet
3. Klikni "Enable User"

### Heslo nefunguje

1. Skontroluj, že heslo je presne: `1369#1369#1369#` (s # znakmi)
2. Skús resetovať heslo v Firebase Console
3. Over, že používaš správny email: `bizbizagent@bizbizagent.com`

## 📝 Pre Google Play Submission

Pri vypĺňaní formulára v Google Play Console:

1. **App Access** sekcia:
   - Vyber: "All or some functionality is restricted"
   - **Username:** `bizbizagent@bizbizagent.com`
   - **Password:** `1369#1369#1369#`
   - **Notes:** "This is a test account strictly for review purposes. It comes with pre-populated dummy data."

2. **Overenie:**
   - Účet musí existovať pred odoslaním aplikácie
   - Účet musí byť typu Email/Password
   - Účet musí byť Enabled

## 🔒 Bezpečnosť

- Demo účet je určený **len pre Google Play review**
- Po schválení aplikácie môžeš účet:
  - Nechať aktívny (pre budúce testovanie)
  - Alebo deaktivovať/vymazať
- Heslo je verejné (v Google Play Console), takže po review ho zmeň alebo účet vymazať

## 📞 Podpora

Ak máš problémy:
1. Skontroluj [TROUBLESHOOTING.md](./TROUBLESHOOTING.md)
2. Pozri Firebase Console > Authentication > Users
3. Skontroluj Firebase Console > Authentication > Settings > Sign-in method
