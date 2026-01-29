# 5-Minute Onboarding Design for BizAgent PWA

**Target App:** AI-powered invoice management tool for small businesses in Slovakia
**Goal:** Create immediate WOW moment by demonstrating core value through AI-generated personalized demo data
**Platform:** PWA (responsive, offline-capable, installable)

## 1. Onboarding Flow Design

**Goal:** Within 5 minutes, users experience creating a professional invoice instantly via AI, building excitement for automation.

**Flow Structure (4 screens, ~3-4 minutes total):**

### 1. Welcome & Quick Setup (30 seconds)
- **Hero title:** "Vytvorte faktúru za sekundy s AI pomocou"
- **Minimal question:** "Čo je váš typ podnikania?" (dropdown: IT služby, Obchod, Remeslo, Iné)
- **Pre-filled:** Skip option ("Preskočiť a vyskúšať")
- **Auto-estimated:** Business type defaults to "IT služby" if skipped
- **Micro-interaction:** Animated AI brain icon processing input

### 2. AI Demo Generation (45 seconds)
- **Loading animation:** "AI generuje vašu ukážkovú faktúru..."
- **Progress bar with steps:** "Analyzujem typ podnikania... Vytváram klienta... Pridávam služby..."
- **Visual:** Floating invoice preview silhouette that fills with AI-generated content

### 3. Instant Preview & Customization (2 minutes)
- **Full invoice preview** with edit capabilities
- **Call-to-action:** "Upravte alebo vytvorte novú faktúru"
- **Quick actions:** "Uložiť ako vzor", "Vygenerovať PDF", "Začať odznova"
- **Progressive disclosure:** Expandable sections for advanced editing

### 4. Feature Teaser & Launch (1 minute)
- **Quick carousel** of 3 key features: "AI skenovanie bločkov", "Daňové predpovede", "Automatické pripomienky"
- **CTA:** "Začať používať BizAgent" (leads to dashboard)
- **Trust badges:** "7 dní zdarma", "GDPR compliant"

**Minimal Questions:** Only 1 optional dropdown for business type (max 2-3 options).

**Pre-filled/Auto-estimated:**
- Business type: Defaults to most common ("IT služby")
- Client data: AI-generated Slovak company (name, IČO, address) based on business type
- Invoice items: 2-3 relevant services/products with realistic pricing
- Dates: Current date + 14 days due date
- Numbers: Auto-generated sequential invoice number

## 2. AI Integrations for WOW Effect

### Primary WOW Feature: AI-Powered Instant Invoice Demo
- **How it works:** User selects business type → AI analyzes context → Generates complete personalized invoice draft with realistic data
- **User Experience Flow:**
  1. User selects "IT služby" → AI generates tech consulting invoice
  2. Preview shows professional invoice for "Webové služby s.r.o." with items like "Tvorba webu" (1200€), "SEO optimalizácia" (300€)
  3. User can immediately edit, save PDF, or regenerate
- **Value Creation:** Instant gratification - user sees their business type reflected in a real invoice within seconds
- **Engagement Boost:** Reduces friction by showing tangible results before account creation

### Secondary AI Features:
- **Personalized Client Generation:** AI creates Slovak business clients with valid IČO patterns
- **Smart Item Suggestions:** Context-aware services/products based on business type (e.g., "Konzultácie" for IT, "Reparačné práce" for trades)
- **Auto-optimization:** AI suggests VAT rates and payment terms based on Slovak regulations

## 3. Designer Cheat Sheet

### Screens (4 total, mobile-first, responsive):

#### 1. Welcome Screen:
- **Layout:** Centered hero with gradient background (white to blue)
- **Elements:** Large title (48pt), subtitle (16pt), dropdown (rounded, blue accent), skip button (text link)
- **Icons:** Animated brain icon (20x20px) during processing
- **Colors:** Primary blue (#0038A8), white background, red accents
- **Animations:** Dropdown slide-in, brain pulse animation

#### 2. AI Generation Screen:
- **Layout:** Full-screen loading with progress bar
- **Elements:** Circular progress indicator, step-by-step text updates, animated invoice silhouette
- **Colors:** Blue progress bar, white background
- **Animations:** Progress bar fill, text typewriter effect, invoice elements materializing

#### 3. Preview Screen:
- **Layout:** Invoice preview (A4 aspect ratio, scrollable), floating action buttons
- **Elements:** Invoice PDF-like design, edit buttons (pencil icons), save/share buttons
- **Colors:** Clean white invoice on gray background
- **Animations:** Fade-in of invoice content, expandable sections

#### 4. Launch Screen:
- **Layout:** Horizontal scrolling cards, bottom CTA button
- **Elements:** Feature cards (3) with icons and short descriptions, "Start" button
- **Colors:** Card backgrounds (light blue), icons (blue/red)
- **Animations:** Card slide-in from right, button press feedback

### Key UX Principles:
- Progressive disclosure (simple to complex)
- Immediate feedback for all interactions
- Mobile-optimized touch targets (44px minimum)
- Consistent Slovak language and business terminology
- Trust-building elements (progress indicators, realistic data)

### Wireframe Concepts:
- Screen 1: [Hero title] / [Dropdown] / [Skip link]
- Screen 2: [Progress circle] / [Animated invoice outline]
- Screen 3: [Invoice preview] / [Edit overlay buttons]
- Screen 4: [Feature carousel] / [CTA button]

## 4. Developer Cheat Sheet

### Required API/AI Calls:

#### 1. Business Type Selection Handler:
- **Function:** `onBusinessTypeSelected(String type)`
- **Purpose:** Prepares context for AI generation

#### 2. AI Invoice Generation:
- **Service:** `GeminiService.generateInvoiceDraft(Map<String, dynamic> data)`
- **Input:** `{'businessType': selectedType, 'country': 'SK', 'language': 'sk'}`
- **Output:** Complete invoice JSON with client, items, totals
- **Fallback:** Use static demo data if AI fails

#### 3. Client Data Generation:
- **Service:** `GeminiService.lookupCompanyByICO(String ico)` (for validation)
- **Alternative:** Custom prompt for Slovak company generation
- **Cache:** Store generated clients for demo purposes

#### 4. Invoice Preview Rendering:
- **Component:** `InvoicePreviewWidget` (reuse from create screen)
- **Data binding:** Real-time updates from AI response
- **PDF Generation:** `pdf` package integration for instant preview

#### 5. Analytics Tracking:
- **Events:** `onboarding_business_type_selected`, `onboarding_ai_generation_complete`, `onboarding_preview_shown`
- **Timing:** Track time spent on each screen (target: <5 minutes total)

### Backend Preparations:
- **Firebase Functions:** Deploy AI generation endpoint if client-side quota limits hit
- **Data Storage:** Demo invoices stored locally (not persisted to Firestore)
- **Authentication:** Anonymous auth for demo mode (already implemented)
- **Error Handling:** Graceful fallback to static demo data
- **Performance:** Pre-load AI models, cache common business types

### Data Structures:
```dart
class OnboardingDemoData {
  final String businessType;
  final Map<String, dynamic> generatedInvoice;
  final List<String> suggestedFeatures;
  final DateTime generatedAt;
}
```

### Integration Points:
- **Router:** Add `/onboarding-demo` route
- **State Management:** Extend `OnboardingProvider` with demo data
- **UI Components:** Reuse `CreateInvoiceScreen` components for preview

---

*Generated for BizAgent PWA - AI-powered invoice management for Slovak small businesses*
