//
//  CommunityEventDetailView.swift
//  Snuffy_SwiftUI
//
//  Created by Snuffy Agent on 19/01/26.
//

import SwiftUI

struct CommunityEventDetailView: View {
    let event: CommunityEvent
    @Environment(\.dismiss) var dismiss
    
    private let snuffyPink = Color(red: 1.0, green: 0.4, blue: 0.6)
    private let bgColor = Color(red: 242/255, green: 242/255, blue: 247/255)
    
    // Sample static contact and organizer data (since CommunityEvent model might not have them natively yet)
    private let defaultContact = "9876543210"
    private let defaultOrganizer = "Anton Demeron"
    
    var body: some View {
        ZStack {
            bgColor.ignoresSafeArea()
            
            ScrollView(showsIndicators: false) {
                VStack(spacing: 0) {
                    
                    // MARK: - Header Title & Hero Image
                    VStack(spacing: 16) {
                        Text(event.title)
                            .font(.system(size: 24, weight: .bold))
                            .foregroundColor(.black)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 20)
                            
                        ZStack {
                            if let urlStr = event.imageURL, let url = URL(string: urlStr) {
                                AsyncImage(url: url) { phase in
                                    if case .success(let img) = phase {
                                        Color.clear
                                            .overlay(
                                                img.resizable().scaledToFill()
                                            )
                                            .clipped()
                                    } else {
                                        eventPlaceholder
                                    }
                                }
                            } else {
                                eventPlaceholder
                            }
                        }
                        .frame(maxWidth: .infinity)
                        .frame(height: 350)
                        .clipped()
                        .cornerRadius(24)
                        .padding(.horizontal, 20)
                    }
                    .padding(.top, 20)
                    
                    VStack(alignment: .leading, spacing: 24) {
                        
                        // MARK: - Event Details Block
                        sectionTitle("Event Details")
                        eventDetailsCard
                        
                        // MARK: - Event Overview Block
                        sectionTitle("Event Overview")
                        Text("I believe every pet deserves love and attention tailored to their needs. Whether it's energetic play for your dog or a calm, cozy atmosphere for your cat, I'm here to make them feel special. Count on me for trustworthy and affectionate care.")
                            .font(.system(size: 15))
                            .foregroundColor(.gray)
                            .lineSpacing(4)
                        
                        // MARK: - Register Button
                        Button {
                            // Register Action
                        } label: {
                            Text("Register")
                                .font(.system(size: 18, weight: .semibold))
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 16)
                                .background(snuffyPink)
                                .cornerRadius(30)
                                .shadow(color: snuffyPink.opacity(0.3), radius: 8, x: 0, y: 4)
                        }
                        .padding(.top, 16)
                        .padding(.bottom, 60)
                        
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 24)
                }
            }
            
            // MARK: - Navigation Header (Floating back button)
            VStack {
                HStack {
                    Button { dismiss() } label: {
                        Image(systemName: "chevron.left")
                            .foregroundColor(.black)
                            .font(.system(size: 18, weight: .semibold))
                            .frame(width: 44, height: 44)
                            .background(Color.white)
                            .clipShape(Circle())
                            .shadow(color: .black.opacity(0.05), radius: 5, x: 0, y: 2)
                    }
                    Spacer()
                }
                .padding(.horizontal, 20)
                .padding(.top, 10)
                Spacer()
            }
        }
        .navigationBarHidden(true)
    }
    
    private func sectionTitle(_ text: String) -> some View {
        Text(text)
            .font(.system(size: 20, weight: .bold))
            .foregroundColor(.black)
            .padding(.bottom, -4)
    }
    
    // MARK: - Event Details Card
    private var eventDetailsCard: some View {
        VStack(spacing: 0) {
            detailRow(icon: "calendar", label: "Date", value: formatDate(event.eventDate))
            Divider().padding(.leading, 44)
            detailRow(icon: "mappin.and.ellipse", label: "Location", value: event.location.isEmpty ? "TBD" : event.location)
            Divider().padding(.leading, 44)
            detailRow(icon: "clock.fill", label: "Time", value: formatTime(event.eventDate))
            Divider().padding(.leading, 44)
            detailRow(icon: "phone.fill", label: "Contact", value: defaultContact)
            Divider().padding(.leading, 44)
            detailRow(icon: "person.crop.circle.fill", label: "Organizer", value: defaultOrganizer)
        }
        .background(Color.white)
        .cornerRadius(20)
    }
    
    private func detailRow(icon: String, label: String, value: String) -> some View {
        HStack(spacing: 16) {
            Image(systemName: icon)
                .foregroundColor(snuffyPink)
                .font(.system(size: 18))
                .frame(width: 24, alignment: .center)
            
            Text(label)
                .font(.system(size: 16))
                .foregroundColor(.black)
                
            Spacer()
            
            Text(value)
                .font(.system(size: 15))
                .foregroundColor(.gray)
        }
        .padding(.vertical, 16)
        .padding(.horizontal, 16)
    }
    
    private var eventPlaceholder: some View {
        ZStack {
            Color(red: 1.0, green: 0.9, blue: 0.94)
            Image(systemName: "pawprint.fill")
                .font(.system(size: 60))
                .foregroundColor(snuffyPink.opacity(0.4))
        }
    }
    
    private func formatDate(_ date: Date) -> String {
        let f = DateFormatter()
        f.dateStyle = .medium
        return f.string(from: date)
    }
    
    private func formatTime(_ date: Date) -> String {
        let f = DateFormatter()
        f.timeStyle = .short
        return f.string(from: date)
    }
}
