//
//  DetailViewModifier.swift
//  Music Memory
//
//  Created for Music Memory
//

import SwiftUI

/// A ViewModifier that can be applied to detail views to ensure proper bottom padding
/// This is a fallback for any detail views that aren't using MediaDetailView
struct DetailViewBottomPaddingModifier: ViewModifier {
    @Environment(\.bottomBarHeight) var bottomBarHeight
    
    func body(content: Content) -> some View {
        content
            .safeAreaInset(edge: .bottom) {
                Color.clear
                    .frame(height: bottomBarHeight)
            }
    }
}

// Extension method for applying to any view
extension View {
    func applyDetailBottomPadding() -> some View {
        self.modifier(DetailViewBottomPaddingModifier())
    }
}

// This can be used in any custom detail view that doesn't use MediaDetailView, for example:
//
// struct CustomDetailView: View {
//     var body: some View {
//         List {
//             // Content here...
//         }
//         .applyDetailBottomPadding()
//     }
// }
