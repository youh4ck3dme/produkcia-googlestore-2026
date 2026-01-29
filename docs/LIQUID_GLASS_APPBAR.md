# 🪞 Liquid Glass AppBar - Dokumentácia

**Dátum:** 2026-01-28  
**Status:** ✅ Implementované

---

## 🎯 Problém

Header (AppBar) bol transparentný a keď bol sticky, splyval so statickými textami v pozadí, čo spôsobovalo zlú čitateľnosť.

---

## ✅ Riešenie

Vytvorený **BizGlassAppBar** widget s liquid glass efektom, ktorý:
- ✅ Používa **BackdropFilter** s blur efektom (15px)
- ✅ Má **transparentné pozadie** s opacity 0.85
- ✅ Používa **gradient** pre liquid glass efekt
- ✅ Má **zvýšenú elevation** keď je sticky (`scrolledUnderElevation: 4`)
- ✅ Je **prehľadný** aj keď je transparentný

---

## 📁 Súbory

### 1. `lib/shared/widgets/biz_glass_appbar.dart`
Nový widget pre AppBar s liquid glass efektom.

**Vlastnosti:**
- `blurAmount` - Množstvo blur efektu (default: 15.0)
- `opacity` - Opacity pozadia (default: 0.85)
- `title`, `actions`, `leading` - Štandardné AppBar vlastnosti

**Použitie:**
```dart
BizGlassAppBar(
  title: Text('Nadpis'),
  actions: [
    IconButton(icon: Icon(Icons.search), onPressed: () {}),
  ],
)
```

### 2. `lib/core/ui/biz_theme.dart`
Aktualizovaný `AppBarTheme`:
- `backgroundColor: Colors.transparent` - Pre glass efekt
- `scrolledUnderElevation: 4` - Zvýšená elevation keď je sticky

### 3. Aktualizované Screeny
- ✅ `lib/features/dashboard/screens/dashboard_screen.dart`
- ✅ `lib/features/invoices/screens/invoices_screen.dart`
- ✅ `lib/features/expenses/screens/expenses_screen.dart`

---

## 🎨 Efekty

### Liquid Glass Efekt
- **BackdropFilter** s blur (sigmaX: 15, sigmaY: 15)
- **Gradient pozadie:**
  - Light mode: Biela (85% opacity) → Modrá (8.5% opacity)
  - Dark mode: Tmavá plocha (85% opacity) → Variant (68% opacity)
- **Border:** Tenký border na spodku (0.5px)
- **Elevation:** 0 normálne, 4 keď je sticky

### Prehľadnosť
- ✅ Text je vždy čitateľný
- ✅ Nezlučuje sa s pozadím
- ✅ Profesionálny vzhľad

---

## 🔧 Technické Detaily

### BackdropFilter
```dart
BackdropFilter(
  filter: ImageFilter.blur(sigmaX: blurAmount, sigmaY: blurAmount),
  child: Container(
    decoration: BoxDecoration(
      gradient: LinearGradient(...),
      border: Border(...),
    ),
  ),
)
```

### Gradient
**Light Mode:**
```dart
colors: [
  Colors.white.withValues(alpha: 0.85),
  BizTheme.slovakBlue.withValues(alpha: 0.085),
]
```

**Dark Mode:**
```dart
colors: [
  BizTheme.darkSurface.withValues(alpha: 0.85),
  BizTheme.darkSurfaceVariant.withValues(alpha: 0.68),
]
```

---

## 📝 Migrácia

### Pred:
```dart
appBar: AppBar(
  title: Text('Nadpis'),
  backgroundColor: Colors.white,
  elevation: 0,
)
```

### Po:
```dart
appBar: BizGlassAppBar(
  title: Text('Nadpis'),
)
```

---

## ✅ Výsledok

- ✅ Header je **prehľadný** aj keď je transparentný
- ✅ **Liquid glass efekt** dodáva profesionálny vzhľad
- ✅ Text je **vždy čitateľný**
- ✅ **Sticky state** má zvýšenú elevation pre lepšiu viditeľnosť
- ✅ **Konzistentný** vzhľad naprieč aplikáciou

---

## 🚀 Ďalšie Kroky

Pre aplikovanie na ďalšie screeny:
1. Importovať `BizGlassAppBar`
2. Nahradiť `AppBar` za `BizGlassAppBar`
3. Odstrániť `backgroundColor` a `elevation` (sú už v widgete)

---

**Všetko je pripravené a funguje!** 🎉
