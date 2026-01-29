# Contributing to BizAgent

Ďakujeme za záujem prispieť k BizAgent! 🎉

## Quick Start

1. **Fork** repository
2. **Clone** tvoj fork: `git clone https://github.com/YOUR_USERNAME/BizAgent.git`
3. **Vytvor branch:** `git checkout -b feature/my-feature`
4. **Commit changes:** `git commit -m "feat: add my feature"`
5. **Push:** `git push origin feature/my-feature`
6. **Create Pull Request** na GitHube

## Development Workflow

### 1. Setup Environment

```bash
cd BizAgent
flutter pub get
flutter test  # Všetky testy musia byť zelené
```

Pre detailný setup pozri [docs/SETUP.md](docs/SETUP.md).

### 2. Create Feature Branch

**Branch naming:**
```bash
feature/invoice-templates     # Nová funkcionalita
fix/hero-tag-duplicate       # Bug fix
docs/update-architecture     # Dokumentácia
refactor/simplify-providers  # Refactoring
test/add-export-coverage     # Testy
```

### 3. Code Standards

#### Dart Style Guide

```dart
// ✅ Good
class InvoiceService {
  Future<void> createInvoice(InvoiceModel invoice) async {
    await _repository.save(invoice);
  }
}

// ❌ Bad
class invoice_service {
  Future<void> CreateInvoice(invoice) async { // No type
    _repository.save(invoice); // Missing await
  }
}
```

**Auto-format:**
```bash
dart format lib/ test/
```

#### File Organization

```dart
// 1. Imports (grouped)
import 'dart:async';              // Dart SDK

import 'package:flutter/material.dart';  // Flutter

import 'package:riverpod/riverpod.dart';  // External packages

import '../models/invoice_model.dart';    // Relative imports

// 2. Constants
const kDefaultTimeout = Duration(seconds: 10);

// 3. Providers
final invoiceProvider = Provider(...);

// 4. Classes
class InvoiceScreen extends StatelessWidget {
  // ...
}
```

### 4. Testing Requirements

**Každá nová funkcionalita MUSÍ mať testy:**

```bash
# Run all tests
flutter test

# Run specific test
flutter test test/features/invoices/invoice_service_test.dart

# Coverage check (min 75%)
flutter test --coverage
```

**Test pattern:**
```dart
// test/features/invoices/invoice_service_test.dart
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('InvoiceService', () {
    late InvoiceService service;
    
    setUp(() {
      service = InvoiceService();
    });
    
    test('should create invoice successfully', () async {
      // Arrange
      final invoice = InvoiceBuilder().build();
      
      // Act
      await service.createInvoice(invoice);
      
      // Assert
      expect(service.lastCreatedId, isNotEmpty);
    });
  });
}
```

### 5. Commit Guidelines

**Format:** `<type>(<scope>): <message>`

**Types:**
- `feat`: Nová funkcionalita
- `fix`: Bug fix
- `docs`: Dokumentácia
- `test`: Testy
- `refactor`: Refactoring bez zmeny functionality
- `style`: Formatting, whitespace
- `chore`: Build, dependencies

**Examples:**
```bash
git commit -m "feat(invoices): add PDF export button"
git commit -m "fix(auth): resolve login redirect loop"
git commit -m "docs: update ARCHITECTURE.md with router flow"
git commit -m "test(dashboard): add quick actions widget test"
```

### 6. Pull Request Process

#### Before Creating PR

```bash
# 1. Update from main
git fetch origin
git rebase origin/main

# 2. Run checks
flutter analyze
flutter test
dart format lib/ test/

# 3. Update CHANGELOG.md
# Add your changes under "Unreleased" section
```

#### PR Template

```markdown
## Description
Brief description of changes...

## Type of Change
- [ ] Bug fix
- [ ] New feature
- [ ] Breaking change
- [ ] Documentation update

## Testing
- [ ] Unit tests added/updated
- [ ] Widget tests added/updated
- [ ] Manual testing completed
- [ ] All tests passing (17/17)

## Screenshots (if applicable)
Before/after screenshots...

## Checklist
- [ ] Code follows project style guide
- [ ] Self-review completed
- [ ] Comments added for complex logic
- [ ] Documentation updated
- [ ] No new warnings from `flutter analyze`
- [ ] CHANGELOG.md updated
```

#### Review Process

1. **Automated checks** musia prejsť (GitHub Actions)
2. **Code review** od aspoň 1 maintainera
3. **Testing** - všetky testy musia byť zelené
4. **Approval** → Merge to main

## Code Review Guidelines

### For Authors

- Keep PRs small (<300 lines)
- Write clear commit messages
- Add tests for new code
- Update documentation
- Respond to review comments promptly

### For Reviewers

**Check:**
- [ ] Code style & formatting
- [ ] Test coverage adequate (≥75%)
- [ ] No hardcoded secrets
- [ ] Error handling present
- [ ] Performance implications
- [ ] Breaking changes documented

**Be constructive:**
```markdown
❌ "This is wrong."
✅ "Consider using StreamProvider instead of FutureProvider for real-time data. See lib/features/invoices/providers/invoices_provider.dart for example."
```

## Architecture Guidelines

### Feature Module Structure

```
features/my_feature/
├── data/
│   └── my_feature_repository.dart
├── models/
│   └── my_feature_model.dart
├── providers/
│   ├── my_feature_provider.dart
│   └── my_feature_controller.dart
├── screens/
│   └── my_feature_screen.dart
├── services/
│   └── my_feature_service.dart
└── widgets/
    └── my_feature_widget.dart
```

Pre viac info pozri [docs/ARCHITECTURE.md](docs/ARCHITECTURE.md).

### Provider Patterns

**StreamProvider** pre real-time Firebase data:
```dart
final myDataProvider = StreamProvider<List<MyModel>>((ref) {
  final uid = ref.watch(authStateProvider).value?.id;
  if (uid == null) return Stream.value([]);
  return ref.read(myRepositoryProvider).watchData(uid);
});
```

**StateNotifierProvider** pre complex state + business logic:
```dart
final myControllerProvider = 
    StateNotifierProvider<MyController, AsyncValue<void>>((ref) {
  return MyController(ref.read(myRepositoryProvider));
});
```

## Bug Reporting

Use `/reportbug` command alebo vytvor GitHub Issue:

**Include:**
- Clear bug description
- Steps to reproduce
- Expected vs actual behavior
- Screenshots/logs
- Environment (OS, Flutter version, device)

**Template:** See [GitHub Issue Template](.github/ISSUE_TEMPLATE/bug_report.md)

## Feature Requests

**Before requesting:**
1. Check existing issues/PRs
2. Consider if it fits project scope
3. Think about implementation complexity

**Template:**
```markdown
## Feature Description
What feature you want...

## Use Case
Why is this useful...

## Proposed Solution
How you'd implement it...

## Alternatives
Other approaches considered...
```

## Documentation

**Update documentation when:**
- Adding new feature
- Changing architecture
- Adding dependencies
- Changing API

**Docs to update:**
- `docs/ARCHITECTURE.md` - Architecture changes
- `docs/SETUP.md` - Setup process changes
- `README.md` - High-level overview
- Inline comments - Complex logic

## License

By contributing, you agree that your contributions will be licensed under the same license as the project (MIT).

## Questions?

- 📧 Email: youh4ck3dme@gmail.com
- 💬 GitHub Discussions: https://github.com/youh4ck3dme/BizAgent/discussions
- 🐛 Issues: https://github.com/youh4ck3dme/BizAgent/issues

## Recognition

Contributors are recognized in:
- [README.md](README.md) Contributors section
- Release notes
- Git history

Thank you for making BizAgent better! 🚀
