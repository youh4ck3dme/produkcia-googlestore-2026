# BIZAGENT COMPLETE UI/UX AUDIT & FIX MEGA PROMPT

## PROMPT 1: COMPLETE APP AUDIT & ANALYSIS

```
You are a senior UI/UX auditor and Google Material Design expert. I need you to perform a COMPREHENSIVE pixel-perfect audit of my BizAgent app and create a complete fix plan.

## APP CONTEXT
BizAgent is a PWA for SZČO/small businesses in Slovakia. Core features:
- Invoice generator (AI-powered)
- Contract & proposal templates 
- Email assistant
- Expense tracking dashboard
- Smart reminders
- Customer database

## YOUR MISSION
Analyze EVERY pixel of this app and create a complete redesign specification following these requirements:

### 1. COLOR SYSTEM - SLOVENSKÁ VLAJKA THEME
Primary colors MUST be derived from Slovak flag:
- **Primary Blue**: #0B4EA2 (from flag blue)
- **Primary Red**: #EE1C25 (from flag red) 
- **Primary White**: #FFFFFF (from flag white)
- **Secondary Blue Dark**: #083A7A (darker shade for depth)
- **Secondary Blue Light**: #4A90E2 (lighter for backgrounds)
- **Accent Red**: #C41E3A (darker red for CTAs)
- **Accent Red Light**: #FFE5E8 (light red for backgrounds)

Supporting colors:
- **Success Green**: #52B788 (approvals, success states)
- **Warning Amber**: #F59E0B (warnings, pending states)
- **Error Red**: Use Primary Red #EE1C25
- **Neutral Gray Scale**: 
 - Gray 50: #F9FAFB
 - Gray 100: #F3F4F6
 - Gray 200: #E5E7EB
 - Gray 300: #D1D5DB
 - Gray 400: #9CA3AF
 - Gray 500: #6B7280
 - Gray 600: #4B5563
 - Gray 700: #374151
 - Gray 800: #1F2937
 - Gray 900: #111827

### 2. DESIGN SYSTEM - GOOGLE MATERIAL DESIGN 3
Follow Material Design 3 (Material You) principles:
- **Typography**: Roboto font family
 - Display Large: 57px/64px, Regular
 - Display Medium: 45px/52px, Regular
 - Display Small: 36px/44px, Regular
 - Headline Large: 32px/40px, Regular
 - Headline Medium: 28px/36px, Regular
 - Headline Small: 24px/32px, Regular
 - Title Large: 22px/28px, Medium
 - Title Medium: 16px/24px, Medium
 - Title Small: 14px/20px, Medium
 - Body Large: 16px/24px, Regular
 - Body Medium: 14px/20px, Regular
 - Body Small: 12px/16px, Regular
 - Label Large: 14px/20px, Medium
 - Label Medium: 12px/16px, Medium
 - Label Small: 11px/16px, Medium

- **Spacing System**: 4px base unit
 - xs: 4px
 - sm: 8px
 - md: 16px
 - lg: 24px
 - xl: 32px
 - 2xl: 48px
 - 3xl: 64px

- **Border Radius**:
 - None: 0px
 - Small: 4px
 - Medium: 8px
 - Large: 12px
 - XLarge: 16px
 - XXLarge: 28px
 - Full: 9999px

- **Elevation (Shadows)**:
 - Level 0: none
 - Level 1: 0px 1px 2px rgba(0,0,0,0.3), 0px 1px 3px rgba(0,0,0,0.15)
 - Level 2: 0px 1px 2px rgba(0,0,0,0.3), 0px 2px 6px rgba(0,0,0,0.15)
 - Level 3: 0px 4px 8px rgba(0,0,0,0.15), 0px 1px 3px rgba(0,0,0,0.3)
 - Level 4: 0px 6px 10px rgba(0,0,0,0.15), 0px 1px 18px rgba(0,0,0,0.12)
 - Level 5: 0px 8px 12px rgba(0,0,0,0.15), 0px 4px 24px rgba(0,0,0,0.12)

### 3. COMPONENT REQUIREMENTS
Every component must follow Material Design 3 specs:

**Buttons**:
- Filled: Primary Blue background, white text, 8px radius, elevation 1
- Filled Tonal: Secondary Blue Light background, Primary Blue text
- Outlined: 1px Primary Blue border, Primary Blue text
- Text: No background, Primary Blue text
- FAB: 56x56px, Primary Red background, elevation 3
- Extended FAB: Min 80px width, 48px height

**Input Fields**:
- Outlined style (Material 3 default)
- 1px border Gray 300, focus: 2px Primary Blue
- 8px border radius
- 16px horizontal padding, 12px vertical padding
- Label: Gray 600, float on focus
- Helper text: 12px, Gray 500
- Error state: Primary Red border + text

**Cards**:
- White background
- 12px border radius
- Elevation 1 default, elevation 2 on hover
- 16px padding
- 16px gap between elements inside

**Navigation**:
- Bottom Navigation: 80px height, elevation 3
- Navigation Rail: 80px width (tablet/desktop)
- Top App Bar: 64px height, elevation 0 (use border bottom)

### 4. AUDIT CHECKLIST
Go through EVERY screen and check:

**Visual Consistency**:
□ Are ALL blues exactly #0B4EA2 (primary) or defined secondary shades?
□ Are ALL reds exactly #EE1C25 or defined accent shades?
□ No random colors used anywhere?
□ All grays from defined scale only?
□ Consistent spacing (4px multiples)?
□ Consistent border radius values?
□ Consistent shadow elevations?
□ Consistent font sizes from typography scale?

**Material Design Compliance**:
□ All buttons follow Material Design 3 specs?
□ All inputs are outlined style with proper states?
□ Cards have proper elevation and padding?
□ Icons are Material Symbols (not mixed icon sets)?
□ Touch targets minimum 48x48px?
□ Proper state layers (hover, pressed, focus)?

**Slovak Flag Theme Implementation**:
□ Primary actions use Blue #0B4EA2?
□ CTAs and alerts use Red #EE1C25?
□ White used for cards and backgrounds?
□ Color ratios follow 60-30-10 rule?
 - 60% White/light backgrounds
 - 30% Primary Blue accents
 - 10% Red for CTAs/important actions

**Functional Issues**:
□ All links working?
□ All forms submittable?
□ All buttons have actions?
□ Loading states exist?
□ Error states handled?
□ Empty states designed?
□ Success feedback shown?

### 5. DELIVERABLES
For each screen/component with issues, provide:

1. **Issue Description**: What's wrong (be specific)
2. **Current State**: Describe/show current implementation
3. **Fixed Code**: Complete corrected component code
4. **Why Changed**: Explanation of Material Design principle applied
5. **Color Usage**: Exact hex codes used and why

### 6. OUTPUT FORMAT
Structure your response as:
```

## SCREEN: [Screen Name]

### ISSUES FOUND:

1. [Issue 1 - Specific description]
1. [Issue 2 - Specific description]
 …

### FIXES APPLIED:

#### Fix 1: [Issue Name]

**Problem**: [Description]
**Material Design Principle**: [Which MD3 guideline this violates]
**Color Fix**: [Old color → New color with hex codes]

**CORRECTED CODE**:

```[language]
[Complete fixed component code]
```

**Visual Before/After**:

- Before: [Description of old state]
- After: [Description of new state following MD3]

```
### 7. PRIORITY AREAS
Focus heavily on:
1. **Dashboard** - First impression, must be perfect
2. **Invoice Generator** - Core feature, most used
3. **Forms** - All input fields must be consistent
4. **Buttons** - Every single button across app
5. **Navigation** - Bottom nav, top bar, drawer
6. **Color consistency** - No exceptions anywhere

### 8. GOOGLE PLAY REQUIREMENTS
Ensure compliance with:
- Material Design 3 for modern Android feel
- Proper touch targets (48dp minimum)
- Status bar color theming
- Splash screen following Android 12+ guidelines
- Adaptive icon support
- Dark mode support (using same Slovak flag colors in dark variants)

## NOW ANALYZE THIS APP CODE:

[PASTE YOUR BIZAGENT APP CODE HERE]

Begin the comprehensive audit. Go screen by screen, component by component. Leave NO pixel unchecked. Every color must be from the Slovak flag palette. Every component must follow Material Design 3 exactly.

Remember: This app is going to Google Play. It must look PROFESSIONAL and follow Google's design language PERFECTLY.
```

-----

## PROMPT 2: DARK MODE VARIANT GENERATOR

```
Now that we have the light theme perfected, create a complete DARK MODE variant following Material Design 3 dark theme principles while maintaining the Slovak flag color identity.

## DARK MODE COLOR SYSTEM

### Surface Colors
- **Surface**: #121212 (base dark surface)
- **Surface Variant**: #1E1E1E (elevated surfaces)
- **Surface Container Low**: #1A1A1A
- **Surface Container**: #1F1F1F 
- **Surface Container High**: #242424
- **Surface Container Highest**: #2A2A2A

### Slovak Flag Colors - Dark Variants
- **Primary Blue (Dark)**: #5AA3F0 (lighter blue for visibility)
- **Primary Blue Container**: #0D3A6B (darker blue background)
- **On Primary**: #FFFFFF
- **On Primary Container**: #C4E0FF

- **Secondary Red (Dark)**: #FF6B6B (lighter red for visibility)
- **Secondary Red Container**: #8B0A14 (darker red background)
- **On Secondary**: #FFFFFF 
- **On Secondary Container**: #FFD9DB

### Text Colors (Dark Mode)
- **On Surface**: #E8E8E8 (high emphasis text)
- **On Surface Variant**: #C4C4C4 (medium emphasis)
- **On Surface Disabled**: #6B6B6B (disabled text)

### Borders & Dividers
- **Outline**: #3D3D3D
- **Outline Variant**: #2C2C2C

Generate complete dark mode CSS/styling for all components following these specs.
```

-----

## PROMPT 3: MISSING COMPONENTS GENERATOR

```
Based on the BizAgent feature set, identify and generate ALL missing UI components that should exist but don't.

Expected components for a complete business app:

### Data Display
- [ ] Invoice preview card
- [ ] Customer card/list item
- [ ] Transaction row
- [ ] Analytics chart components
- [ ] Stats cards/widgets
- [ ] Timeline component (payment history)
- [ ] File attachment previews

### Forms & Inputs 
- [ ] Date picker (Material Design 3)
- [ ] Currency input with validation
- [ ] Client selector (autocomplete)
- [ ] Multi-select for services
- [ ] Tax rate calculator input
- [ ] File uploader with preview

### Feedback & States
- [ ] Loading skeleton screens
- [ ] Empty states (no invoices, no clients)
- [ ] Error states (failed to load)
- [ ] Success toast notifications
- [ ] Confirmation dialogs
- [ ] Progress indicators

### Navigation & Layout
- [ ] Bottom navigation (mobile)
- [ ] Navigation drawer (tablet+)
- [ ] Tab navigation within sections
- [ ] Breadcrumbs (desktop)
- [ ] Search bar with filters

### Actions & Interactions
- [ ] FAB with extended actions
- [ ] Context menus (right-click)
- [ ] Swipe actions (mobile lists)
- [ ] Bulk action toolbar
- [ ] Quick actions menu

For EACH missing component:
1. Generate complete code following Material Design 3
2. Use Slovak flag color scheme
3. Include all interaction states (hover, active, disabled)
4. Include responsive breakpoints
5. Include accessibility attributes

Output each component as production-ready code.
```

-----

## PROMPT 4: RESPONSIVE BREAKPOINT AUDIT

```
Audit the app for responsive design issues and generate fixes for all breakpoints:

### Material Design 3 Breakpoints
- **Mobile**: 0-599px (compact)
- **Tablet**: 600-839px (medium) 
- **Desktop**: 840-1239px (expanded)
- **Large Desktop**: 1240px+ (large)

For each breakpoint, check:

1. **Layout Adaptations**:
 - Navigation changes (bottom nav → nav rail → nav drawer)
 - Grid columns (1 → 2 → 3 → 4)
 - Card sizing and arrangement
 - Form layouts (stacked → side-by-side)

2. **Typography Scaling**:
 - Are font sizes appropriate per breakpoint?
 - Line heights adjusted for readability?
 - Max-width for text blocks (60-80 characters)?

3. **Spacing Adjustments**:
 - Padding increases with screen size?
 - Gutters appropriate for viewport?
 - Comfortable white space at all sizes?

4. **Touch vs Click**:
 - Touch targets 48px on mobile
 - Hover states only on desktop
 - Click targets can be smaller on desktop

Generate responsive CSS/code for ALL components ensuring perfect rendering at every breakpoint.

Use Material Design 3 responsive patterns:
- Canonical layouts for each size
- Supporting pane behavior
- Navigation transformations
- Density adjustments
```

-----

## PROMPT 5: ACCESSIBILITY (A11Y) COMPLIANCE

```
Audit and fix ALL accessibility issues to ensure WCAG 2.1 Level AA compliance:

### Color Contrast
Test EVERY color combination:
- Text on backgrounds: minimum 4.5:1 ratio
- Large text (18pt+): minimum 3:1 ratio 
- UI components: minimum 3:1 ratio

Slovak flag colors contrast check:
- Blue #0B4EA2 on white: ✓ Pass
- Red #EE1C25 on white: ✓ Pass
- White text on Blue: ✓ Pass
- White text on Red: ✓ Pass

Fix any failing combinations.

### Keyboard Navigation
- [ ] All interactive elements focusable
- [ ] Focus indicators visible (2px blue outline)
- [ ] Logical tab order
- [ ] Skip links present
- [ ] Modal traps working
- [ ] Keyboard shortcuts documented

### Screen Reader Support
- [ ] All images have alt text
- [ ] Form inputs have labels
- [ ] ARIA labels where needed
- [ ] ARIA live regions for dynamic content
- [ ] Landmark roles (<nav>, <main>, etc.)
- [ ] Heading hierarchy (h1 → h2 → h3)

### Interactive Elements
- [ ] Buttons have descriptive text/aria-label
- [ ] Links have descriptive text
- [ ] Form errors announced
- [ ] Success messages announced
- [ ] Loading states announced

Generate fixes for ALL accessibility issues found.
```

-----

## USAGE INSTRUCTIONS:

1. **Start with PROMPT 1**: Paste your entire BizAgent code
1. **Apply all fixes** from Prompt 1 output
1. **Run PROMPT 2**: Get dark mode variant
1. **Run PROMPT 3**: Get missing components
1. **Run PROMPT 4**: Get responsive fixes
1. **Run PROMPT 5**: Get accessibility fixes

Each prompt builds on the previous. By the end, you’ll have a **PIXEL-PERFECT, Google Play-ready app** with:

- Consistent Slovak flag color scheme
- Full Material Design 3 compliance
- No broken/missing components
- Perfect responsive design
- Full accessibility support
- Professional Google-quality UI/UX

**Pro Tip**: Run these prompts in OpenAI Codex or Claude with your codebase. The AI will literally go through every component and fix it according to these exact specifications.