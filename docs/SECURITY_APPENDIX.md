# 🧾 Security Appendix (for Google Play Review)

This document is intended for the Google Play Review team to explain the implementation of security and integrity services in the BizAgent app.

## 🛡️ Security Implementation Overview

### 1. App Integrity (Firebase App Check)
The application implements **Firebase App Check** to ensure that requests to our backend (Cloud Firestore, Cloud Functions) originate from an authentic, untampered version of our application.
*   **Provider:** Play Integrity API (Android).
*   **Enforcement:** Backend services use the App Check SDK to verify tokens on every incoming request.

### 2. Abuse Prevention (reCAPTCHA Enterprise)
To protect user authentication and form submissions from automated bots/spam:
*   We use **reCAPTCHA Enterprise** for high-risk actions (Login, Registration).
*   Assessment is performed server-side via Google's Enterprise Assessment API to ensure no client-side spoofing.

### 3. Data Protection
*   All user traffic is encrypted via **SSL/TLS**.
*   User business data (Invoices/Expenses) is isolated via **Firestore Security Rules**, ensuring that only the authenticated owner of the data UID can read or write to their respective documents.

## 🛠️ Verification Credentials
Standard testing credentials provided in the "App Access" section are authorized for all functionality covered by these security layers.
