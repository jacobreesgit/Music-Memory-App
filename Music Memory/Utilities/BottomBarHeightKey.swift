//
//  BottomBarHeightKey.swift
//  Music Memory
//
//  Created for Music Memory
//

import SwiftUI

// Environment key to pass the bottom bar height to all views
struct BottomBarHeightKey: EnvironmentKey {
    static let defaultValue: CGFloat = 0
}

// Extension to access the bottom bar height from the environment
extension EnvironmentValues {
    var bottomBarHeight: CGFloat {
        get { self[BottomBarHeightKey.self] }
        set { self[BottomBarHeightKey.self] = newValue }
    }
}

// Convenience modifier for applying bottom safe area
struct BottomSafeAreaModifier: ViewModifier {
    @Environment(\.bottomBarHeight) var height
    
    func body(content: Content) -> some View {
        content.safeAreaInset(edge: .bottom) {
            Color.clear.frame(height: height)
        }
    }
}

// Extension to apply bottom safe area consistently
extension View {
    func withBottomSafeArea() -> some View {
        self.modifier(BottomSafeAreaModifier())
    }
}
