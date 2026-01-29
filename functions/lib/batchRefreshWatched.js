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
var __importDefault = (this && this.__importDefault) || function (mod) {
    return (mod && mod.__esModule) ? mod : { "default": mod };
};
Object.defineProperty(exports, "__esModule", { value: true });
exports.refreshCompanyNow = exports.batchRefreshWatched = void 0;
const functions = __importStar(require("firebase-functions/v1"));
const admin = __importStar(require("firebase-admin"));
const node_fetch_1 = __importDefault(require("node-fetch"));
admin.initializeApp();
const db = admin.firestore();
const ICOATLAS = "https://icoatlas.sk/api/lookup";
exports.batchRefreshWatched = functions.pubsub
    .schedule("every 24 hours")
    .timeZone("Europe/Bratislava")
    .onRun(async () => {
    const users = await db.collection("users").get();
    for (const user of users.docs) {
        const watched = await user.ref
            .collection("watched_companies")
            .get();
        for (const doc of watched.docs) {
            const icoNorm = doc.id;
            await refreshCompany(icoNorm, user.id);
        }
    }
});
exports.refreshCompanyNow = functions.https.onRequest(async (req, res) => {
    const ico = req.query.ico;
    if (!ico) {
        res.status(400).send("ICO missing");
        return;
    }
    await refreshCompany(ico, "manual");
    res.send("OK");
});
async function refreshCompany(icoNorm, uid) {
    const res = await (0, node_fetch_1.default)(`${ICOATLAS}?ico=${icoNorm}`, {
        headers: {
            "X-Api-Key": process.env.ICOATLAS_API_KEY,
        },
    });
    if (!res.ok)
        return;
    const fresh = await res.json();
    const ref = db.collection("companies").doc(icoNorm);
    const snap = await ref.get();
    if (!snap.exists) {
        await ref.set({
            ...fresh,
            icoNorm,
            fetchedAt: admin.firestore.FieldValue.serverTimestamp(),
        });
        return;
    }
    const old = snap.data();
    if (hasMeaningfulChange(old, fresh)) {
        await ref.set({
            ...fresh,
            fetchedAt: admin.firestore.FieldValue.serverTimestamp(),
        }, { merge: true });
        await db
            .collection("company_changes")
            .doc(icoNorm)
            .collection("events")
            .add({
            uid,
            changedAt: admin.firestore.FieldValue.serverTimestamp(),
            diff: diff(old, fresh),
        });
        await notifyUser(uid, icoNorm, fresh.name);
    }
}
function hasMeaningfulChange(old, fresh) {
    return old.name !== fresh.name || old.address !== fresh.address;
}
function diff(old, fresh) {
    return {
        name: old.name !== fresh.name ? [old.name, fresh.name] : null,
        address: old.address !== fresh.address ? [old.address, fresh.address] : null,
    };
}
async function notifyUser(uid, icoNorm, name) {
    const user = await admin.auth().getUser(uid);
    if (!user)
        return;
    // tu len uložíme notif event, push ide client-side
    await db.collection("notifications").add({
        uid,
        icoNorm,
        title: "Zmena v sledovanej firme",
        body: `${name} má aktualizované údaje`,
        createdAt: admin.firestore.FieldValue.serverTimestamp(),
        read: false,
    });
}
//# sourceMappingURL=batchRefreshWatched.js.map