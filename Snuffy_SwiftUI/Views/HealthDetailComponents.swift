//
//  HealthDetailComponents.swift
//  Snuffy_SwiftUI
//
//  Created by Antigravity on 21/01/26.
//

import SwiftUI

struct DetailRow: View {
    let icon: String
    let label: String
    let value: String
    private let snuffyPink = Color(red: 1.0, green: 0.4, blue: 0.6)
    
    var body: some View {
        HStack(spacing: 16) {
            Image(systemName: icon)
                .foregroundColor(snuffyPink)
                .frame(width: 24)
            
            Text(label)
                .foregroundColor(.gray)
                .font(.system(size: 16))
            
            Spacer()
            
            Text(value)
                .fontWeight(.medium)
                .font(.system(size: 16))
                .foregroundColor(.black)
        }
        .padding()
    }
}

struct ToggleRow: View {
    let icon: String
    let label: String
    @Binding var isOn: Bool
    private let snuffyPink = Color(red: 1.0, green: 0.4, blue: 0.6)
    
    var body: some View {
        HStack(spacing: 16) {
            Image(systemName: icon)
                .foregroundColor(snuffyPink)
                .frame(width: 24)
            
            Text(label)
                .foregroundColor(.gray)
                .font(.system(size: 16))
            
            Spacer()
            
            Toggle("", isOn: $isOn)
                .labelsHidden()
                .tint(snuffyPink)
        }
        .padding(.horizontal)
        .padding(.vertical, 8)
    }
}
