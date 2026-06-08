"use strict";
var __createBinding = (this && this.__createBinding) || (Object.create ? (function(o, m, k, k2) {
    if (k2 === undefined) k2 = k;
    var desc = Object.getOwnPropertyDescriptor(m, k);
    if (!desc || ("get" in desc ? !m.__esModule : desc.writable || desc.configurable)) {
      desc = { enumerable: true, get: function() { return m[k]; } };
    }
    Object.defineProperty(o, k2, desc);
}) : (function(o, m, k, k2) {
    if (k2 === undefined) k2 = k;
    o[k2] = m[k];
}));
var __setModuleDefault = (this && this.__setModuleDefault) || (Object.create ? (function(o, v) {
    Object.defineProperty(o, "default", { enumerable: true, value: v });
}) : function(o, v) {
    o["default"] = v;
});
var __importStar = (this && this.__importStar) || (function () {
    var ownKeys = function(o) {
        ownKeys = Object.getOwnPropertyNames || function (o) {
            var ar = [];
            for (var k in o) if (Object.prototype.hasOwnProperty.call(o, k)) ar[ar.length] = k;
            return ar;
        };
        return ownKeys(o);
    };
    return function (mod) {
        if (mod && mod.__esModule) return mod;
        var result = {};
        if (mod != null) for (var k = ownKeys(mod), i = 0; i < k.length; i++) if (k[i] !== "default") __createBinding(result, mod, k[i]);
        __setModuleDefault(result, mod);
        return result;
    };
})();
Object.defineProperty(exports, "__esModule", { value: true });
exports.validateRecaptcha = void 0;
const functions = __importStar(require("firebase-functions"));
/**
 * Validates reCAPTCHA Enterprise token.
 * This should be called before sensitive operations.
 * Usage: v2 onCall signature
 */
exports.validateRecaptcha = functions.https.onCall(async (request) => {
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
        const response = await fetch(`https://recaptchaenterprise.googleapis.com/v1/projects/${projectID}/assessments?key=${apiKey}`, {
            method: "POST",
            body: JSON.stringify({
                event: {
                    token: token,
                    siteKey: siteKey,
                    expectedAction: action,
                },
            }),
            headers: { "Content-Type": "application/json" },
        });
        const assessment = await response.json();
        if (!assessment.tokenProperties || !assessment.tokenProperties.valid) {
            console.warn(`Invalid reCAPTCHA token: ${assessment?.tokenProperties?.invalidReason || "Unknown reason"}`);
            return { success: false, reason: assessment?.tokenProperties?.invalidReason || "Invalid" };
        }
        return {
            success: true,
            score: assessment.riskAnalysis.score,
            reasons: assessment.riskAnalysis.reasons,
        };
    }
    catch (error) {
        console.error("reCAPTCHA validation error:", error);
        throw new functions.https.HttpsError("internal", "Failed to verify reCAPTCHA.");
    }
});
//# sourceMappingURL=recaptcha.js.map