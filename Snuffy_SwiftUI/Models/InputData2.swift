//
//  InputData2.swift
//  Snuffy_SwiftUI
//
//  Created by Pawan Priyatham  on 05/01/26.
//

import Foundation


//let dogWalkers = [ ]
//    DogWalker(
//        dogWalkerId: "0kfkDOlaE4ZGatxWsxUgSnYPm5n1",
//        name: "Arun Kumar",
//        email: "arun@gmail.com",
//        password: "password1",
//        profilePic: "arun",
//        rating: "4.8",
//        address: "No. 12, Vandalur Main Road, Vandalur, Chennai",
//        location: [12.8926, 80.0817], // Vandalur
//        distanceAway: 8.0,
//        status: "available",
//        pendingRequests: [],
//        completedRequests: 12,
//        phoneNumber: "9390477280"
//    ),
//    DogWalker(
//        dogWalkerId: "I0brES25L1X68B9N3lPAYZlhJTA3",
//        name: "Priya Sharma",
//        email: "priya@gmail.com",
//        password: "password1",
//        profilePic: "priya",
//        rating: "4.7",
//        address: "Flat 5B, Green Residency, Urapakkam, Chennai",
//        location: [12.8116, 80.0482], // Urapakkam
//        distanceAway: 5.0,
//        status: "available",
//        pendingRequests: [],
//        completedRequests: 9,
//        phoneNumber: "9390477280"
//    ),
//    DogWalker(
//        dogWalkerId: "5f3ituTCaYWLy8Dx2jwqBAl3UUU2",
//        name: "Suresh Babu",
//        email: "suresh@gmail.com",
//        password: "password1",
//        profilePic: "suresh",
//        rating: "4.9",
//        address: "No. 45, GST Road, Maraimalai Nagar, Chennai",
//        location: [12.7480, 80.0220], // Maraimalai Nagar
//        distanceAway: 10.0,
//        status: "available",
//        pendingRequests: [],
//        completedRequests: 15,
//        phoneNumber: "9390477280"
//    ),
//    DogWalker(
//        dogWalkerId: "HNlHpGo9GUSWUBHpdvNhcnDqgRh1",
//        name: "Anita Desai",
//        email: "anita@gmail.com",
//        password: "password1",
//        profilePic: "anita",
//        rating: "4.6",
//        address: "Plot No. 23, Mahalakshmi Nagar, Tambaram, Chennai",
//        location: [12.9249, 80.1000], // Tambaram
//        distanceAway: 15.0,
//        status: "available",
//        pendingRequests: [],
//        completedRequests: 11,
//        phoneNumber: "9390477280"
//    ),
//    DogWalker(
//        dogWalkerId: "Fwsm1moaMibsMa3XkPcfoluqrs62",
//        name: "Ravi Teja",
//        email: "ravi@gmail.com",
//        password: "password1",
//        profilePic: "ravi",
//        rating: "4.5",
//        address: "No. 78, Velachery Main Road, Medavakkam, Chennai",
//        location: [12.9244, 80.1588], // Medavakkam
//        distanceAway: 25.0,
//        status: "available",
//        pendingRequests: [],
//        completedRequests: 5,
//        phoneNumber: "9390477280"
//    ),
//    DogWalker(
//        dogWalkerId: "1bFMkkUqzoZ8HLbirO250Vbqec32",
//        name: "Lakshmi Menon",
//        email: "lakshmi@gmail.com",
//        password: "password1",
//        profilePic: "lakshmi",
//        rating: "4.8",
//        address: "Villa 9, East Coast Road, Sholinganallur, Chennai",
//        location: [12.8797, 80.2297], // Sholinganallur
//        distanceAway: 28.0,
//        status: "available",
//        pendingRequests: [],
//        completedRequests: 9,
//        phoneNumber: "9390477280"
//    ),
//    DogWalker(
//        dogWalkerId: "CZ0YW2vSSFSl6Eyk0jVARS15BDZ2",
//        name: "Manoj Pillai",
//        email: "manoj@gmail.com",
//        password: "password1",
//        profilePic: "manoj",
//        rating: "4.7",
//        address: "No. 34, OMR Road, Perungudi, Chennai",
//        location: [12.9698, 80.2515], // Perungudi
//        distanceAway: 30.0,
//        status: "available",
//        pendingRequests: [],
//        completedRequests: 10,
//        phoneNumber: "9390477280"
//    ),
//    DogWalker(
//        dogWalkerId: "TGlxbrf0azP90gS5TUSZmmYCQaI2",
//        name: "Divya Narayan",
//        email: "narayan@gmail.com",
//        password: "password1",
//        profilePic: "divya",
//        rating: "4.9",
//        address: "No. 56, Mount Road, Guindy, Chennai",
//        location: [13.0108, 80.2121], // Guindy
//        distanceAway: 32.0,
//        status: "available",
//        pendingRequests: [],
//        completedRequests: 13,
//        phoneNumber: "9390477280"
//    ),
//    DogWalker(
//        dogWalkerId: "FD0BgkcAW7UvqD4rQBvwuRK3PPp2",
//        name: "Karthik Reddy",
//        email: "karthik@gmail.com",
//        password: "password1",
//        profilePic: "karthik",
//        rating: "4.6",
//        address: "No. 89, Arcot Road, Vadapalani, Chennai",
//        location: [13.0490, 80.2128], // Vadapalani
//        distanceAway: 35.0,
//        status: "available",
//        pendingRequests: [],
//        completedRequests: 11,
//        phoneNumber: "9390477280"
//    ),
//    DogWalker(
//        dogWalkerId: "jlLZLhNeO0QY3kGBEgeTcZJxP9M2",
//        name: "Sneha Iyer",
//        email: "sneha@gmail.com",
//        password: "password1",
//        profilePic: "sneha",
//        rating: "4.7",
//        address: "No. 101, Poonamallee High Road, Koyambedu, Chennai",
//        location: [13.0674, 80.2134], // Koyambedu
//        distanceAway: 38.0,
//        status: "available",
//        pendingRequests: [],
//        completedRequests: 14,
//        phoneNumber: "9390477280"
//    )
//]

