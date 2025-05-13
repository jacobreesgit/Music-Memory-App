//
//  CustomTabBar.swift
//  Music Memory
//
//  Created on 13/05/2025.
//

import SwiftUI
import UIKit

struct CustomTabBar: View {
    @Binding var selectedTab: Int
    @Binding var navigationState: [Int: Bool]
    @Binding var scrollIDs: [Int: UUID]
    let isKeyboardVisible: Bool
    
    // Optional badge counts for tabs
    let badgeCounts: [Int: Int]
    
    let feedbackGenerator = UIImpactFeedbackGenerator(style: .light)
    
    @State private var lastSelectedTab = 0 // Track previous tab for swipe detection
    
    var body: some View {
        ZStack {
            // Blur effect background - this needs to be the bottom layer
            BlurView(style: .systemMaterial)
                .edgesIgnoringSafeArea(.bottom)
            
            // Divider at the top
            VStack(spacing: 0) {
                Divider()
                    .background(Color.gray.opacity(0.3))
                
                // Tab bar content
                HStack(spacing: 0) {
                    ForEach(0..<5) { index in
                        Button(action: {
                            // Haptic feedback for tap
                            feedbackGenerator.impactOccurred()
                            
                            if selectedTab == index {
                                if navigationState[index] == true {
                                    // In detail view - do nothing, let NavigationViewWithState handle it
                                } else {
                                    // In root view - scroll to top
                                    scrollIDs[index] = UUID()
                                }
                            }
                            selectedTab = index
                        }) {
                            Spacer()
                            VStack(spacing: 6) {
                                ZStack(alignment: .topTrailing) {
                                    Image(systemName: iconForIndex(index))
                                        .font(.system(size: 21))
                                        .padding(.top, 8)
                                    
                                    // Badge (if any)
                                    if let count = badgeCounts[index], count > 0 {
                                        Text("\(count)")
                                            .font(.system(size: 12, weight: .bold))
                                            .foregroundColor(.white)
                                            .frame(minWidth: 16, minHeight: 16)
                                            .background(Color.red)
                                            .clipShape(Circle())
                                            .offset(x: 10, y: -5)
                                    }
                                }
                                
                                Text(labelForIndex(index))
                                    .font(.caption)
                                    .dynamicTypeSize(.small ... .large) // Dynamic text support
                            }
                            .foregroundColor(selectedTab == index ? AppStyles.accentColor : Color.gray)
                            .frame(height: 56)
                            .contentShape(Rectangle()) // Improve tap area
                            // Visual feedback on press
                            .scaleEffect(selectedTab == index ? 1.0 : 0.97)
                            .animation(.easeInOut(duration: 0.1), value: selectedTab)
                            Spacer()
                        }
                        .frame(maxWidth: .infinity)
                        .accessibilityLabel("\(labelForIndex(index)) Tab")
                        .accessibilityHint(selectedTab == index ? "Selected" : "")
                        .accessibilityAddTraits(selectedTab == index ? .isSelected : [])
                        .background(Color.clear) // Ensure button background is clear
                    }
                }
            }
        }
        .frame(height: 56) // Fixed height for the tab bar
        .background(Color.clear) // Ensure the overall background is clear
        .onAppear {
            // Initialize lastSelectedTab on appear
            lastSelectedTab = selectedTab
        }
        // Add haptic feedback for swipe gestures between main tabs
        .onChange(of: selectedTab) { newValue in
            // Only trigger haptic if the tab actually changed (not just programmatic update)
            if newValue != lastSelectedTab {
                feedbackGenerator.impactOccurred()
                lastSelectedTab = newValue
            }
        }
    }
    
    private func iconForIndex(_ index: Int) -> String {
        switch index {
        case 0: return "chart.bar.fill"
        case 1: return "music.note"
        case 2: return "arrow.up.arrow.down"
        case 3: return "arrow.2.squarepath"
        case 4: return "gearshape.fill"
        default: return ""
        }
    }
    
    private func labelForIndex(_ index: Int) -> String {
        switch index {
        case 0: return "Dashboard"
        case 1: return "Library"
        case 2: return "Sorter"
        case 3: return "Replace"
        case 4: return "Settings"
        default: return ""
        }
    }
}
