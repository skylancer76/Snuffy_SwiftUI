// functions/index.js
// Authored by bhumika sharam
//
// Firebase Cloud Function — approveCaregiver
//
// HOW TO DEPLOY:
//   cd functions
//   npm install
//   firebase deploy --only functions
//
// The approve button in the admin email hits:
//   https://us-central1-<PROJECT_ID>.cloudfunctions.net/approveCaregiver?token=<uid>_<role>

const { onRequest } = require("firebase-functions/v2/https");
const { initializeApp }  = require("firebase-admin/app");
const { getFirestore }   = require("firebase-admin/firestore");

initializeApp();

exports.approveCaregiver = onRequest(async (req, res) => {
    const token = (req.query.token || "").trim();

    if (!token || !token.includes("_")) {
        return res.status(400).send(errorPage("Invalid or missing approval token."));
    }

    // token format: "<uid>_caretaker"  or  "<uid>_dogwalker"
    const lastUnderscore = token.lastIndexOf("_");
    const uid  = token.substring(0, lastUnderscore);
    const role = token.substring(lastUnderscore + 1); // "caretaker" or "dogwalker"

    if (!uid || !["caretaker", "dogwalker"].includes(role)) {
        return res.status(400).send(errorPage("Unrecognised role in token."));
    }

    try {
        const db = getFirestore();
        const collection = role === "caretaker" ? "caretakers" : "dogwalkers";

        // 1. Verify the applicant in the main collection (set with merge to be safe)
        await db.collection(collection).doc(uid).set({ isVerified: true }, { merge: true });

        // 2. Mark the notification as approved (set with merge — works even if doc doesn't exist)
        await db.collection("admin_notifications").doc(token).set({
            uid: uid,
            role: role,
            status: "approved",
            approvedAt: new Date().toISOString()
        }, { merge: true });

        console.log(`✅ Approved ${role} uid=${uid}`);
        return res.status(200).send(successPage(role));

    } catch (err) {
        console.error("approveCaregiver error:", err);
        return res.status(500).send(errorPage(err.message));
    }
});

// ─── HTML Responses ──────────────────────────────────────────────────────────

function successPage(role) {
    const label = role === "caretaker" ? "Caretaker" : "Dog Walker";
    return `<!DOCTYPE html>
<html>
<head><meta charset="utf-8"/>
  <style>
    body { font-family: -apple-system, Arial, sans-serif; background: #fff5f8;
           display: flex; justify-content: center; align-items: center;
           min-height: 100vh; margin: 0; }
    .card { background: white; border-radius: 24px; padding: 48px 56px;
            box-shadow: 0 8px 40px rgba(255,102,153,0.15); text-align: center;
            max-width: 420px; }
    .icon { font-size: 64px; margin-bottom: 16px; }
    h1 { color: #FF3366; font-size: 24px; margin: 0 0 12px; }
    p  { color: #666; font-size: 15px; line-height: 1.6; }
    .badge { display: inline-block; background: #FF6699; color: white;
             border-radius: 50px; padding: 8px 24px; font-size: 13px;
             font-weight: 600; margin-top: 24px; }
  </style>
</head>
<body>
  <div class="card">
    <div class="icon">✅</div>
    <h1>${label} Approved!</h1>
    <p>The applicant has been verified in Snuffy. They will gain access to
       the app automatically within the next 60 seconds.</p>
    <div class="badge">🐾 Snuffy Admin</div>
  </div>
</body>
</html>`;
}

function errorPage(message) {
    return `<!DOCTYPE html>
<html>
<head><meta charset="utf-8"/></head>
<body style="font-family:Arial; text-align:center; padding:60px; color:#cc3300;">
  <h2>⚠️ Approval Failed</h2>
  <p>${message}</p>
</body>
</html>`;
}
