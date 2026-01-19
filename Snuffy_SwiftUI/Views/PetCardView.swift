//
//  PetCardView.swift
//  Snuffy_SwiftUI
//

import SwiftUI

struct PetCardView: View {
    let pet: PetData
    @State private var petImage: UIImage?
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Pet Image
            if let image = petImage {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFill()
                    .frame(height: 140)
                    .clipped()
            } else {
                Image("DogPlaceholder")
                    .resizable()
                    .scaledToFill()
                    .frame(height: 140)
                    .clipped()
                    .onAppear {
                        loadPetImage()
                    }
            }
            
            // Text Section
            VStack(alignment: .leading, spacing: 4) {
                Text(pet.petName ?? "Unknown")
                    .font(.system(size: 18, weight: .bold))
                    .foregroundColor(.black)
                
                Text(pet.petBreed ?? "Unknown Breed")
                    .font(.system(size: 14))
                    .foregroundColor(.gray)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 10)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Color.white)
        }
        .frame(maxWidth: .infinity)
        .cornerRadius(16)
        .shadow(color: Color.black.opacity(0.1), radius: 8, x: 0, y: 4)
    }
    
    private func loadPetImage() {
        guard let imageUrlString = pet.petImage,
              let url = URL(string: imageUrlString) else {
            petImage = UIImage(named: "DogPlaceholder")
            return
        }
        
        let fileName = url.lastPathComponent
        let cachesDirectory = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask).first!
        let localURL = cachesDirectory.appendingPathComponent(fileName)
        
        if FileManager.default.fileExists(atPath: localURL.path),
           let image = UIImage(contentsOfFile: localURL.path) {
            petImage = image
        } else {
            ImageDownloader.shared.downloadImage(from: url) { downloadedLocalURL in
                if let downloadedLocalURL = downloadedLocalURL,
                   let image = UIImage(contentsOfFile: downloadedLocalURL.path) {
                    DispatchQueue.main.async {
                        petImage = image
                    }
                } else {
                    DispatchQueue.main.async {
                        petImage = UIImage(named: "DogPlaceholder")
                    }
                }
            }
        }
    }
}
