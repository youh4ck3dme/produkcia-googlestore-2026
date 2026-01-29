# 🛡️ ReCaptcha Enterprise Setup

Tento dokument obsahuje kľúčové údaje a inštrukcie pre integráciu ReCaptcha Enterprise, ktorú si nakonfiguroval.

## 🔑 Kľúče a ID

*   **Projekt ID:** `bizagent-live-2026`
*   **Site Key (Web/Android):** `6Lf7dFQsAAAAALJbTSS5yaomUSvSNTpP4nr6GzlA`
*   **Action:** `LOGIN` (default action for auth verification)

---

## 🌐 Web Integration (Client Side)

Script bol automaticky pridaný do `web/index.html`:
```html
<script src="https://www.google.com/recaptcha/enterprise.js?render=6Lf7dFQsAAAAALJbTSS5yaomUSvSNTpP4nr6GzlA"></script>
```

Pre manuálne vyvolanie (ak nebude stačiť FlutterFire App Check):
```javascript
function onClick(e) {
  e.preventDefault();
  grecaptcha.enterprise.ready(async () => {
    const token = await grecaptcha.enterprise.execute('6Lf7dFQsAAAAALJbTSS5yaomUSvSNTpP4nr6GzlA', {action: 'LOGIN'});
    // Send token to backend
  });
}
```

---

## 🔙 Backend Verification (Server Side)

Toto je potrebné implementovať na strane servera (Firebase Cloud Functions), ak chceš overovať tokeny manuálne (napr. pre custom login flow).

### Request URL
`POST https://recaptchaenterprise.googleapis.com/v1/projects/bizagent-live-2026/assessments?key=API_KEY`

*   *API_KEY* nájdeš v Google Cloud Console -> APIs & Services -> Credentials.

### Request Body (`request.json`)
```json
{
  "event": {
    "token": "TOKEN_FROM_CLIENT",
    "expectedAction": "LOGIN",
    "siteKey": "6Lf7dFQsAAAAALJbTSS5yaomUSvSNTpP4nr6GzlA"
  }
}
```

### Response Check
Backend musí skontrolovať odpoveď:
1.  `tokenProperties.valid` musí byť `true`.
2.  `tokenProperties.action` musí sedieť (`LOGIN`).
3.  `riskAnalysis.score` by malo byť vysoké (0.0 - 1.0, kde 1.0 je človek).

---

## 📱 Android Integration

Pre Android verziu je najlepšie použiť **Firebase App Check**, ktorý automaticky použije ReCaptcha Enterprise alebo Play Integrity API.

1.  Choď do **Firebase Console** -> **App Check**.
2.  Registruj svoju Android aplikáciu (`com.bizagent.app`).
3.  Vlož SHA-256 fingerprint (z `keytool` alebo Play Console).
