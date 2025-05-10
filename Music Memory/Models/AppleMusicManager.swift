//
//  AppleMusicManager.swift
//  Music Memory
//
//  Created by Jacob Rees on 10/05/2025.
//

import Foundation
import MusicKit
import MediaPlayer
import Combine
import CryptoKit
import Security

class AppleMusicManager: ObservableObject {
    static let shared = AppleMusicManager()
    
    @Published var isAuthorized = false
    @Published var isSubscribed = false
    @Published var authorizationStatus: MusicAuthorization.Status = .notDetermined
    @Published var isSearching = false
    @Published var searchResults: MusicItemCollection<Song> = MusicItemCollection<Song>([])
    @Published var error: Error?
    
    // Add developer token property
    private var developerToken: String?
    
    private var cancellables = Set<AnyCancellable>()
    
    private init() {
        // Generate developer token on initialization
        developerToken = generateDeveloperToken()
        checkAuthorizationStatus()
    }
    
    // MARK: - Developer Token Generation
    
    // Your credentials
    private let teamID = "5RP4WRQ9V2"
    private let keyID = "7BWZNSH39T"
    
    func generateDeveloperToken() -> String? {
        do {
            // Load the private key from the app bundle
            guard let keyData = loadPrivateKeyFromBundle() else {
                print("Failed to load private key file from bundle")
                return nil
            }
            
            // Create the JWT payload
            let now = Date()
            let expirationDate = now.addingTimeInterval(15777000) // ~6 months in seconds
            
            let payload: [String: Any] = [
                "iss": teamID,
                "iat": Int(now.timeIntervalSince1970),
                "exp": Int(expirationDate.timeIntervalSince1970),
                "sub": "media.music-memory.jacobrees.com"
            ]
            
            // Create the JWT header
            let header: [String: Any] = [
                "alg": "ES256",
                "kid": keyID
            ]
            
            // Generate the token
            return try generateJWT(header: header, payload: payload, keyData: keyData)
            
        } catch {
            print("Error generating developer token: \(error.localizedDescription)")
            return nil
        }
    }
    
    // Load the private key from the app bundle
    private func loadPrivateKeyFromBundle() -> Data? {
        guard let keyPath = Bundle.main.path(forResource: "Music_Memory_MusicKit_Key", ofType: "p8") else {
            print("Key file not found in bundle")
            return nil
        }
        
        print("Key path found: \(keyPath)")
        return FileManager.default.contents(atPath: keyPath)
    }
    
    // Extract the private key from the .p8 file data
    private func extractPrivateKey(from data: Data) throws -> P256.Signing.PrivateKey {
        // Convert the data to a string
        guard let pemString = String(data: data, encoding: .utf8) else {
            throw NSError(domain: "AppleMusicAuth", code: 1, userInfo: [NSLocalizedDescriptionKey: "Invalid key data"])
        }
        
        // Extract just the base64 content between the header and footer
        let keyString = pemString
            .replacingOccurrences(of: "-----BEGIN PRIVATE KEY-----", with: "")
            .replacingOccurrences(of: "-----END PRIVATE KEY-----", with: "")
            .replacingOccurrences(of: "\n", with: "")
            .trimmingCharacters(in: .whitespacesAndNewlines)
        
        // Decode base64
        guard let keyData = Data(base64Encoded: keyString) else {
            throw NSError(domain: "AppleMusicAuth", code: 2, userInfo: [NSLocalizedDescriptionKey: "Invalid base64 data"])
        }
        
        // Create the private key using PKCS8 format
        return try P256.Signing.PrivateKey(derRepresentation: keyData)
    }
    
    // Generate JWT token
    private func generateJWT(header: [String: Any], payload: [String: Any], keyData: Data) throws -> String {
        // Encode header and payload as base64
        let headerData = try JSONSerialization.data(withJSONObject: header)
        let headerBase64 = headerData.base64EncodedString()
            .replacingOccurrences(of: "=", with: "")
            .replacingOccurrences(of: "+", with: "-")
            .replacingOccurrences(of: "/", with: "_")
        
        let payloadData = try JSONSerialization.data(withJSONObject: payload)
        let payloadBase64 = payloadData.base64EncodedString()
            .replacingOccurrences(of: "=", with: "")
            .replacingOccurrences(of: "+", with: "-")
            .replacingOccurrences(of: "/", with: "_")
        
        // Create the content to sign
        let signingInput = "\(headerBase64).\(payloadBase64)"
        guard let signingData = signingInput.data(using: .utf8) else {
            throw NSError(domain: "AppleMusicAuth", code: 3, userInfo: [NSLocalizedDescriptionKey: "Failed to create signing data"])
        }
        
        // Extract private key and sign the content
        let privateKey = try extractPrivateKey(from: keyData)
        let signature = try privateKey.signature(for: signingData)
        let signatureBase64 = signature.rawRepresentation.base64EncodedString()
            .replacingOccurrences(of: "=", with: "")
            .replacingOccurrences(of: "+", with: "-")
            .replacingOccurrences(of: "/", with: "_")
        
        // Combine to create JWT
        return "\(signingInput).\(signatureBase64)"
    }
    
    // MARK: - Authentication and Authorization
    
    func checkAuthorizationStatus() {
        Task { @MainActor in
            let status = MusicAuthorization.currentStatus
            
            self.authorizationStatus = status
            self.isAuthorized = status == .authorized
            
            // Check if the user has an Apple Music subscription
            if status == .authorized {
                self.checkSubscriptionStatus()
            }
        }
    }
    
    func requestAuthorization() async -> MusicAuthorization.Status {
        // Ensure we have a developer token
        if developerToken == nil {
            developerToken = generateDeveloperToken()
        }
        
        let status = await MusicAuthorization.request()
        
        await MainActor.run {
            self.authorizationStatus = status
            self.isAuthorized = status == .authorized
            
            if status == .authorized {
                self.checkSubscriptionStatus()
            }
        }
        
        return status
    }
    
    func checkSubscriptionStatus() {
        Task {
            do {
                // Use the correct subscription status check
                let subscription = try await MusicSubscription.current
                
                await MainActor.run {
                    self.isSubscribed = subscription.canPlayCatalogContent
                }
            } catch {
                print("Error checking subscription status: \(error.localizedDescription)")
                await MainActor.run {
                    self.isSubscribed = false
                    self.error = error
                }
            }
        }
    }
    
    // MARK: - Search and Version Finding
    
    func searchAppleMusic(for query: String, limit: Int = 25) async {
        // Don't search if query is empty or too short
        guard !query.isEmpty && query.count >= 2 else {
            await MainActor.run {
                self.searchResults = MusicItemCollection<Song>([])
                self.isSearching = false
            }
            return
        }
        
        // Check for developer token
        guard developerToken != nil else {
            await MainActor.run {
                self.error = NSError(domain: "AppleMusicManager", code: 1,
                                    userInfo: [NSLocalizedDescriptionKey: "Developer token not available"])
                self.isSearching = false
            }
            return
        }
        
        await MainActor.run {
            self.isSearching = true
            self.error = nil
        }
        
        do {
            var request = MusicCatalogSearchRequest(term: query, types: [Song.self])
            request.limit = limit
            
            let response = try await request.response()
            
            await MainActor.run {
                self.searchResults = response.songs
                self.isSearching = false
            }
        } catch {
            print("Error searching Apple Music: \(error.localizedDescription)")
            await MainActor.run {
                self.searchResults = MusicItemCollection<Song>([])
                self.isSearching = false
                self.error = error
            }
        }
    }
    
    func findVersionsForSong(_ librarySong: MPMediaItem) async -> [Song] {
        // Check for developer token
        guard developerToken != nil else {
            await MainActor.run {
                self.error = NSError(domain: "AppleMusicManager", code: 1,
                                   userInfo: [NSLocalizedDescriptionKey: "Developer token not available"])
                self.isSearching = false
            }
            return []
        }
        
        await MainActor.run {
            self.isSearching = true
            self.error = nil
        }
        
        // Create a search query using song title and artist
        let songTitle = librarySong.title ?? ""
        let artistName = librarySong.artist ?? ""
        
        // Skip if we don't have enough info
        guard !songTitle.isEmpty else {
            await MainActor.run {
                self.isSearching = false
            }
            return []
        }
        
        // Formulate a search that will find versions of the track
        let query = "\(songTitle) \(artistName)".trimmingCharacters(in: .whitespacesAndNewlines)
        
        do {
            var request = MusicCatalogSearchRequest(term: query, types: [Song.self])
            request.limit = 20
            
            let response = try await request.response()
            
            // Convert MusicItemCollection to Array
            let songsArray = response.songs.compactMap { $0 }
            
            await MainActor.run {
                self.isSearching = false
            }
            
            // Return results directly without complex filtering
            return songsArray
        } catch {
            print("Error finding versions: \(error.localizedDescription)")
            await MainActor.run {
                self.isSearching = false
                self.error = error
            }
            return []
        }
    }
    
    // MARK: - Playlist and Library Management
    
    func createPlaylist(name: String, description: String?, songs: [Song]) async -> Bool {
        do {
            // Use underscore to ignore the returned playlist and suppress warning
            _ = try await MusicLibrary.shared.createPlaylist(
                name: name,
                description: description ?? "Created by Music Memory",
                items: songs
            )
            
            print("Successfully created playlist: \(name) with \(songs.count) songs")
            return true
        } catch {
            print("Error creating playlist: \(error.localizedDescription)")
            await MainActor.run {
                self.error = error
            }
            return false
        }
    }
    
    func addSongToLibrary(_ song: Song) async -> Bool {
        do {
            // Pass the individual song directly, not as an array
            try await MusicLibrary.shared.add(song)
            print("Successfully added song to library: \(song.title)")
            return true
        } catch {
            print("Error adding song to library: \(error.localizedDescription)")
            await MainActor.run {
                self.error = error
            }
            return false
        }
    }
}
