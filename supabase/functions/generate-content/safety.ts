/** Input/output safety for Google Play generative-AI policy compliance. */

const PROMPT_INJECTION_PATTERNS = [
  /ignore\s+(all\s+)?(previous|prior|above)\s+instructions/i,
  /disregard\s+(all\s+)?(previous|prior)\s+/i,
  /\bsystem\s*:\s*/i,
  /\bdeveloper\s*:\s*/i,
  /you\s+are\s+now\s+(a|an)\s+/i,
  /<\s*script\b/i,
];

const BLOCKED_OUTPUT_PATTERNS = [
  /\b(kill\s+yourself|self[- ]harm\s+instructions)\b/i,
  /\b(how\s+to\s+make\s+a\s+bomb|weapon\s+manufacturing)\b/i,
  /\b(child\s+sexual|csam)\b/i,
];

const SAFETY_SYSTEM_PREFIX =
  "Si BizAgent — asistent pre slovenských podnikateľov (účtovníctvo, faktúry, dane). " +
  "Neposkytuj nelegálne, násilné, sexuálne ani škodlivé rady. " +
  "Odpovedaj stručne, fakticky, v slovenčine. " +
  "Ak otázka nie je o podnikaní, účtovníctve alebo daniach, zdvorilo odmietni.\n\n";

export function validatePrompt(prompt: string): string | null {
  const trimmed = prompt.trim();
  if (!trimmed) return 'Parameter "prompt" je povinný.';
  if (trimmed.length > 10000) {
    return 'Parameter "prompt" je povinný (max 10 000 znakov).';
  }
  for (const pattern of PROMPT_INJECTION_PATTERNS) {
    if (pattern.test(trimmed)) {
      return "Prompt obsahuje nepodporovaný obsah.";
    }
  }
  return null;
}

export function wrapPromptForSafety(userPrompt: string): string {
  return `${SAFETY_SYSTEM_PREFIX}Otázka používateľa:\n${userPrompt}`;
}

export function filterModelOutput(text: string): string {
  const trimmed = (text || "").trim();
  if (!trimmed) return "AI nevrátilo žiadny text.";
  for (const pattern of BLOCKED_OUTPUT_PATTERNS) {
    if (pattern.test(trimmed)) {
      return "Odpoveď bola zablokovaná bezpečnostným filtrom. Skúste preformulovať otázku.";
    }
  }
  return trimmed;
}