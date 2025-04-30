//
//  LibraryAccessView.swift
//  Music Memory
//
//  Created by Jacob Rees on 27/04/2025.
//

import SwiftUI

/// View shown when the app needs access to the music library
struct LibraryAccessView: View {
    var body: some View {
        VStack(spacing: AppStyles.standardPadding) {
            Image(systemName: "music.note.list")
                .font(.system(size: 60))
                .foregroundColor(AppStyles.accentColor)
                .padding()
            
            Text("Music Memory needs access to your library")
                .font(AppStyles.headlineStyle)
                .multilineTextAlignment(.center)
            
            Text("Please allow access in Settings to see your music play counts")
                .font(AppStyles.bodyStyle)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding()
            
            Button("Open Settings") {
                if let url = URL(string: UIApplication.openSettingsURLString) {
                    UIApplication.shared.open(url)
                }
            }
            .buttonStyle(.bordered)
            .tint(AppStyles.accentColor)
            .padding()
        }
        .padding()
    }
}
