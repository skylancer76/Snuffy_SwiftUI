const { onRequest, onCall, HttpsError } = require("firebase-functions/v2/https");
const { defineSecret, defineString } = require("firebase-functions/params");
const { initializeApp } = require("firebase-admin/app");
const { getFirestore }  = require("firebase-admin/firestore");

initializeApp();

// MARK: - Secrets and Configurations

const GEMINI_API_KEY   = defineSecret("GEMINI_API_KEY");
const SENDGRID_API_KEY = defineSecret("SENDGRID_API_KEY");

const SENDER_EMAIL = defineString("SENDER_EMAIL");
const SENDER_NAME  = defineString("SENDER_NAME", { default: "Snuffy" });

// MARK: - Admin Approval Endpoint

exports.approveCaregiver = onRequest(async (req, res) => {
    const token = (req.query.token || "").trim();

    if (!token || !token.includes("_")) {
        return res.status(400).send(errorPage("Invalid or missing approval token."));
    }

    const lastUnderscore = token.lastIndexOf("_");
    const uid  = token.substring(0, lastUnderscore);
    const role = token.substring(lastUnderscore + 1);

    if (!uid || !["caretaker", "dogwalker"].includes(role)) {
        return res.status(400).send(errorPage("Unrecognised role in token."));
    }

    try {
        const db = getFirestore();
        const collection = role === "caretaker" ? "caretakers" : "dogwalkers";

        await db.collection(collection).doc(uid).set({ isVerified: true }, { merge: true });

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

// MARK: - Gemini Chat Proxy

exports.geminiChat = onCall(
    { secrets: [GEMINI_API_KEY], region: "us-central1" },
    async (request) => {
        if (!request.auth || !request.auth.uid) {
            throw new HttpsError("unauthenticated", "Sign in to use Snuffy Bot.");
        }

        const data = request.data || {};
        const contents = data.contents;
        const systemInstruction = data.system_instruction;
        const generationConfig = data.generationConfig || { temperature: 0.6, maxOutputTokens: 1024 };
        const model = data.model || "gemini-2.5-flash";

        if (!Array.isArray(contents) || contents.length === 0) {
            throw new HttpsError("invalid-argument", "Missing conversation contents.");
        }

        const apiKey = GEMINI_API_KEY.value();
        if (!apiKey) {
            throw new HttpsError("failed-precondition", "Gemini API key is not configured.");
        }

        const url = `https://generativelanguage.googleapis.com/v1beta/models/${encodeURIComponent(model)}:generateContent?key=${encodeURIComponent(apiKey)}`;
        const payload = { contents, generationConfig };
        if (systemInstruction) {
            payload.system_instruction = systemInstruction;
        }

        let upstream;
        try {
            upstream = await fetch(url, {
                method: "POST",
                headers: { "Content-Type": "application/json" },
                body: JSON.stringify(payload)
            });
        } catch (err) {
            console.error("geminiChat fetch error:", err);
            throw new HttpsError("unavailable", "Couldn't reach the assistant. Please try again.");
        }

        const bodyText = await upstream.text();
        if (!upstream.ok) {
            console.error(`geminiChat upstream ${upstream.status}: ${bodyText}`);
            throw new HttpsError("internal", `Gemini error (${upstream.status}).`);
        }

        let parsed;
        try {
            parsed = JSON.parse(bodyText);
        } catch (err) {
            console.error("geminiChat parse error:", err, bodyText);
            throw new HttpsError("internal", "Couldn't parse the assistant's response.");
        }

        const text = parsed?.candidates?.[0]?.content?.parts?.[0]?.text;
        if (!text) {
            throw new HttpsError("internal", "Empty response from the assistant.");
        }

        return { text: text.trim() };
    }
);

// MARK: - SendGrid Email Proxy

exports.sendCaregiverEmail = onCall(
    { secrets: [SENDGRID_API_KEY], region: "us-central1" },
    async (request) => {
        if (!request.auth || !request.auth.uid) {
            throw new HttpsError("unauthenticated", "Sign in required to send approval email.");
        }

        const { to, subject, htmlBody } = request.data || {};
        if (!to || !subject || !htmlBody) {
            throw new HttpsError("invalid-argument", "Missing to, subject, or htmlBody.");
        }

        const apiKey      = SENDGRID_API_KEY.value();
        const senderEmail = SENDER_EMAIL.value();
        const senderName  = SENDER_NAME.value();
        if (!apiKey) {
            throw new HttpsError("failed-precondition", "SendGrid API key is not configured.");
        }
        if (!senderEmail) {
            throw new HttpsError("failed-precondition", "SendGrid sender is not configured.");
        }

        const payload = {
            personalizations: [{ to: [{ email: to }] }],
            from: { email: senderEmail, name: senderName || "Snuffy" },
            subject,
            content: [{ type: "text/html", value: htmlBody }]
        };

        let upstream;
        try {
            upstream = await fetch("https://api.sendgrid.com/v3/mail/send", {
                method: "POST",
                headers: {
                    "Authorization": `Bearer ${apiKey}`,
                    "Content-Type": "application/json"
                },
                body: JSON.stringify(payload)
            });
        } catch (err) {
            console.error("sendCaregiverEmail fetch error:", err);
            throw new HttpsError("unavailable", "Couldn't reach the email service.");
        }

        if (!upstream.ok) {
            const bodyText = await upstream.text();
            console.error(`sendCaregiverEmail upstream ${upstream.status}: ${bodyText}`);
            throw new HttpsError("internal", `Email service error (${upstream.status}).`);
        }

        console.log(`✉️  Sent caregiver email to ${to} (uid=${request.auth.uid})`);
        return { ok: true };
    }
);

// MARK: - HTML Page Templates

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

