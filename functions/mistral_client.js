const MISTRAL_API_URL = "https://api.mistral.ai/v1/chat/completions";

const isRetryableStatus = (status) =>
  status === 401 || status === 403 || status === 429 || status === 402 || status === 503;

/**
 * Volá Mistral chat/completions — primárny kľúč, pri chybe kľúča/kvóty záložný.
 * @returns {{ text: string, model: string, keySlot: 'primary' | 'backup' }}
 */
async function callMistralWithFallback({ prompt, keys, model = "mistral-small-latest" }) {
  const keyList = (keys || []).filter((k) => typeof k === "string" && k.trim().length > 0);
  if (keyList.length === 0) {
    throw new Error("Mistral: žiadny API kľúč");
  }

  let lastError = null;

  for (let i = 0; i < keyList.length; i++) {
    const apiKey = keyList[i];
    const keySlot = i === 0 ? "primary" : "backup";

    try {
      const response = await fetch(MISTRAL_API_URL, {
        method: "POST",
        headers: {
          Authorization: `Bearer ${apiKey}`,
          "Content-Type": "application/json",
        },
        body: JSON.stringify({
          model,
          messages: [{ role: "user", content: prompt }],
          temperature: 0.7,
          max_tokens: 2000,
        }),
        signal: AbortSignal.timeout(30000),
      });

      const raw = await response.text();
      let data = {};
      try {
        data = raw ? JSON.parse(raw) : {};
      } catch {
        data = { raw };
      }

      if (!response.ok) {
        const err = new Error(
          data?.message || data?.error?.message || `Mistral HTTP ${response.status}`,
        );
        err.status = response.status;
        lastError = err;

        if (i < keyList.length - 1 && isRetryableStatus(response.status)) {
          console.warn(`Mistral ${keySlot} key failed (${response.status}), trying backup...`);
          continue;
        }
        throw err;
      }

      const text = data.choices?.[0]?.message?.content || "";
      return {
        text: text || "AI nevrátilo žiadny text.",
        model: data.model || model,
        keySlot,
      };
    } catch (error) {
      lastError = error;
      const status = error.status;
      if (i < keyList.length - 1 && (status == null || isRetryableStatus(status))) {
        console.warn(`Mistral ${keySlot} error, trying backup:`, error.message);
        continue;
      }
      throw error;
    }
  }

  throw lastError || new Error("Mistral: všetky kľúče zlyhali");
}

module.exports = { callMistralWithFallback };
