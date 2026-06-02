import Foundation

struct PetBotMessage: Identifiable {
    let id: String
    let text: String
    let isUser: Bool
    let timestamp: Date
    let imageData: Data?

    init(id: String = UUID().uuidString, text: String, isUser: Bool, timestamp: Date = Date(), imageData: Data? = nil) {
        self.id        = id
        self.text      = text
        self.isUser    = isUser
        self.timestamp = timestamp
        self.imageData = imageData
    }
}
