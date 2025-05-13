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
    
    // Keep track of the height of the bottom UI for padding
    @State private var bottomBarHeight: CGFloat = 56 // Default to just tab bar height
    
    // Added to track the currently selected library tab
    @State private var currentLibraryTab = 0
    
    // Optional badge counts for tabs
    let badgeCounts: [Int: Int] = [:] // e.g. [1: 3] would show a badge with "3" on the Library tab
    
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
            .edgesIgnoringSafeArea(.bottom)
            // Pass the bottom bar height to all views in the environment
            .environment(\.bottomBarHeight, bottomBarHeight)
            
            // Now Playing Bar and Tab Bar Container
            if !isKeyboardVisible {
                // Container for measuring height
                VStack(spacing: 0) {
                    // Now Playing Bar
                    if nowPlayingModel.currentSong != nil {
                        NowPlayingBar(nowPlayingModel: nowPlayingModel)
                    }
                    
                    // Custom TabBar
                    CustomTabBar(
                        selectedTab: $selectedTab,
                        navigationState: $navigationState,
                        scrollIDs: $scrollIDs,
                        isKeyboardVisible: isKeyboardVisible,
                        badgeCounts: badgeCounts
                    )
                }
                .background(BlurView(style: .systemMaterial))
                .edgesIgnoringSafeArea(.bottom)
                .transition(.move(edge: .bottom))
                .animation(.easeInOut(duration: 0.25), value: nowPlayingModel.currentSong != nil)
                // Measure the height of the bottom UI to update our environment
                .background(
                    GeometryReader { geometry -> Color in
                        DispatchQueue.main.async {
                            // Update the height state when it changes
                            bottomBarHeight = geometry.size.height
                        }
                        return Color.clear
                    }
                )
            }
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
        .environmentObject(sortSessionStore)
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
                // Apply the bottom safe area to the root view
                rootView.withBottomSafeArea()
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
}
