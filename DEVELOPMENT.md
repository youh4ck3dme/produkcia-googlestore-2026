# 🛠 BizAgent Development Documentation

> **Status:** 🚧 In Active Development (MVP Phase)  
> **Version:** 1.0.0+1  
> **Last Updated:** January 17, 2026

## 1. Project Overview
**BizAgent** is a comprehensive Flutter application designed to assist freelancers (SZČO) and small businesses in Slovakia. It combines standard business management tools (invoicing, expense tracking) with AI-powered capabilities to automate administrative overhead.

### Core Value Proposition
*   **Automation**: OCR for receipts, auto-generated PDFs.
*   **Simplicity**: Streamlined UI/UX for non-technical users.
*   **Intelligence**: (Planned) AI assistant for financial insights.

---

## 2. Technical Architecture

The project adheres to a **Feature-First Clean Architecture**, prioritizing modularity and scalability.

### 2.1 Directory Structure
```
lib/
├── core/               # Shared functionality (Router, Theme, Services, Utils)
├── features/           # Modular features (Auth, Invoices, Expenses, etc.)
│   ├── [feature_name]/
│   │   ├── models/     # Data classes (freezed/json_serializable)
│   │   ├── providers/  # State management (Riverpod)
│   │   ├── screens/    # UI Pages
│   │   └── widgets/    # Feature-specific widgets
├── shared/             # Global shared widgets/models
└── app.dart            # Root widget (MaterialApp configuration)
```

### 2.2 Key Technologies
*   **State Management**: `flutter_riverpod` (v2.x). Uses `AsyncValue` for robust error/loading handling.
*   **Navigation**: `go_router` for declarative routing and deep linking. Includes a `GoRouterRefreshStream` for auth state listening.
*   **Backend**: Firebase ecosystem (Auth, Firestore, Storage, Functions).
*   **Local Services**:
    *   `pdf` & `printing`: Native PDF generation.
    *   `google_mlkit_text_recognition`: On-device OCR for privacy and speed.

---

## 3. Feature Deep Dives

### 🔐 Authentication (`features/auth`)
*   **Logic**: Managed by `AuthRepository` interacting with `FirebaseAuth`.
*   **State**: `authProvider` exposes the current user stream.
*   **Security**: `AppRouter` uses a redirect guard to protect non-login routes.

### 📄 Invoices (`features/invoices`)
*   **Data Model**: `InvoiceModel` includes nested `InvoiceItem` lists.
*   **PDF Generation**: `PdfService` (`core/services/pdf_service.dart`) compiles the invoice data + user settings (logo, company info) into a standardized A4 PDF.
*   **Storage**: Metadata in Firestore `users/{uid}/invoices`, PDFs optionally stored in Storage (currently generated on-fly).

### 💸 Expenses & OCR (`features/expenses`)
*   **OCR Workflow**:
    1.  User takes photo/selects image.
    2.  `OcrService` processes image using Google ML Kit.
    3.  Regex patterns extract "Total Amount", "Date", and "Vendor".
    4.  Data pre-fills the `CreateExpenseScreen` form.

### ⚙️ Settings (`features/settings`)
*   **Persistence**: Settings (Company Name, ICO, IBAN) are stored in Firestore `users/{uid}/settings` to sync across devices.
*   **Usage**: These settings are automatically injected into every generated Invoice PDF.

---

## 4. Development Roadmap (Next 3 Steps)

### 🚀 Step 1: Intelligent AI Assistant (`features/ai_tools`)
**Objective**: Transform the app from a "tracker" to an "agent".
*   **Implementation**:
    *   Connect to OpenAI API or use on-device LLM (e.g., Gemma/Llama via MediaPipe) for privacy.
    *   Implement "Chat with your Data": Allow users to ask "How much did I spend on gas last month?"
    *   Auto-categorization of expenses based on vendor name.

### 🧪 Step 2: Comprehensive Testing Strategy
**Objective**: Ensure stability before public release.
*   **Unit Tests**: Cover `OcrService` regex logic and `InvoiceModel` calculations.
*   **Widget Tests**: Verify critical flows (Login -> Dashboard -> Create Invoice).
*   **Integration Tests**: Test Firestore interactions using Firebase Emulator Suite.

### 📧 Step 3: Advanced Invoicing Features
**Objective**: Complete the billing cycle.
*   **Email Sending**: Integrate SendGrid or Firebase Extensions (Trigger Email) to send PDFs directly to clients.
*   **Recurring Invoices**: Cloud Functions cron job to auto-generate monthly invoices.
*   **Multi-currency Support**: Fetch live rates for international clients.

---

## 5. Developer Guidelines

### Adding a New Feature
1.  Create folder `lib/features/new_feature`.
2.  Define `models/`.
3.  Create `repository` (data source).
4.  Create `provider` (controller).
5.  Build `screens` and `widgets`.
6.  Register route in `core/router/app_router.dart`.

### Code Style
*   Use `const` constructors wherever possible.
*   Follow strict linting rules (`flutter_lints`).
*   Prefer `ConsumerWidget` over `ConsumerStatefulWidget` unless lifecycle methods are needed.
