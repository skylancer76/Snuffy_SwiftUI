//
//  CommunityModels.swift
//  Snuffy_SwiftUI
//
//  Created by Bhumika Sharma on 30/03/26.
//

import Foundation
import FirebaseFirestore

// MARK: - Media Type
enum CommunityMediaType: String, Codable {
    case text   = "text"
    case image  = "image"
    case video  = "video"
}

// MARK: - Community Post
struct CommunityPost: Identifiable, Codable {
    var id: String
    var userId: String
    var userName: String
    var authorAvatarURL: String?
    var caption: String
    var mediaURL: String?
    var mediaType: CommunityMediaType
    var timestamp: Date
    var likesCount: Int
    var commentsCount: Int
    /// Populated client-side after checking the likes sub-collection
    var isLikedByCurrentUser: Bool = false

    init(
        id: String = UUID().uuidString,
        userId: String,
        userName: String,
        authorAvatarURL: String? = nil,
        caption: String,
        mediaURL: String? = nil,
        mediaType: CommunityMediaType = .text,
        timestamp: Date = Date(),
        likesCount: Int = 0,
        commentsCount: Int = 0,
        isLikedByCurrentUser: Bool = false
    ) {
        self.id               = id
        self.userId           = userId
        self.userName         = userName
        self.authorAvatarURL  = authorAvatarURL
        self.caption          = caption
        self.mediaURL         = mediaURL
        self.mediaType        = mediaType
        self.timestamp        = timestamp
        self.likesCount       = likesCount
        self.commentsCount    = commentsCount
        self.isLikedByCurrentUser = isLikedByCurrentUser
    }

    /// Initialize from a Firestore document dictionary
    init?(from data: [String: Any], id: String) {
        guard
            let userId       = data["userId"]    as? String,
            let userName     = data["userName"]  as? String,
            let caption      = data["caption"]   as? String,
            let mediaTypeRaw = data["mediaType"] as? String,
            let mediaType    = CommunityMediaType(rawValue: mediaTypeRaw),
            let ts           = data["timestamp"] as? Timestamp
        else { return nil }

        self.id               = id
        self.userId           = userId
        self.userName         = userName
        self.authorAvatarURL  = data["authorAvatarURL"] as? String
        self.caption          = caption
        self.mediaURL         = data["mediaURL"]        as? String
        self.mediaType        = mediaType
        self.timestamp        = ts.dateValue()
        self.likesCount       = data["likesCount"]      as? Int ?? 0
        self.commentsCount    = data["commentsCount"]   as? Int ?? 0
        self.isLikedByCurrentUser = false
    }

    func toDictionary() -> [String: Any] {
        var dict: [String: Any] = [
            "id":            id,
            "userId":        userId,
            "userName":      userName,
            "caption":       caption,
            "mediaType":     mediaType.rawValue,
            "timestamp":     Timestamp(date: timestamp),
            "likesCount":    likesCount,
            "commentsCount": commentsCount
        ]
        if let url = authorAvatarURL { dict["authorAvatarURL"] = url }
        if let url = mediaURL        { dict["mediaURL"]        = url }
        return dict
    }
}

// MARK: - Community Comment
struct CommunityComment: Identifiable, Codable {
    var id: String
    var postId: String
    var userId: String
    var userName: String
    var text: String
    var timestamp: Date

    init(
        id: String = UUID().uuidString,
        postId: String,
        userId: String,
        userName: String,
        text: String,
        timestamp: Date = Date()
    ) {
        self.id        = id
        self.postId    = postId
        self.userId    = userId
        self.userName  = userName
        self.text      = text
        self.timestamp = timestamp
    }

    init?(from data: [String: Any], id: String) {
        guard
            let postId   = data["postId"]    as? String,
            let userId   = data["userId"]    as? String,
            let userName = data["userName"]  as? String,
            let text     = data["text"]      as? String,
            let ts       = data["timestamp"] as? Timestamp
        else { return nil }

        self.id        = id
        self.postId    = postId
        self.userId    = userId
        self.userName  = userName
        self.text      = text
        self.timestamp = ts.dateValue()
    }

    func toDictionary() -> [String: Any] {
        return [
            "id":        id,
            "postId":    postId,
            "userId":    userId,
            "userName":  userName,
            "text":      text,
            "timestamp": Timestamp(date: timestamp)
        ]
    }
}

// MARK: - Community Event
struct CommunityEvent: Identifiable, Codable {
    var id: String
    var title: String
    var tag: String
    var location: String
    var eventDate: Date
    var imageURL: String?
    var contactInfo: String?
    var userId: String
    var userName: String?
    var timestamp: Date

    init(
        id: String = UUID().uuidString,
        title: String,
        tag: String,
        location: String,
        eventDate: Date,
        imageURL: String? = nil,
        contactInfo: String? = nil,
        userId: String,
        userName: String? = nil,
        timestamp: Date = Date()
    ) {
        self.id          = id
        self.title       = title
        self.tag         = tag
        self.location    = location
        self.eventDate   = eventDate
        self.imageURL    = imageURL
        self.contactInfo = contactInfo
        self.userId      = userId
        self.userName    = userName
        self.timestamp   = timestamp
    }

    init?(from data: [String: Any], id: String) {
        guard
            let title    = data["title"]     as? String,
            let tag      = data["tag"]       as? String,
            let location = data["location"]  as? String,
            let eventTs  = data["eventDate"] as? Timestamp,
            let userId   = data["userId"]    as? String,
            let ts       = data["timestamp"] as? Timestamp
        else { return nil }

        self.id          = id
        self.title       = title
        self.tag         = tag
        self.location    = location
        self.eventDate   = eventTs.dateValue()
        self.imageURL    = data["imageURL"]    as? String
        self.contactInfo = data["contactInfo"] as? String
        self.userId      = userId
        self.userName    = data["userName"]    as? String
        self.timestamp   = ts.dateValue()
    }

    func toDictionary() -> [String: Any] {
        var dict: [String: Any] = [
            "id":        id,
            "title":     title,
            "tag":       tag,
            "location":  location,
            "eventDate": Timestamp(date: eventDate),
            "userId":    userId,
            "timestamp": Timestamp(date: timestamp)
        ]
        if let url  = imageURL    { dict["imageURL"]    = url  }
        if let info = contactInfo { dict["contactInfo"] = info }
        if let name = userName    { dict["userName"]    = name }
        return dict
    }
}

