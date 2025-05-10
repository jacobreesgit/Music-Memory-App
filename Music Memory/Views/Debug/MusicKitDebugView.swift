//
//  MusicKitDebugView.swift
//  Music Memory
//
//  Created by Jacob Rees on 10/05/2025.
//

import SwiftUI
import MusicKit
import MediaPlayer

// Move TestStatus enum definition to the top level before it's used
enum TestStatus {
    case unknown
    case success
    case failed
    case running
}

struct MusicKitDebugView: View {
    @StateObject private var viewModel = MusicKitDebugViewModel()
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            List {
                // Status section
                Section(header: Text("MusicKit Status")) {
                    // Authorization status
                    HStack {
                        Text("Authorization")
                        Spacer()
                        statusBadge(for: viewModel.authorizationStatus)
                    }
                    
                    // Subscription status
                    HStack {
                        Text("Apple Music Subscription")
                        Spacer()
                        statusBadge(for: viewModel.subscriptionStatus)
                    }
                    
                    // Developer token status
                    HStack {
                        Text("Developer Token")
                        Spacer()
                        statusBadge(for: viewModel.tokenStatus)
                    }
                    
                    // Search capability
                    HStack {
                        Text("Search Capability")
                        Spacer()
                        statusBadge(for: viewModel.searchStatus)
                    }
                }
                
                // Test actions section
                Section(header: Text("Test MusicKit")) {
                    Button(action: {
                        Task {
                            await viewModel.requestAuthorization()
                        }
                    }) {
                        HStack {
                            Image(systemName: "key.fill")
                            Text("Request Authorization")
                            Spacer()
                            if viewModel.authorizationStatus == .running {
                                ProgressView()
                            }
                        }
                    }
                    .disabled(viewModel.authorizationStatus == .running)
                    
                    Button(action: {
                        Task {
                            await viewModel.checkSubscription()
                        }
                    }) {
                        HStack {
                            Image(systemName: "music.note")
                            Text("Check Subscription")
                            Spacer()
                            if viewModel.subscriptionStatus == .running {
                                ProgressView()
                            }
                        }
                    }
                    .disabled(viewModel.authorizationStatus != .success || viewModel.subscriptionStatus == .running)
                    
                    Button(action: {
                        Task {
                            await viewModel.testSearch()
                        }
                    }) {
                        HStack {
                            Image(systemName: "magnifyingglass")
                            Text("Test Search")
                            Spacer()
                            if viewModel.searchStatus == .running {
                                ProgressView()
                            }
                        }
                    }
                    .disabled(viewModel.authorizationStatus != .success || viewModel.searchStatus == .running)
                    
                    Button(action: {
                        Task {
                            await viewModel.checkToken()
                        }
                    }) {
                        HStack {
                            Image(systemName: "checkmark.seal")
                            Text("Verify JWT Token")
                            Spacer()
                            if viewModel.tokenStatus == .running {
                                ProgressView()
                            }
                        }
                    }
                    .disabled(viewModel.tokenStatus == .running)
                    
                    Button(action: {
                        Task {
                            await viewModel.runFullDiagnostic()
                        }
                    }) {
                        HStack {
                            Image(systemName: "stethoscope")
                            Text("Run Full Diagnostic")
                            Spacer()
                            if viewModel.isDiagnosticRunning {
                                ProgressView()
                            }
                        }
                        .foregroundColor(.blue)
                    }
                    .disabled(viewModel.isDiagnosticRunning)
                }
                
                // Search test section
                Section(header: Text("Quick Search Test")) {
                    TextField("Search query", text: $viewModel.searchQuery)
                        .autocorrectionDisabled()
                    
                    Button(action: {
                        Task {
                            await viewModel.performSearch()
                        }
                    }) {
                        HStack {
                            Image(systemName: "magnifyingglass")
                            Text("Search")
                            Spacer()
                            if viewModel.isSearching {
                                ProgressView()
                            }
                        }
                    }
                    .disabled(viewModel.authorizationStatus != .success || viewModel.isSearching || viewModel.searchQuery.isEmpty)
                    
                    if !viewModel.searchResults.isEmpty {
                        Text("Found \(viewModel.searchResults.count) results")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                        
                        ForEach(Array(viewModel.searchResults.prefix(3).enumerated()), id: \.element.id) { index, song in
                            HStack {
                                Text("\(index + 1). ")
                                    .foregroundColor(.secondary)
                                VStack(alignment: .leading) {
                                    Text(song.title)
                                        .font(.subheadline)
                                    Text(song.artistName)
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                            }
                        }
                    }
                }
                
                // Debug logs
                if !viewModel.logs.isEmpty {
                    Section(header: Text("Debug Logs")) {
                        Text(viewModel.logs)
                            .font(.system(.caption, design: .monospaced))
                            .foregroundColor(.secondary)
                    }
                    
                    Button(action: {
                        viewModel.clearLogs()
                    }) {
                        Text("Clear Logs")
                            .foregroundColor(.red)
                    }
                }
            }
            .navigationTitle("MusicKit Debug")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
            .onAppear {
                // Run full diagnostics immediately when the view appears
                Task {
                    await viewModel.runFullDiagnostic()
                }
            }
        }
    }
    
    @ViewBuilder
    private func statusBadge(for status: TestStatus) -> some View {
        switch status {
        case .unknown:
            Text("Unknown")
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(Color.gray.opacity(0.2))
                .foregroundColor(.gray)
                .cornerRadius(8)
        case .success:
            Text("Success")
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(Color.green.opacity(0.2))
                .foregroundColor(.green)
                .cornerRadius(8)
        case .failed:
            Text("Failed")
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(Color.red.opacity(0.2))
                .foregroundColor(.red)
                .cornerRadius(8)
        case .running:
            HStack {
                Text("Testing")
                ProgressView()
                    .scaleEffect(0.7)
            }
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(Color.blue.opacity(0.2))
            .foregroundColor(.blue)
            .cornerRadius(8)
        }
    }
}

// MARK: - View Model
class MusicKitDebugViewModel: ObservableObject {
    @Published var authorizationStatus: TestStatus = .unknown
    @Published var subscriptionStatus: TestStatus = .unknown
    @Published var tokenStatus: TestStatus = .unknown
    @Published var searchStatus: TestStatus = .unknown
    @Published var isDiagnosticRunning: Bool = false
    
    @Published var searchQuery: String = "Beatles"
    @Published var searchResults: MusicItemCollection<Song> = MusicItemCollection<Song>([])
    @Published var isSearching: Bool = false
    
    @Published var logs: String = ""
    
    func checkCurrentStatus() {
        // Check authorization
        let status = MusicAuthorization.currentStatus
        authorizationStatus = status == .authorized ? .success : .failed
        
        // Check subscription if authorized
        if status == .authorized {
            Task {
                await checkSubscription()
            }
        }
        
        // Check JWT token
        Task {
            await checkToken()
        }
    }
    
    func requestAuthorization() async {
        await MainActor.run {
            authorizationStatus = .running
            log("Requesting MusicKit authorization...")
        }
        
        let status = await MusicAuthorization.request()
        
        await MainActor.run {
            authorizationStatus = status == .authorized ? .success : .failed
            log("Authorization result: \(status.rawValue)")
            
            // If authorized, also check subscription
            if status == .authorized {
                Task {
                    await checkSubscription()
                }
            }
        }
    }
    
    func checkSubscription() async {
        await MainActor.run {
            subscriptionStatus = .running
            log("Checking Apple Music subscription...")
        }
        
        do {
            let subscription = try await MusicSubscription.current
            
            await MainActor.run {
                subscriptionStatus = subscription.canPlayCatalogContent ? .success : .failed
                log("Subscription status: \(subscription.canPlayCatalogContent ? "Active" : "Inactive")")
            }
        } catch {
            await MainActor.run {
                subscriptionStatus = .failed
                log("Error checking subscription: \(error.localizedDescription)")
            }
        }
    }
    
    func testSearch() async {
        await MainActor.run {
            searchStatus = .running
            log("Testing search functionality...")
        }
        
        do {
            var request = MusicCatalogSearchRequest(term: "Test", types: [Song.self])
            request.limit = 5
            
            let response = try await request.response()
            
            await MainActor.run {
                searchStatus = response.songs.count > 0 ? .success : .failed
                log("Search test result: Found \(response.songs.count) songs")
            }
        } catch {
            await MainActor.run {
                searchStatus = .failed
                log("Search test failed: \(error.localizedDescription)")
            }
        }
    }
    
    func checkToken() async {
        await MainActor.run {
            tokenStatus = .running
            log("Verifying JWT token...")
        }
        
        let token = AppleMusicManager.shared.debugDeveloperToken
        
        if let token = token {
            // Check JWT format (header.payload.signature)
            let components = token.components(separatedBy: ".")
            
            if components.count == 3 {
                await MainActor.run {
                    tokenStatus = .success
                    log("Token format valid: \(String(token.prefix(10)))...")
                }
            } else {
                await MainActor.run {
                    tokenStatus = .failed
                    log("Token format invalid, doesn't have 3 components")
                }
            }
        } else {
            await MainActor.run {
                tokenStatus = .failed
                log("No developer token available")
            }
        }
    }
    
    func performSearch() async {
        guard !searchQuery.isEmpty else { return }
        
        await MainActor.run {
            isSearching = true
            log("Searching for: \(searchQuery)")
        }
        
        do {
            // Call AppleMusicManager search
            await AppleMusicManager.shared.searchAppleMusic(for: searchQuery, limit: 10)
            
            await MainActor.run {
                self.searchResults = AppleMusicManager.shared.searchResults
                isSearching = false
                log("Search completed: \(self.searchResults.count) results")
            }
        } catch {
            await MainActor.run {
                isSearching = false
                log("Search error: \(error.localizedDescription)")
            }
        }
    }
    
    func runFullDiagnostic() async {
        await MainActor.run {
            isDiagnosticRunning = true
            log("Starting full MusicKit diagnostic...")
        }
        
        // Step 1: Check token
        await checkToken()
        
        // Step 2: Check authorization
        let authStatus = MusicAuthorization.currentStatus
        await MainActor.run {
            authorizationStatus = authStatus == .authorized ? .success : .failed
            log("Current authorization: \(authStatus.rawValue)")
        }
        
        // If not authorized, try to authorize
        if authStatus != .authorized {
            let newStatus = await MusicAuthorization.request()
            await MainActor.run {
                authorizationStatus = newStatus == .authorized ? .success : .failed
                log("Authorization request result: \(newStatus.rawValue)")
            }
        }
        
        // Step 3: Check subscription if authorized
        if authStatus == .authorized || authorizationStatus == .success {
            await checkSubscription()
        }
        
        // Step 4: Test search if authorized
        if authStatus == .authorized || authorizationStatus == .success {
            await testSearch()
        }
        
        // Step 5: Check key file existence
        await MainActor.run {
            let keyPath = Bundle.main.path(forResource: "Music_Memory_MusicKit_Key", ofType: "p8")
            log("MusicKit key file: \(keyPath != nil ? "Found" : "Not found")")
            
            if let keyPath = keyPath {
                let fileExists = FileManager.default.fileExists(atPath: keyPath)
                log("Key file exists: \(fileExists)")
                
                if fileExists {
                    if let fileData = FileManager.default.contents(atPath: keyPath) {
                        log("Key file size: \(fileData.count) bytes")
                    } else {
                        log("Could not read key file contents")
                    }
                }
            }
        }
        
        await MainActor.run {
            isDiagnosticRunning = false
            log("Full diagnostic completed")
        }
    }
    
    func clearLogs() {
        logs = ""
    }
    
    func log(_ message: String) {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "HH:mm:ss"
        let timestamp = dateFormatter.string(from: Date())
        
        logs = "[\(timestamp)] \(message)\n" + logs
    }
}

// MARK: - AppleMusicManager Extension
extension AppleMusicManager {
    // Changed property name to avoid conflict
    var debugDeveloperToken: String? {
        return generateDeveloperToken()
    }
}

// Preview
struct MusicKitDebugView_Previews: PreviewProvider {
    static var previews: some View {
        MusicKitDebugView()
    }
}
