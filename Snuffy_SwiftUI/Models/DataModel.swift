//
//  DataModel.swift
//  Snuffy_SwiftUI
//
//  Created by Pawan Priyatham  on 05/01/26.
//

import Foundation
import CoreLocation
import FirebaseCore
import FirebaseFirestore

// MARK: - Unified Caretaker Model
class Caretakers: Codable {
    var caretakerId: String
    var name: String
    var email: String
    var password: String
    var profilePic: String?
    var petSitted : String?
    var galleryImages: [String]?
    var bio: String
    var experience: Int
    var address: String
    var rating: String?
    var location: [Double]
    var distanceAway: Double
    var status: String
    var pendingRequests: [String]
    var completedRequests: Int
    var phoneNumber: String?
    var latitude: Double? {
            return location.count > 0 ? location[0] : nil
        }
        
    var longitude: Double? {
            return location.count > 1 ? location[1] : nil
        }
    
    
    init(
        caretakerId: String,
        name: String,
        email: String,
        password: String,
        profilePic: String? = nil,
        petSitted : String? = nil,
        galleryImages: [String]? = nil,
        bio: String,
        experience: Int,
        address: String,
        location: [Double],
        rating: String? = nil,
        distanceAway: Double = 0.0,
        status: String = "available",
        pendingRequests: [String] = [],
        completedRequests: Int = 0,
        phoneNumber: String? = nil
    ) {
        self.caretakerId = caretakerId
        self.name = name
        self.email = email
        self.password = password
        self.profilePic = profilePic
        self.petSitted = petSitted
        self.galleryImages = galleryImages
        self.bio = bio
        self.experience = experience
        self.address = address
        self.rating = rating
        self.location = location
        self.distanceAway = distanceAway
        self.status = status
        self.pendingRequests = pendingRequests
        self.completedRequests = completedRequests
        self.phoneNumber = phoneNumber
    }
}



// MARK: - Dog Walker Model

class DogWalker: Codable {
    var dogWalkerId: String
    var name: String
    var email: String
    var password: String
    var profilePic: String?
    var rating: String?
    var address: String
    var location: [Double]
    var distanceAway: Double
    var status: String
    var pendingRequests: [String]
    var completedRequests: Int
    var phoneNumber: String?
    var latitude: Double? {
            return location.count > 0 ? location[0] : nil
        }
        
    var longitude: Double? {
            return location.count > 1 ? location[1] : nil
        }
    // Initialization
    init(
        dogWalkerId: String,
        name: String,
        email: String,
        password: String,
        profilePic: String,
        rating: String,
        address: String,
        location: [Double],
        distanceAway: Double = 0.0,
        status: String = "available",
        pendingRequests: [String] = [],
        completedRequests: Int = 0,
        phoneNumber: String? = nil
    ) {
        self.dogWalkerId = dogWalkerId
        self.name = name
        self.email = email
        self.password = password
        self.profilePic = profilePic
        self.rating = rating
        self.address = address
        self.location = location
        self.distanceAway = distanceAway
        self.status = status
        self.pendingRequests = pendingRequests
        self.completedRequests = completedRequests
        self.phoneNumber = phoneNumber
    }
}

enum RequestType {
    case caretaker
    case dogWalker
}

struct UpcomingBookingModel {
    let bookingId: String
    let requestType: RequestType
    let caretakerOrWalkerId: String
    let caretakerOrWalkerName: String
    let caretakerOrWalkerPhone: String
    let caretakerOrWalkerImageURL: String
    let petName: String
}

enum ProfileType {
    case caretaker
    case dogwalker
}

// MARK: - Pet Data Model
class PetData: Codable, Identifiable {
    var petId: String
    var petImage: String?
    var petName: String?
    var petBreed: String?
    var petGender: String?
    var petAge: String?
    var petWeight: String?
    var medications: [PetMedicationDetails]?
    var vaccinationDetails: [VaccinationDetails]?
    var dietaryDetails: [PetDietDetails]?
    
    init(
        petId: String = UUID().uuidString,
        petImage: String? = nil,
        petName: String? = nil,
        petBreed: String? = nil,
        petGender: String? = nil,
        petAge: String? = nil,
        petWeight: String? = nil,
        medications: [PetMedicationDetails]? = nil,
        vaccinationDetails: [VaccinationDetails]? = nil,
        dietaryDetails: [PetDietDetails]? = nil

    ) {
        self.petId = petId
        self.petImage = petImage
        self.petName = petName
        self.petBreed = petBreed
        self.petGender = petGender
        self.petAge = petAge
        self.petWeight = petWeight
        self.medications = medications
        self.vaccinationDetails = vaccinationDetails
        self.dietaryDetails = dietaryDetails
    }
}

// MARK: - Dietary Details Model
class PetDietDetails: Codable {
    
    var dietId: String?
    var mealType: String
    var foodName: String
    var foodCategory: String
    var portionSize: String
    var feedingFrequency: String
    var servingTime: String

    init(
        dietId: String? = nil,
        mealType: String,
        foodName: String,
        foodCategory: String,
        portionSize: String,
        feedingFrequency: String,
        servingTime: String
    ) {
        self.dietId = dietId
        self.mealType = mealType
        self.foodName = foodName
        self.foodCategory = foodCategory
        self.portionSize = portionSize
        self.feedingFrequency = feedingFrequency
        self.servingTime = servingTime
    }
}


// MARK: - Medication Model
class PetMedicationDetails: Codable {
    
    var medicationId: String?
    var medicineName: String
    var medicineType: String
    var purpose: String
    var frequency: String
    var dosage: String
    var startDate: String
    var endDate: String

    init(
        medicationId: String? = nil,
        medicineName: String,
        medicineType: String,
        purpose: String,
        frequency: String,
        dosage: String,
        startDate: String,
        endDate: String
    ) {
        self.medicationId = medicationId
        self.medicineName = medicineName
        self.medicineType = medicineType
        self.purpose = purpose
        self.frequency = frequency
        self.dosage = dosage
        self.startDate = startDate
        self.endDate = endDate
    }
}

class VaccinationDetails: Codable {
    var vaccineId: String?
    var vaccineName: String
    var dateOfVaccination: String
    var expires: Bool
    var expiryDate: String?
    var notifyUponExpiry: Bool
    var notes: String?

    init(
        vaccineId: String? = nil,
        vaccineName: String,
        dateOfVaccination: String,
        expires: Bool,
        expiryDate: String? = nil,
        notifyUponExpiry: Bool,
        notes: String? = nil
    ) {
        self.vaccineId = vaccineId
        self.vaccineName = vaccineName
        self.dateOfVaccination = dateOfVaccination
        self.expires = expires
        self.expiryDate = expiryDate
        self.notifyUponExpiry = notifyUponExpiry
        self.notes = notes
    }
}


struct ScheduleCaretakerRequest: Codable {
    
    // MARK: - Required Fields
    var requestId: String
    var userId: String
    var userName: String
    var petName: String
    var startDate: Date?
    var endDate: Date?
    var petPickup: Bool
    var petDropoff: Bool
    var instructions: String
    var status: String
    var caretakerId: String
    var petId: String?
    var petImageUrl: String?
    var petBreed: String?
    var buildingNo: String?
    var houseNo: String?
    var landmark: String?
    var location: String?
    var latitude: Double?
    var longitude: Double?
    var duration: String
    var timestamp: Date?
    
    init?(from data: [String: Any]) {
       
        guard let requestId = data["requestId"] as? String,
              let userId    = data["userId"] as? String,
              let userName  = data["userName"] as? String,
              let petName   = data["petName"]  as? String,
              let startTimestamp = data["startDate"] as? Timestamp,
              let endTimestamp = data["endDate"] as? Timestamp,
              let petPickup   = data["petPickup"] as? Bool,
              let petDropoff  = data["petDropoff"] as? Bool,
              let instructions = data["instructions"] as? String,
              let caretakerId = data["caretakerId"] as? String,
              let status      = data["status"] as? String
        else {
            return nil
        }
        
        self.requestId = requestId
        self.userId = userId
        self.userName = userName
        self.petName = petName
        self.startDate = startTimestamp.dateValue()
        self.endDate = endTimestamp.dateValue()
        self.petPickup = petPickup
        self.petDropoff = petDropoff
        self.instructions = instructions
        self.caretakerId = caretakerId
        self.status = status
        self.petId  = data["petId"]        as? String
        self.petImageUrl = data["petImageUrl"]  as? String
        self.petBreed = data["petBreed"]     as? String
        self.buildingNo = data["buildingNo"]   as? String
        self.houseNo = data["houseNo"]      as? String
        self.landmark = data["landmark"]     as? String
        self.location = data["location"]     as? String
        self.latitude = data["latitude"]     as? Double
        self.longitude = data["longitude"]    as? Double
        self.duration = ScheduleCaretakerRequest.formatDateRange(start: startTimestamp,
                                                            end: endTimestamp)
        if let rawTimestamp = data["timestamp"] as? Timestamp {
            self.timestamp = rawTimestamp.dateValue()
        } else {
            self.timestamp = nil
        }
    }
    
    static func formatDateRange(start: Timestamp, end: Timestamp) -> String {
        let dateFormatter = DateFormatter()
        dateFormatter.dateStyle = .medium
        dateFormatter.timeStyle = .short
        
        let startStr = dateFormatter.string(from: start.dateValue())
        let endStr   = dateFormatter.string(from: end.dateValue())
        return "\(startStr) - \(endStr)"
    }
}




// MARK: - Dogwalker Request

struct ScheduleDogWalkerRequest: Codable {
    var requestId: String
    var userId: String
    var userName: String
    var petName: String
    var date: Date
    var startTime: Date
    var endTime: Date
    var petImageUrl: String?
    var petBreed: String?
    var instructions: String
    var status: String
    var dogWalkerId: String
    var duration: String
    var buildingNo: String?
    var houseNo: String?
    var landmark: String?
    var timestamp: Date?
    
    init?(from data: [String: Any]) {
        guard
            let requestId = data["requestId"] as? String,
            let userId    = data["userId"] as? String,
            let userName  = data["userName"] as? String,
            let petName   = data["petName"] as? String,
            let dateTS    = data["date"] as? Timestamp,
            let startTimeTS = data["startTime"] as? Timestamp,
            let endTimeTS = data["endTime"] as? Timestamp,
            let instructions = data["instructions"] as? String,
            let dogWalkerId = data["dogWalkerId"] as? String,
            let status = data["status"] as? String
            
        else {
            return nil
        }
        
        self.requestId = requestId
        self.userId = userId
        self.userName = userName
        self.petName = petName
        self.date = dateTS.dateValue()
        self.startTime = startTimeTS.dateValue()
        self.endTime = endTimeTS.dateValue()
        self.instructions = instructions
        self.dogWalkerId = dogWalkerId
        self.status = status
        self.petImageUrl = data["petImageUrl"]  as? String
        self.petBreed = data["petBreed"]     as? String
        self.buildingNo = data["buildingNo"]   as? String
        self.houseNo = data["houseNo"]      as? String
        self.landmark = data["landmark"]     as? String
        
        if let rawTimestamp = data["timestamp"] as? Timestamp {
            self.timestamp = rawTimestamp.dateValue()
        } else {
            self.timestamp = nil
        }
        
        self.duration = ScheduleDogWalkerRequest.calculateDuration(start: self.startTime, end: self.endTime)
    }
    
    static func calculateDuration(start: Date, end: Date) -> String {
        let interval = end.timeIntervalSince(start)
        let hours = Int(interval) / 3600
        let minutes = (Int(interval) % 3600) / 60
        return "\(hours)h \(minutes)m"
    }
}

    


// MARK: - Chats Struct
struct ChatMessage {
    var senderId: String
    var text: String
    var timestamp: Date
}

class PetLiveUpdate  {
    var name: String
    var description: String
    var location: CLLocationCoordinate2D
    var im: [String]
    
    init(name: String, description: String, location: CLLocationCoordinate2D, im: [String]) {
        self.name = name
        self.description = description
        self.location = location
        self.im = im
    }
    
    // Convert to Dictionary
    func toDictionary() -> [String: Any] {
        return [
            "name": name,
            "description": description,
            "latitude": location.latitude,
            "longitude": location.longitude,
            "im": im
        ]
    }
    
    // Initialize from Dictionary
    convenience init?(from dictionary: [String: Any]) {
        guard let name = dictionary["name"] as? String,
              let description = dictionary["description"] as? String,
              let latitude = dictionary["latitude"] as? Double,
              let longitude = dictionary["longitude"] as? Double,
              let im = dictionary["im"] as? [String] else {
            print("Failed to decode PetLiveUpdate from dictionary: \(dictionary)")
            return nil
        }
        
        let location = CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
        self.init(name: name, description: description, location: location, im: im)
    }
}
