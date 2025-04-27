//
//  EnvironmentReader.swift
//  Music Memory
//
//  Created by Jacob Rees on 27/04/2025.
//


import SwiftUI

/// A helper view that provides access to the environment without requiring @EnvironmentObject in every view
struct EnvironmentReader<Content: View>: View {
    @Environment(\.self) var environment
    let content: (EnvironmentValues) -> Content
    
    init(@ViewBuilder content: @escaping (EnvironmentValues) -> Content) {
        self.content = content
    }
    
    var body: some View {
        content(environment)
    }
}
