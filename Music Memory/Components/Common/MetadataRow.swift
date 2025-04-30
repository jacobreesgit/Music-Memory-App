//
//  MetadataRow.swift
//  Music Memory
//
//  Created by Jacob Rees on 27/04/2025.
//

import SwiftUI

/// A reusable row for displaying metadata with an icon, label, and value
struct MetadataRow: View {
    let icon: String
    let title: String
    let value: String
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .frame(width: 24)
                .foregroundColor(.secondary)
            
            Text(title)
                .fontWeight(.medium)
            
            Spacer()
            
            Text(value)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.trailing)
        }
    }
}

extension View {
    func standardMetadataSection<Content: View>(@ViewBuilder content: () -> Content) -> some View {
        Section(header: Text("Statistics")
            .padding(.leading, -15)) {
                content()
        }
    }
}
