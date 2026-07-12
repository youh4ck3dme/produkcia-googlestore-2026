# ✅ Checklist – Google Play Release

Pred vytvorením **BizAgent_GooglePlay_Release.zip** musí prebehnúť **kompletné otestovanie všetkých funkcií**.

---

## 1. Pred vytvorením ZIP

- [ ] **Flutter testy:** `flutter test` – všetky prejdú (0 failed).
- [ ] **Comprehensive test:** `./comprehensive_test.sh` – 0 failed.
- [ ] **Build AAB:** `./build_release_aab.sh` – úspešný build.
- [ ] **Manuálna kontrola:** Demo účet, prihlásenie, faktúry, výdavky, AI, skenovanie.

Ak niečo z toho zlyhá, oprav to alebo pozri `TEST_STATUS_RELEASE.md` v root projekte.

---

## 2. Obsah tohto priečinka (do ZIP)

| Súbor | Účel |
|-------|------|
| `STORE_LISTING_SK.md` | Názov, krátky a úplný popis pre Store listing |
| `PRIVACY_POLICY_URL.md` | Inštrukcie pre URL zásad ochrany súkromia |
| `graphics/` | Hotové PNG pre Play Console (512 ikona, 1024×500 feature, 4× 1080×1920) |
| `FEATURE_GRAPHIC_PROMPT.md` | Prompt pre regeneráciu feature graphic |
| `SCREENSHOTS_PROMPTS.md` | Prompty pre regeneráciu screenshotov |
| `CHECKLIST_GOOGLE_PLAY.md` | Tento checklist |

---

## 3. V Google Play Console

- [ ] **Store listing:** Skopíruj texty z `STORE_LISTING_SK.md`.
- [ ] **Privacy policy:** Pridaj verejnú URL podľa `PRIVACY_POLICY_URL.md`.
- [ ] **App icon:** `graphics/icon/hi-res-icon-512.png` (512×512)
- [ ] **Feature graphic:** `graphics/feature-graphic-1024x500.png` (1024×500)
- [ ] **Screenshots:** `graphics/screenshots/phone/01-dashboard.png` … `04-ai-tools.png` (1080×1920)
- [ ] **Regenerovať:** `./scripts/export_google_play_assets.sh` → skopíruj do `graphics/`
- [ ] **App access:** Demo účet `bizbizagent@bizbizagent.com` / heslo podľa `GOOGLE_PLAY_UPLOAD_CHECKLIST.md`.
- [ ] **Data Safety:** Podľa hlavného checklistu v root projekte.

---

## 4. Vytvorenie ZIP

V root adresári projektu:

```bash
./create_bizagent_googleplay_release_zip.sh
```

Bez `--force` skript najprv spustí `flutter test` a `comprehensive_test.sh`. Ak niečo zlyhá, ZIP sa nevytvorí.

S `--force` (iba ak si už všetko otestoval manuálne):

```bash
./create_bizagent_googleplay_release_zip.sh --force
```

Výstup: **BizAgent_GooglePlay_Release.zip** (AAB + tento obsah).
