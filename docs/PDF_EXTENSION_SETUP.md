# 📄 PDF Extension Setup pre Cursor

## 🚀 Rýchla Inštalácia

### Automatická (cez skript)
```bash
./install_pdf_extension.sh
```

### Manuálna Inštalácia

1. **Otvoriť Extensions:**
   - Stlač `Cmd+Shift+X` (macOS) alebo `Ctrl+Shift+X` (Windows/Linux)

2. **Vyhľadať PDF Extension:**
   - Do vyhľadávacieho poľa zadaj: `PDF`

3. **Nainštalovať:**
   - Klikni na **"PDF"** by Mathematic Inc
   - Klikni **"Install"**

## 📦 Odporúčané Extensions

### 1. PDF by Mathematic Inc ⭐ (Odporúčané)
- **ID:** `mathematic.vscode-pdf`
- **Installs:** 2.17M+
- **Rating:** 5/5
- **Features:**
  - Používa najnovšiu pdf.js knižnicu
  - Rýchle renderovanie
  - Bez memory leakov
  - Jednoduché a spoľahlivé

**Link:** https://marketplace.visualstudio.com/items?itemName=mathematic.vscode-pdf

### 2. Modern PDF Preview (WASM)
- **ID:** `chocolatedesue.modern-pdf-preview`
- **Features:**
  - Vysoký výkon (WebAssembly)
  - Anotácie (highlighting, drawing, notes)
  - Ukladanie zmien (Ctrl+S/Cmd+S)
  - Theme synchronizácia

**Link:** https://marketplace.visualstudio.com/items?itemName=chocolatedesue.modern-pdf-preview

### 3. Cursor AI PDF/DOCX Reader
- **ID:** `padg9912.pdf-docx-reader`
- **Features:**
  - Špeciálne navrhnuté pre Cursor
  - AI integrácia
  - Extrakcia textu a metadát
  - JSON/Text výstup

**Link:** https://marketplace.visualstudio.com/items?itemName=padg9912.pdf-docx-reader

## ✅ Overenie Inštalácie

Po inštalácii:

1. **Reštartuj Cursor** (Cmd+Q a znova otvor)

2. **Otvoriť PDF súbor:**
   - Klikni na `bizagentvssumuop.pdf` v Exploreri
   - PDF by sa mal automaticky otvoriť v preview móde

3. **Ak sa neotvorí automaticky:**
   - Klikni pravým tlačidlom na PDF súbor
   - Vyber **"Open With..."**
   - Vyber **"PDF Preview"** alebo **"PDF Viewer"**

## 🔧 Použitie

### Základné Funkcie
- **Zoom:** `Cmd/Ctrl +` alebo `Cmd/Ctrl -`
- **Fit to Width:** `Cmd/Ctrl 0`
- **Fit to Page:** `Cmd/Ctrl 1`
- **Next Page:** `Cmd/Ctrl →` alebo `Page Down`
- **Previous Page:** `Cmd/Ctrl ←` alebo `Page Up`

### Modern PDF Preview (ak máš túto extension)
- **Highlight:** Vyber text a klikni pravým tlačidlom → "Highlight"
- **Add Note:** Klikni na text → "Add Note"
- **Save Changes:** `Cmd/Ctrl + S`

## ⚠️ Známe Problémy

### PDF sa neotvára
- Skontroluj, či je extension nainštalovaná
- Reštartuj Cursor
- Skús otvoriť PDF cez "Open With..."

### Pomalé renderovanie
- Cursor môže byť pomalší ako VSCode pri PDF
- Skús použiť Modern PDF Preview (WASM) pre lepší výkon

### Zoom nefunguje
- Známý problém v Cursor
- Skús použiť Modern PDF Preview alebo PDF by Mathematic Inc

## 📚 Ďalšie Informácie

- [VSCode Marketplace - PDF Extensions](https://marketplace.visualstudio.com/search?target=vscode&category=All%20categories&sortBy=Installs&search=pdf)
- [Cursor Forum - PDF Support](https://forum.cursor.com/t/pdf-viewer-support-problem/39765)
