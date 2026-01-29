# Changelog

All notable changes to BizAgent will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Added
- Complete project documentation (9 docs)
- Privacy Policy links in Settings footer

### Changed
- Improved email validation with real-time feedback

## [1.0.0] - 2026-01-17

### Added
- 🎉 Initial release
- Firebase Authentication (Email/Password)
- Invoice creation with automatic numbering (YYYY/XXX format)
- Invoice PDF generation with QR payment code
- Expense tracking with OCR receipt scanning
- Bank CSV import with automatic invoice matching
- ZIP export for accountants (invoices + expenses + summary)
- Tax calculation service (VAT 0%, 10%, 20%)
- QR payment support (EPC-QR standard)
- Dark mode toggle
- Multi-language support (SK primary, EN partial)
- Pull-to-refresh on Dashboard, Invoices, Expenses
- Undo action when deleting expenses
- Success screens after saving invoice/expense
- Visual feedback when adding invoice items

### Features by Module

#### Auth
- Email/password login & registration
- Firebase Authentication integration
- Auto-redirect based on auth state
- Debug fake login button

#### Invoices
- Create invoices with multiple line items
- Automatic invoice numbering (Firestore atomic increment)
- VAT calculation per line (0%, 10%, 20% rates)
- Invoice detail view with QR payment code
- PDF export (via `printing` package)
- Real-time sync via Firestore StreamProvider
- Variable symbol generation from invoice number

#### Expenses
- Manual expense entry
- OCR receipt scanning (ML Kit)
- Camera integration
- Swipe-to-delete with undo
- Date picker
- Amount extraction from OCR text

#### Dashboard
- Quick actions (5 tiles)
- Empty state with first-run banner
- Revenue & expense overview
- Upcoming tax deadlines widget

#### Bank Import
- CSV file picker
- Automatic column mapping (SK bank formats)
- Smart invoice matching (VS + amount)
- Match confirmation UI
- Transaction preview table

#### Export
- ZIP archive generation
- Invoices as PDFs
- Expenses as photos
- Summary CSV
- Data JSON backup
- Share via system share sheet
- Save to Files app

#### Settings
- Company info (IČO, DIČ, IČ DPH)
- Bank account (IBAN, SWIFT)
- VAT payer toggle
- QR code on invoice toggle
- Dark mode toggle
- Privacy Policy links (SK + EN)

### Technical

#### Architecture
- Clean architecture (core/features/shared)
- Riverpod for state management
- GoRouter for navigation with auth guard
- Feature module pattern
- Repository pattern for data access

#### Testing
- 17 unit & widget tests passing
- Test coverage: 75%+
- Provider override pattern for mocking
- Regression tests (BizEmptyState usage)
- CI/CD ready (GitHub Actions templates)

#### Firebase
- Firestore for data storage
- Firebase Auth for authentication
- Firebase Storage for expense photos
- Firebase Analytics for events
- Firebase Crashlytics for error tracking
- Security rules (user-scoped access)

#### Dependencies
- `flutter_riverpod: ^2.6.1` - State management
- `go_router: ^17.0.1` - Navigation
- `firebase_core: ^4.3.0` - Firebase
- `cloud_firestore: ^6.1.1` - Database
- `pdf: ^3.10.7` - PDF generation
- `google_mlkit_text_recognition: ^0.15.0` - OCR
- `qr_flutter: ^4.1.0` - QR codes
- `url_launcher: ^6.2.2` - External links
- Full list in `pubspec.yaml`

### Security
- Firebase Security Rules deployed
- No hardcoded secrets in git
- API keys in placeholder format
- Gitleaks scan passing
- GDPR compliant data handling
- Privacy policy published

### Documentation
- ✅ README.md - Project overview
- ✅ CONTRIBUTING.md - Contribution guidelines
- ✅ CHANGELOG.md - Version history
- ✅ docs/ARCHITECTURE.md - Architecture guide
- ✅ docs/SETUP.md - Development setup
- ✅ docs/DEPLOYMENT.md - Release process
- ✅ docs/SECURITY.md - Security practices
- ✅ docs/TESTING.md - Testing guide
- ✅ docs/TROUBLESHOOTING.md - Common issues
- ✅ docs/PLAY_STORE.md - Play Store checklist
- ✅ UX_IMPROVEMENTS.md - UX analysis & roadmap

### Known Issues
- Multiple FAB hero tags (workaround: unique tags)
- Starship prompt slowness (config optimization available)
- iOS CocoaPods setup required (documented)

## Release Notes Template

```markdown
## [X.Y.Z] - YYYY-MM-DD

### Added
- New features...

### Changed
- Modified features...

### Deprecated
- Soon-to-be-removed features...

### Removed
- Removed features...

### Fixed
- Bug fixes...

### Security
- Security improvements...
```

## Versioning Strategy

- **MAJOR** (X.0.0): Breaking changes, major redesign
- **MINOR** (0.X.0): New features, backward compatible
- **PATCH** (0.0.X): Bug fixes, minor improvements
- **BUILD** (+X): Every release, increments automatically

Example: `1.2.3+45`
- Version name: 1.2.3
- Version code (build): 45

---

[Unreleased]: https://github.com/youh4ck3dme/BizAgent/compare/v1.0.0...HEAD
[1.0.0]: https://github.com/youh4ck3dme/BizAgent/releases/tag/v1.0.0
