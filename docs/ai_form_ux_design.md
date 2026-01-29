# Design Plan: AI-Powered Adaptive Forms

## Goal
Transform static Flutter forms into dynamic, intent-aware interfaces that minimize user friction using Gemini/LLM orchestration.

## 1. AI UX Strategy

### A. Dynamic Shortening (Contextual Hiding)
- **Logic**: Use a `Visibility` or `AnimatedSwitcher` wrapper on form fields.
- **Trigger**: AI analyzes the "creation intent" (e.g., "fast invoice").
- **Implementation**:
  - Regular clients: Hide address/tax ID fields by default (expandable via "Details").
  - Service-based vs. Product-based: Hide Qty/Unit fields if the user usually bills flat fees.

### B. Smart Pre-filling & Reordering
- **Pre-filling**: Pull from `Firestore` history. If client "X" was billed 500€ last month for "Consulting", pre-populate these.
- **Reordering**: Move high-priority fields (Amount, Item Title) to the top based on the specific template detected.

### C. One-Tap Fill (Magic Fill)
- **UI**: A "Magic Fill" floating bubble or prominent suggestion chip.
- **Safety**: Highlight pre-filled values in a subtle color (e.g., light blue background) to indicate "AI generated" and require a final confirmation before save.

---

## 2. Global AI Form Optimizer Prompt

This prompt is designed to be sent from the Flutter app to the LLM agent.

### System Role
`You are a Form UX Specialist. Your goal is to optimize a business form for speed and accuracy.`

### Input Schema
- `fields`: List of `{ "name": string, "type": "text"|"number"|"date"|"dropdown", "required": bool }`
- `userContext`: `{ "history": [...], "profile": {...}, "recentActivity": "..." }`
- `intent`: "Fast invoice", "Correction", "Regular monthly billing"

### Prompt Example
```json
{
  "fields": [
    {"name": "clientName", "type": "text", "required": true},
    {"name": "amount", "type": "number", "required": true},
    {"name": "dueDate", "type": "date", "required": false}
  ],
  "userContext": {
    "lastInvoice": {"client": "TechCorp", "amount": 1200, "description": "Dev Ops"},
    "defaults": {"dueDays": 14}
  },
  "intent": "Regular billing"
}
```

### Expected Output Structure
```json
{
  "optimizedOrder": ["clientName", "amount", "dueDate"],
  "defaultValues": {
    "clientName": "TechCorp",
    "amount": 1200,
    "description": "Dev Ops"
  },
  "fieldConfig": {
    "clientName": {"hidden": false, "optional": false},
    "clientAddress": {"hidden": true, "optional": true}
  },
  "confidence": 0.95
}
```
