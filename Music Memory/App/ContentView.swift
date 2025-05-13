//
//  ContentView.swift
//  Music Memory
//
//  Created by Jacob Rees on 27/04/2025.
//

import SwiftUI
import UIKit
import Combine
import MediaPlayer

struct ContentView: View {
    @EnvironmentObject var musicLibrary: MusicLibraryModel
    @StateObject var sortSessionStore = SortSessionStore()
    @StateObject var nowPlayingModel = NowPlayingModel()
    @State private var selectedTab = 0
    @State private var navigationState = [0: false, 1: false, 2: false, 3: false, 4: false]
    @State private var scrollIDs = [0: UUID(), 1: UUID(), 2: UUID(), 3: UUID(), 4: UUID()]
    @State private var isKeyboardVisible = false
    @State private var lastSelectedTab = 0 // Track previous tab for swipe detection
    
    // Added to track the currently selected library tab
    @State private var currentLibraryTab = 0
    
    // Optional badge counts for tabs
    let badgeCounts: [Int: Int] = [:] // e.g. [1: 3] would show a badge with "3" on the Library tab
    
    let feedbackGenerator = UIImpactFeedbackGenerator(style: .light)
    
    // Helper function to create proper bindings to dictionary values
    private func bindingFor(key: Int) -> Binding<Bool> {
        return Binding(
            get: { self.navigationState[key] ?? false },
            set: { self.navigationState[key] = $0 }
        )
    }
    
    // Binding for the current library tab
    private var libraryTabBinding: Binding<Int> {
        Binding(
            get: { self.currentLibraryTab },
            set: { self.currentLibraryTab = $0 }
        )
    }
    
    // Configure large title appearance for the entire app
    init() {
        let appearance = UINavigationBarAppearance()
        appearance.configureWithDefaultBackground()
        appearance.largeTitleTextAttributes = [.foregroundColor: UIColor.label]
        appearance.titleTextAttributes = [.foregroundColor: UIColor.label]
        
        UINavigationBar.appearance().standardAppearance = appearance
        UINavigationBar.appearance().compactAppearance = appearance
        UINavigationBar.appearance().scrollEdgeAppearance = appearance
        UINavigationBar.appearance().prefersLargeTitles = true
    }
    
    var body: some View {
        ZStack(alignment: .bottom) {
            // Content area
            TabView(selection: $selectedTab) {
                NavigationViewWithState(
                    rootView: DashboardView().id(scrollIDs[0]),
                    inDetailView: bindingFor(key: 0),
                    scrollToTopAction: { scrollIDs[0] = UUID() }
                )
                .tag(0)
                
                NavigationViewWithState(
                    rootView: LibraryView(selectedTab: libraryTabBinding).id(scrollIDs[1]),
                    inDetailView: bindingFor(key: 1),
                    scrollToTopAction: { scrollIDs[1] = UUID() }
                )
                .tag(1)
                
                NavigationViewWithState(
                    rootView: SorterView().id(scrollIDs[2]),
                    inDetailView: bindingFor(key: 2),
                    scrollToTopAction: { scrollIDs[2] = UUID() }
                )
                .tag(2)
                
                NavigationViewWithState(
                    rootView: ReplaceView().id(scrollIDs[3]),
                    inDetailView: bindingFor(key: 3),
                    scrollToTopAction: { scrollIDs[3] = UUID() }
                )
                .tag(3)
                
                NavigationViewWithState(
                    rootView: SettingsView().id(scrollIDs[4]),
                    inDetailView: bindingFor(key: 4),
                    scrollToTopAction: { scrollIDs[4] = UUID() }
                )
                .tag(4)
            }
            .tabViewStyle(PageTabViewStyle(indexDisplayMode: .never))
            .padding(.bottom, isKeyboardVisible ? 0 : 56)
            .environmentObject(sortSessionStore)
            // Add haptic feedback for swipe gestures between main tabs
            .onChange(of: selectedTab) { newValue in
                // Only trigger haptic if the tab actually changed (not just programmatic update)
                if newValue != lastSelectedTab {
                    feedbackGenerator.impactOccurred()
                    lastSelectedTab = newValue
                }
            }
            
            VStack(spacing: 0) {
                // Now Playing Bar - display when song is playing and keyboard is not visible
                if !isKeyboardVisible && nowPlayingModel.currentSong != nil {
                    NowPlayingBar(nowPlayingModel: nowPlayingModel)
                }
                
                // Custom footer - only show when keyboard is not visible
                if !isKeyboardVisible {
                    VStack(spacing: 0) {
                        Divider()
                        
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
                            }
                        }
                        .background(Color(UIColor.systemBackground))
                    }
                }
            }
            .edgesIgnoringSafeArea(.bottom)
            .transition(.move(edge: .bottom))
            .animation(.easeInOut(duration: 0.25), value: isKeyboardVisible)
            .background(Color(UIColor.systemBackground))
        }
        .onReceive(NotificationCenter.default.publisher(for: UIResponder.keyboardWillShowNotification)) { _ in
            isKeyboardVisible = true
        }
        .onReceive(NotificationCenter.default.publisher(for: UIResponder.keyboardWillHideNotification)) { _ in
            isKeyboardVisible = false
        }
        .onAppear {
            // Initialize lastSelectedTab on appear
            lastSelectedTab = selectedTab
        }
        .environmentObject(nowPlayingModel)
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

// Helper view to track navigation state and handle navigation actions
struct NavigationViewWithState<Content: View>: View {
    let rootView: Content
    @Binding var inDetailView: Bool
    let scrollToTopAction: () -> Void
    
    // UIKit navigation controller reference
    @State private var navController: UINavigationController?
    
    var body: some View {
        NavigationView {
            rootView
        }
        .navigationViewStyle(StackNavigationViewStyle()) // Force consistent navigation style
        .background(
            NavigationControllerTracker(isInDetailView: $inDetailView, navController: $navController)
        )
        .onChange(of: inDetailView) { newValue in
            // If tab is tapped while in detail view, pop to root
            if !newValue, let navController = navController {
                navController.popToRootViewController(animated: true)
            }
        }
    }
}

// UIViewControllerRepresentable to track navigation state
struct NavigationControllerTracker: UIViewControllerRepresentable {
    @Binding var isInDetailView: Bool
    @Binding var navController: UINavigationController?
    
    func makeUIViewController(context: Context) -> UIViewController {
        let vc = UIViewController()
        return vc
    }
    
    func updateUIViewController(_ uiViewController: UIViewController, context: Context) {
        DispatchQueue.main.async {
            if let nc = uiViewController.navigationController {
                navController = nc
                // We're in a detail view if we're not at the root
                isInDetailView = nc.viewControllers.count > 1
            }
        }
    }
}
