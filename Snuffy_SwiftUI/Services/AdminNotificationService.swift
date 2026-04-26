//
//  AdminNotificationService.swift
//  Snuffy_SwiftUI
//
//  Authored by bhumika sharam
//


import Foundation
import FirebaseFirestore
import FirebaseAuth

struct AdminNotificationService {

    static let shared = AdminNotificationService()

    private let sendGridAPIKey  =  ""
    private let senderEmail     =  ""
    private let senderName      = ""
    private let adminEmail      = ""
    private let firebaseProjectID = ""
   
    private let db = Firestore.firestore()

    // MARK: - Send Caretaker Approval Email
    func sendCaretakerApprovalRequest(
        uid: String,
        name: String,
        email: String,
        address: String,
        bio: String,
        experience: Int,
        petsHandled: Int,
        phoneNumber: String,
        certification: String,
        lor: String,
        galleryImages: [String]
    ) {
        print("[AdminNotificationService] 🚀 Starting caretaker approval request...")
        print("[AdminNotificationService] UID: \(uid), Name: \(name), Email: \(email)")

        let token = "\(uid)_caretaker"
        let approvalURL = cloudFunctionURL(token: token)

        let html = buildEmailHTML(
            role: "Caretaker",
            name: name, email: email, address: address,
            bio: bio, experience: "\(experience) year(s)",
            petsHandled: petsHandled, phoneNumber: phoneNumber,
            certification: certification, lor: lor,
            galleryImages: galleryImages,
            approvalURL: approvalURL
        )

        saveNotificationToFirestore(token: token, uid: uid, role: "caretaker",
                                    name: name, email: email)

        print("[AdminNotificationService] 📨 About to call sendEmail for caretaker...")
        sendEmail(
            to: adminEmail,
            subject: "🐾 New Caretaker Application — \(name)",
            htmlBody: html
        )
        print("[AdminNotificationService] 📨 sendEmail function called for caretaker")
    }

    // MARK: - Send Dog Walker Approval Email
    func sendDogWalkerApprovalRequest(
        uid: String,
        name: String,
        email: String,
        address: String,
        bio: String,
        petsHandled: Int,
        phoneNumber: String,
        certification: String,
        lor: String,
        galleryImages: [String]
    ) {
        print("[AdminNotificationService] 🚀 Starting dog walker approval request...")
        print("[AdminNotificationService] UID: \(uid), Name: \(name), Email: \(email)")

        let token = "\(uid)_dogwalker"
        let approvalURL = cloudFunctionURL(token: token)

        let html = buildEmailHTML(
            role: "Dog Walker",
            name: name, email: email, address: address,
            bio: bio, experience: "N/A",
            petsHandled: petsHandled, phoneNumber: phoneNumber,
            certification: certification, lor: lor,
            galleryImages: galleryImages,
            approvalURL: approvalURL
        )

        saveNotificationToFirestore(token: token, uid: uid, role: "dogwalker",
                                    name: name, email: email)

        print("[AdminNotificationService] 📨 About to call sendEmail for dogwalker...")
        sendEmail(
            to: adminEmail,
            subject: "🐾 New Dog Walker Application — \(name)",
            htmlBody: html
        )
        print("[AdminNotificationService] 📨 sendEmail function called for dogwalker")
    }

    // MARK: - Core SendGrid API Call
    private func sendEmail(to: String, subject: String, htmlBody: String) {
        print("[AdminNotificationService] 📧 Preparing to send email...")
        print("[AdminNotificationService] To: \(to)")
        print("[AdminNotificationService] Subject: \(subject)")

        guard let url = URL(string: "https://api.sendgrid.com/v3/mail/send") else {
            print("[AdminNotificationService] ❌ Invalid SendGrid URL")
            return
        }

        let body: [String: Any] = [
            "personalizations": [
                ["to": [["email": to]]]
            ],
            "from": ["email": senderEmail, "name": senderName],
            "subject": subject,
            "content": [
                ["type": "text/html", "value": htmlBody]
            ]
        ]

        guard let jsonData = try? JSONSerialization.data(withJSONObject: body) else {
            print("[AdminNotificationService] ❌ Failed to serialize JSON body")
            return
        }

        print("[AdminNotificationService] 📤 Sending request to SendGrid...")

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("Bearer \(sendGridAPIKey)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = jsonData

        // Use a semaphore to ensure the request completes before the app moves on
        let task = URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                print("[AdminNotificationService] ❌ Network error: \(error.localizedDescription)")
                return
            }

            guard let httpResponse = response as? HTTPURLResponse else {
                print("[AdminNotificationService] ❌ No HTTP response received")
                return
            }

            let responseBody = data.flatMap { String(data: $0, encoding: .utf8) } ?? "<no body>"

            if (200...299).contains(httpResponse.statusCode) {
                print("[AdminNotificationService] ✅ Email sent successfully to \(to)")
                print("[AdminNotificationService] HTTP Status: \(httpResponse.statusCode)")
            } else {
                print("[AdminNotificationService] ❌ SendGrid Error")
                print("[AdminNotificationService] HTTP Status: \(httpResponse.statusCode)")
                print("[AdminNotificationService] Response: \(responseBody)")
            }
        }

        task.resume()
        print("[AdminNotificationService] 📧 Email task started")
    }

    // MARK: - Firestore Audit Trail
    private func saveNotificationToFirestore(
        token: String, uid: String, role: String, name: String, email: String
    ) {
        print("[AdminNotificationService] 📝 Saving notification to Firestore...")
        print("[AdminNotificationService] Token: \(token), UID: \(uid), Role: \(role)")

        let doc: [String: Any] = [
            "uid": uid,
            "role": role,
            "applicantName": name,
            "applicantEmail": email,
            "approvalToken": token,
            "status": "pending",
            "createdAt": Timestamp()
        ]

        db.collection("admin_notifications").document(token).setData(doc) { error in
            if let error = error {
                print("[AdminNotificationService] ✗ Firestore write FAILED: \(error.localizedDescription)")
            } else {
                print("[AdminNotificationService] ✓ Firestore write SUCCESS for token: \(token)")
            }
        }
    }

    // MARK: - Approval Cloud Function URL
    private func cloudFunctionURL(token: String) -> String {
        return "https://us-central1-\(firebaseProjectID).cloudfunctions.net/approveCaregiver?token=\(token)"
    }

    // MARK: - HTML Email Builder
    private func buildEmailHTML(
        role: String, name: String, email: String, address: String,
        bio: String, experience: String, petsHandled: Int, phoneNumber: String,
        certification: String, lor: String, galleryImages: [String],
        approvalURL: String
    ) -> String {

        let imageLinks = galleryImages.prefix(4).enumerated().map { idx, url in
            let label = idx == 0 ? " (Profile Photo)" : ""
            return """
            <a href="\(url)" target="_blank" style="display:inline-block; margin:8px; text-decoration:none;">
              <img src="\(url)" width="140" height="140" alt="Photo \(idx+1)"
                   style="border-radius:12px; border:3px solid #FF6699; display:block;" />
              <div style="color:#888; font-size:12px; margin-top:6px;">Photo \(idx+1)\(label)</div>
            </a>
            """
        }.joined(separator: "\n")

        return """
        <!DOCTYPE html>
        <html>
        <head><meta charset="utf-8"/></head>
        <body style="margin:0; padding:0; background-color:#f5f5f5; font-family:-apple-system,Arial,sans-serif;">
          <div style="max-width:600px; margin:30px auto; background-color:#ffffff; border-radius:20px;
                      overflow:hidden; border:1px solid #e0e0e0;">

            <!-- Header -->
            <div style="background-color:#FF6699; padding:32px; text-align:center;">
              <div style="font-size:40px;">🐾</div>
              <h1 style="color:#ffffff; margin:8px 0 4px; font-size:22px;">
                New \(role) Application
              </h1>
              <p style="color:#ffe6f0; margin:0; font-size:14px;">
                Snuffy — Review &amp; Approve
              </p>
            </div>

            <!-- Details table -->
            <div style="padding:28px 32px;">
              <table style="width:100%; border-collapse:collapse; font-size:14px;">
                \(tableRow("👤 Name", name))
                \(tableRow("📧 Email", email))
                \(tableRow("📞 Phone", phoneNumber))
                \(tableRow("📍 Address", address))
                \(tableRow("📝 Bio", bio))
                \(tableRow("⏳ Experience", experience))
                \(tableRow("🐶 Pets Handled", "\(petsHandled)"))
                \(tableRow("🏅 Certification", certification.isEmpty ? "Not provided" : certification))
                \(tableRow("📄 Letter of Recommendation", lor.isEmpty ? "Not provided" : lor))
              </table>

              <!-- Gallery -->
              \(galleryImages.isEmpty ? "" : """
              <div style="margin-top:28px;">
                <h3 style="color:#333333; font-size:16px; margin-bottom:16px; border-bottom:1px solid #eee; padding-bottom:8px;">📸 Photos</h3>
                <div style="text-align:center;">\(imageLinks)</div>
              </div>
              """)

              <!-- Approve Button -->
              <div style="text-align:center; margin-top:40px; margin-bottom:20px;">
                <a href="\(approvalURL)" target="_blank"
                   style="display:inline-block; padding:16px 48px; background-color:#FF3366;
                          color:#ffffff !important; text-decoration:none; font-size:16px;
                          font-family:sans-serif; font-weight:bold; border-radius:50px;">
                  &#x2705; &nbsp;Approve \(role)
                </a>
                <p style="color:#aaaaaa; font-size:12px; margin-top:16px;">
                  Clicking Approve will immediately verify this applicant in the database.
                </p>
              </div>
            </div>

            <!-- Footer -->
            <div style="background:#f9f9f9; padding:16px 32px; text-align:center;
                        border-top:1px solid #f0f0f0;">
              <p style="color:#ccc; font-size:11px; margin:0;">
                This email was sent automatically by Snuffy App. Do not reply.
              </p>
            </div>
          </div>
        </body>
        </html>
        """
    }

    private func tableRow(_ label: String, _ value: String) -> String {
        return """
        <tr style="border-bottom:1px solid #f0f0f0;">
          <td style="padding:10px 8px; color:#888; width:38%; vertical-align:top;">\(label)</td>
          <td style="padding:10px 8px; color:#333; font-weight:500;">\(value)</td>
        </tr>
        """
    }
}
