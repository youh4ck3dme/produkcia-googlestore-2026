import * as functions from "firebase-functions";
import fetch from "node-fetch";

/**
 * Validates reCAPTCHA Enterprise token.
 * This should be called before sensitive operations.
 * Usage: v2 onCall signature
 */
export const validateRecaptcha = functions.https.onCall(async (request) => {
  const data = request.data;
  const token = data.token;
  const action = data.action || "LOGIN";
  const projectID = "bizagent-live-2026";
  const siteKey = "6Lf7dFQsAAAAALJbTSS5yaomUSvSNTpP4nr6GzlA";
  
  // SECURE: API Key should be stored in Secret Manager!
  const apiKey = process.env.RECAPTCHA_API_KEY; 

  if (!token) {
    throw new functions.https.HttpsError("invalid-argument", "Missing reCAPTCHA token.");
  }

  try {
    const response = await fetch(
      `https://recaptchaenterprise.googleapis.com/v1/projects/${projectID}/assessments?key=${apiKey}`,
      {
        method: "POST",
        body: JSON.stringify({
          event: {
            token: token,
            siteKey: siteKey,
            expectedAction: action,
          },
        }),
        headers: { "Content-Type": "application/json" },
      }
    );

    const assessment: any = await response.json();

    if (!assessment.tokenProperties || !assessment.tokenProperties.valid) {
      console.warn(`Invalid reCAPTCHA token: ${assessment?.tokenProperties?.invalidReason || "Unknown reason"}`);
      return { success: false, reason: assessment?.tokenProperties?.invalidReason || "Invalid" };
    }

    return {
      success: true,
      score: assessment.riskAnalysis.score,
      reasons: assessment.riskAnalysis.reasons,
    };
  } catch (error) {
    console.error("reCAPTCHA validation error:", error);
    throw new functions.https.HttpsError("internal", "Failed to verify reCAPTCHA.");
  }
});
