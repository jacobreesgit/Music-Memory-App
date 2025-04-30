//
//  LoadingView.swift
//  Music Memory
//
//  Created by Jacob Rees on 27/04/2025.
//

import SwiftUI

/// View shown during data loading operations
struct LoadingView: View {
    let message: String
    
    var body: some View {
        VStack(spacing: AppStyles.standardPadding) {
            ProgressView()
                .scaleEffect(1.5)
                .padding()
            
            Text(message)
                .font(AppStyles.bodyStyle)
                .foregroundColor(.secondary)
        }
    }
}
