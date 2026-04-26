//
//  ProfileGalleryCell.swift
//  Snuffy_SwiftUI
//
//  Created by Bhumika Sharma on 19/01/26.
//


import SwiftUI
import Kingfisher

struct ProfileGalleryCell: View {
    let url: URL

    var body: some View {
        GeometryReader { geo in
            let size = geo.size
            
            if url.scheme == "local" {
                // Load from local assets
                let imageName = url.host ?? ""
                Image(imageName)
                    .resizable()
                    .scaledToFill()
                    .frame(width: size.width, height: size.height)
                    .clipped()
                    .cornerRadius(12)
            } else {
                // Load from remote URL
                KFImage(url)
                    .placeholder {
                        Color(UIColor.systemGray5)
                            .overlay(
                                Image(systemName: "photo")
                                    .foregroundColor(.gray)
                                    .font(.system(size: 28))
                            )
                    }
                    .resizable()
                    .scaledToFill()
                    .frame(width: size.width, height: size.height)
                    .clipped()
                    .cornerRadius(12)
            }
        }
        // height = width × 1.3 (matches UIKit flowLayout itemSize)
        .aspectRatio(1/1.3, contentMode: .fit)
    }
}
