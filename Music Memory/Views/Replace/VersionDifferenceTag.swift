//
//  VersionDifferenceTag.swift
//  Music Memory
//
//  Created by Jacob Rees on 10/05/2025.
//

import SwiftUI

struct VersionDifferenceTag: View {
    let difference: VersionDifference
    
    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: difference.icon)
                .font(.system(size: 10))
            
            Text(difference.rawValue)
                .font(.system(size: 11, weight: .medium))
                .lineLimit(1)
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(difference.color.opacity(0.2))
        .foregroundColor(difference.color)
        .cornerRadius(12)
    }
}
