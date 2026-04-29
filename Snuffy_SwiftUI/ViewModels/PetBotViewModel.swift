//
//  PetBotViewModel.swift
//  Snuffy_SwiftUI
//  Created by Bhumika Sharma

import Foundation
import FirebaseAuth
import FirebaseFirestore
import Combine
import UIKit

@MainActor
class PetBotViewModel: ObservableObject {
    @Published var messages: [PetBotMessage] = []
    @Published var isThinking      = false
    @Published var isLoadingData   = true
    @Published var dataLoadError: String?

    private let db = Firestore.firestore()
    private var systemPrompt = ""
    // Multi-turn conversation history sent to Gemini
    private var geminiHistory: [GeminiContent] = []

    // MARK: - Init

    init() {
        let welcome = PetBotMessage(
            text: "Hi! I'm Snuffy Bot 🐾 I know all about your pets. Ask me anything!",
            isUser: false
        )
        messages = [welcome]
        Task { await loadAllPetData() }
    }

    // MARK: - Load pet data from Firestore and build system prompt

    private func loadAllPetData() async {
        guard let uid = Auth.auth().currentUser?.uid else {
            isLoadingData = false
            return
        }

        do {
            // Fetch all pets belonging to this owner
            let petSnap = try await db.collection("Pets")
                .whereField("ownerID", isEqualTo: uid)
                .getDocuments()

            var contextBlocks: [String] = []

            for petDoc in petSnap.documents {
                let data    = petDoc.data()
                let petId   = petDoc.documentID
                let petName = data["petName"] as? String ?? "Unknown"

                var block = """
                --- PET: \(petName) ---
                Breed:  \(data["petBreed"]  as? String ?? "N/A")
                Gender: \(data["petGender"] as? String ?? "N/A")
                Age:    \(data["petAge"]    as? String ?? "N/A")
                Weight: \(data["petWeight"] as? String ?? "N/A")
                """

                // Vaccinations
                let vaccSnap = try? await db.collection("Pets").document(petId)
                    .collection("Vaccinations").getDocuments()
                if let docs = vaccSnap?.documents, !docs.isEmpty {
                    block += "\n\nVaccinations:"
                    for d in docs {
                        let v = d.data()
                        var line = "\n• \(v["vaccineName"] as? String ?? "?") — Vaccinated: \(v["dateOfVaccination"] as? String ?? "?")"
                        if let exp = v["expiryDate"] as? String, !exp.isEmpty {
                            line += " — Expires: \(exp)"
                        }
                        block += line
                    }
                } else {
                    block += "\n\nVaccinations: None recorded"
                }

                // Medications
                let medSnap = try? await db.collection("Pets").document(petId)
                    .collection("PetMedication").getDocuments()
                if let docs = medSnap?.documents, !docs.isEmpty {
                    block += "\n\nMedications:"
                    for d in docs {
                        let m = d.data()
                        block += "\n• \(m["medicineName"] as? String ?? "?") (\(m["medicineType"] as? String ?? "?"))"
                        block += " — Purpose: \(m["purpose"] as? String ?? "?")"
                        block += " — Dosage: \(m["dosage"] as? String ?? "?"), \(m["frequency"] as? String ?? "?")"
                        block += " — \(m["startDate"] as? String ?? "?") to \(m["endDate"] as? String ?? "?")"
                    }
                } else {
                    block += "\n\nMedications: None recorded"
                }

                // Dietary details
                let dietSnap = try? await db.collection("Pets").document(petId)
                    .collection("PetDiet").getDocuments()
                if let docs = dietSnap?.documents, !docs.isEmpty {
                    block += "\n\nDiet:"
                    for d in docs {
                        let dt = d.data()
                        block += "\n• \(dt["mealType"] as? String ?? "?"): \(dt["foodName"] as? String ?? "?") (\(dt["foodCategory"] as? String ?? "?"))"
                        block += " — \(dt["portionSize"] as? String ?? "?"), \(dt["feedingFrequency"] as? String ?? "?")"
                    }
                } else {
                    block += "\n\nDiet: None recorded"
                }

                contextBlocks.append(block)
            }

            let dateStr = DateFormatter.localizedString(from: Date(), dateStyle: .long, timeStyle: .none)

            systemPrompt = """
            You are Snuffy Bot, a warm and knowledgeable AI assistant for pet owners inside the Snuffy app. \
            Your job is to answer questions specifically about the user's pets based on the data below. \
            Be friendly, concise, and accurate. Format lists with bullet points. \
            IMPORTANT: You are read-only. You cannot add, edit, or delete any data in the app. \
            Never offer or suggest making changes to the app on the user's behalf. \
            If the user asks you to add, update, or remove anything, tell them they can do it themselves in the app. \
            If asked about something unrelated to their pets or pet care, politely redirect. \
            Today's date is \(dateStr).

            \(contextBlocks.isEmpty ? "The user has no pets registered yet. Encourage them to add pets in the app." : contextBlocks.joined(separator: "\n\n"))
            """

        } catch {
            dataLoadError = "Couldn't load pet data: \(error.localizedDescription)"
        }
        isLoadingData = false
    }

    // MARK: - Send message

    func send(_ text: String, image: UIImage? = nil) async {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty || image != nil, !isThinking else { return }

        // Append user message (store compressed JPEG for display)
        let imageData = image.flatMap { $0.jpegData(compressionQuality: 0.7) }
        let userMsg = PetBotMessage(text: trimmed, isUser: true, imageData: imageData)
        messages.append(userMsg)

        // History keeps text only; image is injected per-call below
        let historyText = trimmed.isEmpty ? "[Image attached]" : trimmed
        geminiHistory.append(GeminiContent(role: "user", parts: [GeminiPart(text: historyText)]))
        if geminiHistory.count > 40 { geminiHistory.removeFirst(2) }

        // Build image parts for this specific call
        var imageParts: [GeminiPart] = []
        if let img = image, let jpeg = img.jpegData(compressionQuality: 0.5) {
            imageParts.append(GeminiPart(inlineData: GeminiInlineData(
                mime_type: "image/jpeg",
                data: jpeg.base64EncodedString()
            )))
        }

        isThinking = true
        defer { isThinking = false }

        do {
            let reply = try await callGemini(imageParts: imageParts)
            let botMsg = PetBotMessage(text: reply, isUser: false)
            messages.append(botMsg)
            geminiHistory.append(GeminiContent(role: "model", parts: [GeminiPart(text: reply)]))
            if geminiHistory.count > 40 { geminiHistory.removeFirst(2) }
        } catch {
            print("[PetBot] Gemini error: \(error)")
            let errMsg = PetBotMessage(text: "Sorry, I couldn't connect. Please try again.", isUser: false)
            messages.append(errMsg)
        }
    }

    // MARK: - Gemini REST API (typed Codable request)

    private func callGemini(imageParts: [GeminiPart] = []) async throws -> String {
        let key    = AIConfig.geminiAPIKey
        let model  = AIConfig.geminiModel
        let urlStr = "https://generativelanguage.googleapis.com/v1beta/models/\(model):generateContent?key=\(key)"
        guard let url = URL(string: urlStr) else { throw URLError(.badURL) }

        var req        = URLRequest(url: url)
        req.httpMethod = "POST"
        req.setValue("application/json", forHTTPHeaderField: "Content-Type")

        // Inject image parts into the last (current) user turn
        var contents = geminiHistory
        if !imageParts.isEmpty, let last = contents.last {
            contents.removeLast()
            contents.append(GeminiContent(role: last.role, parts: last.parts + imageParts))
        }

        let payload = GeminiRequest(
            system_instruction: GeminiSystemInstruction(parts: [GeminiPart(text: systemPrompt)]),
            contents: contents,
            generationConfig: GeminiGenerationConfig(temperature: 0.6, maxOutputTokens: 1024)
        )
        req.httpBody = try JSONEncoder().encode(payload)

        let (data, response) = try await URLSession.shared.data(for: req)

        if let http = response as? HTTPURLResponse, http.statusCode != 200 {
            let body = String(data: data, encoding: .utf8) ?? "(empty)"
            print("[PetBot] HTTP \(http.statusCode): \(body)")
            throw NSError(domain: "Gemini", code: http.statusCode,
                          userInfo: [NSLocalizedDescriptionKey: "HTTP \(http.statusCode): \(body)"])
        }

        let parsed = try JSONDecoder().decode(GeminiResponse.self, from: data)
        guard let text = parsed.candidates?.first?.content?.parts?.first?.text else {
            throw NSError(domain: "Gemini", code: -1,
                          userInfo: [NSLocalizedDescriptionKey: "Empty response"])
        }
        return text.trimmingCharacters(in: .whitespacesAndNewlines)
    }
}

// MARK: - Gemini Codable types

private struct GeminiInlineData: Codable {
    let mime_type: String
    let data: String
}

private struct GeminiPart: Codable {
    let text: String?
    let inline_data: GeminiInlineData?

    init(text: String) {
        self.text        = text
        self.inline_data = nil
    }

    init(inlineData: GeminiInlineData) {
        self.text        = nil
        self.inline_data = inlineData
    }

    func encode(to encoder: Encoder) throws {
        var c = encoder.container(keyedBy: CodingKeys.self)
        if let t = text        { try c.encode(t, forKey: .text) }
        if let d = inline_data { try c.encode(d, forKey: .inline_data) }
    }

    init(from decoder: Decoder) throws {
        let c        = try decoder.container(keyedBy: CodingKeys.self)
        text         = try c.decodeIfPresent(String.self,          forKey: .text)
        inline_data  = try c.decodeIfPresent(GeminiInlineData.self, forKey: .inline_data)
    }

    enum CodingKeys: String, CodingKey { case text, inline_data }
}

private struct GeminiContent: Codable {
    let role: String
    let parts: [GeminiPart]
}

private struct GeminiSystemInstruction: Codable {
    let parts: [GeminiPart]
}

private struct GeminiGenerationConfig: Codable {
    let temperature: Double
    let maxOutputTokens: Int
}

private struct GeminiRequest: Codable {
    let system_instruction: GeminiSystemInstruction
    let contents: [GeminiContent]
    let generationConfig: GeminiGenerationConfig
}

private struct GeminiResponsePart: Codable { let text: String? }
private struct GeminiResponseContent: Codable { let parts: [GeminiResponsePart]? }
private struct GeminiCandidate: Codable { let content: GeminiResponseContent? }
private struct GeminiResponse: Codable { let candidates: [GeminiCandidate]? }
