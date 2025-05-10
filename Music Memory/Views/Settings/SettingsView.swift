//
//  SettingsView.swift
//  Music Memory
//
//  Created by Jacob Rees on 01/05/2025.
//

import SwiftUI
import MediaPlayer
import MusicKit

struct SettingsView: View {
    @EnvironmentObject var musicLibrary: MusicLibraryModel
    @State private var showingAbout = false
    @State private var showingConfirmation = false
    @State private var isRefreshing = false
    @AppStorage("useSystemAppearance") private var useSystemAppearance = true
    @AppStorage("isDarkMode") private var isDarkMode = false
    @State private var showingMusicKitDebug = false
    
    var body: some View {
        VStack(spacing: 0) {
            List {
                // APPEARANCE SECTION
                Section(header:
                    Text("APPEARANCE")
                        .font(.footnote)
                        .foregroundColor(.secondary)
                        .padding(.top, 15)
                        .padding(.bottom, 5)
                ) {
                    Toggle("Use System Appearance", isOn: $useSystemAppearance)
                        .padding(.vertical, 2)
                    
                    if !useSystemAppearance {
                        Toggle("Dark Mode", isOn: $isDarkMode)
                            .padding(.vertical, 2)
                            .onChange(of: isDarkMode) { _ in
                                updateAppearance()
                            }
                    }
                }
                
                // LIBRARY SECTION
                Section(header:
                    Text("LIBRARY")
                        .font(.footnote)
                        .foregroundColor(.secondary)
                        .padding(.top, 15)
                        .padding(.bottom, 5)
                ) {
                    Toggle("Hide Items with 0 Plays", isOn: .constant(true))
                        .padding(.vertical, 2)
                    
                    Button(action: {
                        showingConfirmation = true
                    }) {
                        HStack {
                            Image(systemName: "arrow.clockwise")
                                .foregroundColor(.blue)
                                .frame(width: 20)
                            
                            Text("Refresh Music Library")
                                .foregroundColor(.blue)
                                .frame(maxWidth: .infinity, alignment: .leading)
                        }
                    }
                    .padding(.vertical, 6)
                    
                    Button(action: {
                        if let url = URL(string: UIApplication.openSettingsURLString) {
                            UIApplication.shared.open(url)
                        }
                    }) {
                        HStack {
                            Image(systemName: "lock.shield")
                                .foregroundColor(.blue)
                                .frame(width: 20)
                            
                            Text("Manage Permissions")
                                .foregroundColor(.blue)
                                .frame(maxWidth: .infinity, alignment: .leading)
                        }
                    }
                    .padding(.vertical, 6)
                }
                
                // DEBUGGING SECTION
                Section(header:
                    Text("DEBUGGING")
                        .font(.footnote)
                        .foregroundColor(.secondary)
                        .padding(.top, 15)
                        .padding(.bottom, 5)
                ) {
                    Button(action: {
                        showingMusicKitDebug = true
                    }) {
                        HStack {
                            Image(systemName: "waveform.badge.magnifyingglass")
                                .foregroundColor(.blue)
                                .frame(width: 20)
                            
                            Text("Test MusicKit Integration")
                                .foregroundColor(.blue)
                                .frame(maxWidth: .infinity, alignment: .leading)
                        }
                    }
                    .padding(.vertical, 6)
                }
                
                // APP INFORMATION SECTION
                Section(header:
                    Text("APP INFORMATION")
                        .font(.footnote)
                        .foregroundColor(.secondary)
                        .padding(.top, 15)
                        .padding(.bottom, 5)
                ) {
                    Button(action: {
                        showingAbout = true
                    }) {
                        HStack {
                            Image(systemName: "info.circle")
                                .foregroundColor(.blue)
                                .frame(width: 20)
                            
                            Text("About Music Memory")
                                .foregroundColor(.blue)
                                .frame(maxWidth: .infinity, alignment: .leading)
                        }
                    }
                    .padding(.vertical, 6)
                }
                
                // LEGAL SECTION
                Section(header:
                    Text("LEGAL")
                        .font(.footnote)
                        .foregroundColor(.secondary)
                        .padding(.top, 15)
                        .padding(.bottom, 5)
                ) {
                    NavigationLink(destination: TermsView()) {
                        HStack {
                            Image(systemName: "doc.text")
                                .foregroundColor(.purple)
                                .frame(width: 20)
                            
                            Text("Terms of Service")
                        }
                    }
                    .padding(.vertical, 2)
                    
                    NavigationLink(destination: PrivacyPolicyView()) {
                        HStack {
                            Image(systemName: "hand.raised")
                                .foregroundColor(.purple)
                                .frame(width: 20)
                            
                            Text("Privacy Policy")
                        }
                    }
                    .padding(.vertical, 2)
                }
            }
            .listStyle(InsetGroupedListStyle())
            // This removes extra separator lines below the list
            .environment(\.defaultMinListRowHeight, 0)
            // Remove inset on all sides
            .listRowInsets(EdgeInsets())
        }
        .navigationTitle("Settings")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            // Set initial appearance
            updateAppearance()
            
            // Improve list appearance
            UITableView.appearance().backgroundColor = .systemGroupedBackground
            
            // Fix separator insets for alignment
            UITableView.appearance().separatorInset = UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 0)
            UITableView.appearance().separatorStyle = .singleLine
        }
        .alert("Refresh Library", isPresented: $showingConfirmation) {
            Button("Cancel", role: .cancel) { }
            Button("Refresh") {
                refreshLibrary()
            }
        } message: {
            Text("This will reload all songs, albums, artists, and playlists from your music library.")
        }
        .sheet(isPresented: $showingAbout) {
            AboutView()
        }
        .sheet(isPresented: $showingMusicKitDebug) {
            MusicKitDebugView()
        }
    }
    
    private func refreshLibrary() {
        isRefreshing = true
        
        // Simulate loading delay for UI feedback
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            musicLibrary.requestPermissionAndLoadLibrary()
            
            // Allow some time for the refresh to process
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                isRefreshing = false
            }
        }
    }
    
    private func updateAppearance() {
        let windows = UIApplication.shared.connectedScenes
            .compactMap { $0 as? UIWindowScene }
            .flatMap { $0.windows }
        
        for window in windows {
            window.overrideUserInterfaceStyle = useSystemAppearance ? .unspecified : (isDarkMode ? .dark : .light)
        }
    }
}

// About View
struct AboutView: View {
    var body: some View {
        VStack(spacing: 20) {
            // App icon
            Image(systemName: "music.note.list")
                .font(.system(size: 80))
                .foregroundColor(AppStyles.accentColor)
                .padding()
            
            // App info
            Text("Music Memory")
                .font(.title.bold())
            
            Text("Version 1.0.0")
                .foregroundColor(.secondary)
            
            Divider()
                .padding(.horizontal)
            
            // Description
            Text("Music Memory helps you discover your listening habits by analyzing your music library play counts and presenting insights about your music collection.")
                .multilineTextAlignment(.center)
                .padding(.horizontal)
            
            // Credits
            VStack {
                Text("Created by")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                Text("Jacob Rees at Jaba")
                    .font(.headline)
            }
            .padding(.top)
            
            Button(action: {
                if let url = URL(string: "mailto:jacobrees@icloud.com") {
                    UIApplication.shared.open(url)
                }
            }) {
                HStack {
                    Image(systemName: "envelope")
                        .font(.system(size: 14))
                    Text("Contact: jacobrees@icloud.com")
                        .font(.subheadline)
                }
                .foregroundColor(.blue)
            }
            .padding(.top, 8)
            
            Spacer()
            
            // Dismiss button
            Button(action: {
                // This will dismiss the sheet
            }) {
                Text("Done")
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(AppStyles.accentColor)
                    .foregroundColor(.white)
                    .cornerRadius(10)
            }
            .padding(.horizontal)
            .presentationDetents([.medium])
        }
        .padding()
    }
}

// Terms View
struct TermsView: View {
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 15) {
                Text("Terms of Service")
                    .font(.title.bold())
                    .padding(.bottom)
                
                Group {
                    Text("1. Acceptance of Terms")
                        .font(.headline)
                    Text("By downloading and using Music Memory, you agree to these Terms of Service and our Privacy Policy.")
                    
                    Text("2. Description of Service")
                        .font(.headline)
                    Text("Music Memory provides analytics about your music library's play count data, with all processing performed locally on your device.")
                    
                    Text("3. User Restrictions")
                        .font(.headline)
                    Text("You agree not to modify, reverse engineer, or attempt to access parts of the application beyond its intended interface.")
                    
                    Text("4. Intellectual Property")
                        .font(.headline)
                    Text("Music Memory and all related content are protected by copyright, trademark, and other intellectual property laws in the United Kingdom.")
                    
                    Text("5. Disclaimer of Warranties")
                        .font(.headline)
                    Text("The application is provided \"as is\" without warranties of any kind, either express or implied.")
                }
                
                Group {
                    Text("6. Limitation of Liability")
                        .font(.headline)
                    Text("Under no circumstances shall we be liable for any indirect, incidental, special, or consequential damages.")
                    
                    Text("7. Governing Law")
                        .font(.headline)
                    Text("These terms shall be governed by the laws of England and Wales. Any dispute arising from these terms will be subject to the exclusive jurisdiction of the courts of England and Wales.")
                    
                    Text("8. Changes to Terms")
                        .font(.headline)
                    Text("We reserve the right to modify these terms at any time. We will provide notification of significant changes.")
                }
            }
            .padding()
        }
        .navigationTitle("Terms of Service")
    }
}

// Privacy Policy View
struct PrivacyPolicyView: View {
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 15) {
                Text("Privacy Policy")
                    .font(.title.bold())
                    .padding(.bottom)
                
                Group {
                    Text("1. Information Collection")
                        .font(.headline)
                    Text("Music Memory accesses your device's music library metadata only. This includes song titles, artists, albums, and play counts. This data is processed entirely on your device, in compliance with the UK General Data Protection Regulation (UK GDPR) and the Data Protection Act 2018.")
                    
                    Text("2. Information Usage")
                        .font(.headline)
                    Text("We use this information solely to provide the analytics features of the app. No data is transmitted from your device unless you explicitly enable anonymous analytics.")
                    
                    Text("3. Data Storage")
                        .font(.headline)
                    Text("All your music data is stored locally on your device. We do not maintain any servers that store or process your personal music information.")
                    
                    Text("4. Analytics")
                        .font(.headline)
                    Text("If you enable anonymous analytics, we collect minimal information about app usage to improve our service. This data is anonymized and contains no personally identifiable information or details about your music library.")
                }
                
                Group {
                    Text("5. Third Parties")
                        .font(.headline)
                    Text("We do not share any of your information with third parties.")
                    
                    Text("6. Your Rights")
                        .font(.headline)
                    Text("Under UK data protection law, you have rights including the right to access, correct, or delete your personal data. You can disable music library access at any time through your device settings or disable analytics in the app's privacy settings.")
                    
                    Text("7. Changes to Policy")
                        .font(.headline)
                    Text("We may update our Privacy Policy from time to time. We will notify you of any changes by posting the new Privacy Policy in the app.")
                    
                    Text("8. Data Controller & Contact")
                        .font(.headline)
                    Text("The data controller for Music Memory is Jacob Rees (Jaba), based in the United Kingdom. If you have any questions or concerns about this Privacy Policy, please contact us at jacobrees@icloud.com.")
                    
                    Text("9. Supervisory Authority")
                        .font(.headline)
                    Text("You have the right to lodge a complaint with the Information Commissioner's Office (ICO), the UK data protection regulator.")
                }
            }
            .padding()
        }
        .navigationTitle("Privacy Policy")
    }
}

// Extension for UserDefaults binding
extension UserDefaults {
    func bind<T>(for keyPath: ReferenceWritableKeyPath<UserDefaults, T?>, default defaultValue: T) -> Binding<T> {
        return Binding<T>(
            get: { self[keyPath: keyPath] ?? defaultValue },
            set: { self[keyPath: keyPath] = $0 }
        )
    }
}
