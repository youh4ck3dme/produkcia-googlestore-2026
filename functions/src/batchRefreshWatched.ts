import * as functions from "firebase-functions/v1";
import * as admin from "firebase-admin";
import fetch from "node-fetch";

admin.initializeApp();
const db = admin.firestore();

const ICOATLAS = "https://icoatlas.sk/api/lookup";

export const batchRefreshWatched = functions.pubsub
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

export const refreshCompanyNow = functions.https.onRequest(
  async (req, res) => {
    const ico = req.query.ico as string;
    if (!ico) {
      res.status(400).send("ICO missing");
      return;
    }

    await refreshCompany(ico, "manual");
    res.send("OK");
  }
);

async function refreshCompany(icoNorm: string, uid: string) {
  const res = await fetch(`${ICOATLAS}?ico=${icoNorm}`, {
    headers: {
      "X-Api-Key": process.env.ICOATLAS_API_KEY!,
    },
  });

  if (!res.ok) return;

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

  const old = snap.data()!;
  if (hasMeaningfulChange(old, fresh)) {
    await ref.set(
      {
        ...fresh,
        fetchedAt: admin.firestore.FieldValue.serverTimestamp(),
      },
      { merge: true }
    );

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

function hasMeaningfulChange(old: any, fresh: any): boolean {
  return old.name !== fresh.name || old.address !== fresh.address;
}

function diff(old: any, fresh: any) {
  return {
    name: old.name !== fresh.name ? [old.name, fresh.name] : null,
    address: old.address !== fresh.address ? [old.address, fresh.address] : null,
  };
}

async function notifyUser(uid: string, icoNorm: string, name: string) {
  const user = await admin.auth().getUser(uid);
  if (!user) return;

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
