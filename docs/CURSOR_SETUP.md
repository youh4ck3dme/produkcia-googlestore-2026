# BizAgent — otvorenie v Cursor

## Krok 1: Otvor správny priečinok

**NIKDY** neotváraj celý home (`~`). Otvor **iba**:

```
/Users/erikbabcan/Projects/02_Products/bizagent
```

### Možnosť A — workspace súbor (odporúčané)

```bash
open -a Cursor "/Users/erikbabcan/Projects/02_Products/bizagent/bizagent.code-workspace"
```

### Možnosť B — CLI

```bash
/Applications/Cursor.app/Contents/Resources/app/bin/cursor "/Users/erikbabcan/Projects/02_Products/bizagent"
```

### Možnosť C — Cursor UI

File → Open Folder → `Projects/02_Products/bizagent`

## Krok 2: Over že si na správnom mieste

V root priečinku musíš vidieť:

- `pubspec.yaml`
- `lib/`
- `test/` (94+ dart testov)
- `supabase/`
- `CANONICAL_SOURCE.md`

Ak vidíš `HUB/`, `Documents/` alebo 76 projektov — máš zlý workspace.

## Krok 3: Prvý beh

```bash
flutter pub get
flutter analyze
flutter test
```

Očakávaný výsledok: **366+ passed**, 19 skipped.

## Krok 4: Refresh prompty

Spusti postupne 3 prompty z `docs/CURSOR_REFRESH_PROMPTS.md` — každý v novom Agent chate s otvoreným **iba** týmto priečinkom.

## Čo je v projekte pripravené

| Súbor | Účel |
|-------|------|
| `bizagent.code-workspace` | Izolovaný Cursor workspace |
| `.cursorignore` | Skryje build, secrets, veľké assety pred AI |
| `.vscode/tasks.json` | Flutter test / analyze / run |
| `CANONICAL_SOURCE.md` | Mapa duplicitných kópií |