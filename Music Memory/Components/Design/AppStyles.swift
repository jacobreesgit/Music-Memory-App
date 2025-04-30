//
//  AppStyles.swift
//  Music Memory
//
//  Created by Jacob Rees on 27/04/2025.
//

import SwiftUI

/// AppStyles contains all the design system elements for consistent appearance across the app
struct AppStyles {
    // MARK: - Colors
    static let accentColor = Color.purple
    static let backgroundColor = Color(UIColor.systemBackground)
    static let secondaryColor = Color.secondary.opacity(0.2)
    
    // MARK: - Spacing and Sizing
    static let cornerRadius: CGFloat = 8
    static let standardPadding: CGFloat = 16
    static let smallPadding: CGFloat = 8
    static let iconSize: CGFloat = 50
    
    // MARK: - Text Styles
    static let titleStyle = Font.title
    static let subtitleStyle = Font.title2
    static let headlineStyle = Font.headline
    static let bodyStyle = Font.body
    static let captionStyle = Font.caption
    static let playCountStyle = Font.subheadline
    
    // MARK: - Common ViewModifiers
    
    /// Standard row style modifier
    struct StandardRowStyle: ViewModifier {
        func body(content: Content) -> some View {
            content
                .padding(.vertical, 4)
        }
    }
    
    /// Standard section header style modifier
    struct SectionHeaderStyle: ViewModifier {
        func body(content: Content) -> some View {
            content
                .font(.headline)
                .fontWeight(.bold)
                .foregroundColor(accentColor)
                .padding(.horizontal)
                .padding(.top, 8)
        }
    }
}

// MARK: - View Extension for Style Modifiers
extension View {
    func standardRowStyle() -> some View {
        self.modifier(AppStyles.StandardRowStyle())
    }
    
    func sectionHeaderStyle() -> some View {
        self.modifier(AppStyles.SectionHeaderStyle())
    }
}
