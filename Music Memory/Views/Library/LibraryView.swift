import SwiftUI
import MediaPlayer

struct LibraryView: View {
    @EnvironmentObject var musicLibrary: MusicLibraryModel
    @Binding var selectedTab: Int
    @State private var lastSelectedTab = 0 // Track previous tab for swipe detection
    @State private var pendingNavigationRequest: (type: String, id: String)? = nil
    
    // Feedback generator for haptic feedback
    private let feedbackGenerator = UIImpactFeedbackGenerator(style: .light)
    
    // Initialize with a default value for previews and a binding for real usage
    init(selectedTab: Binding<Int>? = nil) {
        self._selectedTab = selectedTab ?? .constant(0)
    }
    
    var body: some View {
        if musicLibrary.isLoading {
            LoadingView(message: "Loading your music...")
        } else if !musicLibrary.hasAccess {
            LibraryAccessView()
        } else {
            VStack(spacing: 0) {
                // Custom tab bar at the top with smooth animation similar to screenshot
                HStack(spacing: 0) {
                    ForEach(0..<5) { index in
                        Button(action: {
                            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                // Haptic feedback for tap
                                feedbackGenerator.impactOccurred()
                                selectedTab = index
                            }
                        }) {
                            VStack(spacing: 4) {
                                Text(tabTitle(for: index))
                                    .font(.headline)
                                    .foregroundColor(selectedTab == index ? AppStyles.accentColor : .secondary)
                                    .fontWeight(selectedTab == index ? .bold : .regular)
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.bottom, 8)
                        }
                    }
                }
                .overlay(
                    // Moving underline indicator
                    GeometryReader { geo in
                        let tabWidth = geo.size.width / 5
                        Rectangle()
                            .fill(AppStyles.accentColor)
                            .frame(width: tabWidth - 20, height: 2)
                            .offset(x: CGFloat(selectedTab) * tabWidth + 10)
                            .animation(.spring(response: 0.3, dampingFraction: 0.7), value: selectedTab)
                    }
                    .frame(height: 2)
                    , alignment: .bottom
                )
                .padding(.top, 8)
                
                // Tab content - added animation modifier to match main navigation
                TabView(selection: $selectedTab) {
                    // Tracks tab
                    SongsView()
                        .tag(0)
                    
                    // Artists tab
                    ArtistsView()
                        .tag(1)
                    
                    // Albums tab
                    AlbumsView()
                        .tag(2)
                    
                    // Genres tab
                    GenresView()
                        .tag(3)
                        
                    // Playlists tab
                    PlaylistsView()
                        .tag(4)
                }
                .tabViewStyle(PageTabViewStyle(indexDisplayMode: .never))
                .animation(.spring(response: 0.35, dampingFraction: 0.86, blendDuration: 0), value: selectedTab)
                // Add haptic feedback for swipe gestures between library tabs
                .onChange(of: selectedTab) { newValue in
                    // Only trigger haptic if the tab actually changed (not just programmatic update)
                    if newValue != lastSelectedTab {
                        feedbackGenerator.impactOccurred()
                        lastSelectedTab = newValue
                    }
                    
                    // Check if we have a pending navigation after tab changed
                    handlePendingNavigation()
                }
                .onAppear {
                    // Initialize lastSelectedTab on appear
                    lastSelectedTab = selectedTab
                    
                    // Listen for navigation requests from deep links
                    setupNavigationNotificationObserver()
                }
            }
        }
    }
    
    private func tabTitle(for index: Int) -> String {
        switch index {
        case 0: return "Songs"
        case 1: return "Artists"
        case 2: return "Albums"
        case 3: return "Genres"
        case 4: return "Playlists"
        default: return ""
        }
    }
    
    // Add notification observer for deep link navigation requests
    private func setupNavigationNotificationObserver() {
        NotificationCenter.default.addObserver(
            forName: Notification.Name("NavigateToDetailItem"),
            object: nil,
            queue: .main
        ) { notification in
            if let userInfo = notification.userInfo,
               let type = userInfo["type"] as? String,
               let id = userInfo["id"] as? String {
                // Store the navigation request
                pendingNavigationRequest = (type: type, id: id)
                
                // Set the appropriate tab first
                switch type {
                case "songs":
                    selectedTab = 0
                case "artists":
                    selectedTab = 1
                case "albums":
                    selectedTab = 2
                case "genres":
                    selectedTab = 3
                case "playlists":
                    selectedTab = 4
                default:
                    selectedTab = 0
                }
                
                // The tab change will trigger handlePendingNavigation via onChange
            }
        }
    }
    
    // Handle pending navigation after tab selection is complete
    private func handlePendingNavigation() {
        guard let navigation = pendingNavigationRequest else { return }
        
        // We need to find the item and navigate to it programmatically
        // This might require implementing a helper function in each view
        // to find and navigate to an item by ID
        
        // For now, we'll just print what we're trying to navigate to
        print("Should navigate to \(navigation.type) with ID: \(navigation.id)")
        
        // Clear the pending navigation
        pendingNavigationRequest = nil
        
        // TODO: Add actual navigation logic here or better yet, introduce a NavigationManager class
        // that can be injected into each tab view to handle finding items by ID
    }
}
