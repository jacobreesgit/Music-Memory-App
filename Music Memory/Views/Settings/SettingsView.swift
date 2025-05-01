//
//  SettingsView.swift
//  Music Memory
//
//  Created by Jacob Rees on 01/05/2025.
//

import SwiftUI
import MediaPlayer

struct SettingsView: View {
    @EnvironmentObject var musicLibrary: MusicLibraryModel
    @State private var showingAbout = false
    @State private var showingConfirmation = false
    @State private var isRefreshing = false
    @AppStorage("useSystemAppearance") private var useSystemAppearance = true
    @AppStorage("isDarkMode") private var isDarkMode = false
    @AppStorage("allowAnalytics") private var allowAnalytics = false
    
    var body: some View {
        List {
            // Appearance section
            Section(header: Text("APPEARANCE")) {
                Toggle("Use System Appearance", isOn: $useSystemAppearance)
                
                if !useSystemAppearance {
                    Toggle("Dark Mode", isOn: $isDarkMode)
                        .onChange(of: isDarkMode) { _ in
                            updateAppearance()
                        }
                }
            }
            
            // Library section
            Section(header: Text("LIBRARY")) {
                Button(action: {
                    showingConfirmation = true
                }) {
                    HStack {
                        Image(systemName: "arrow.clockwise")
                            .foregroundColor(.blue)
                            .font(.system(size: 16))
                        
                        Text("Refresh Music Library")
                            .foregroundColor(.blue)
                    }
                }
                .disabled(isRefreshing)
                .alert("Refresh Library", isPresented: $showingConfirmation) {
                    Button("Cancel", role: .cancel) { }
                    Button("Refresh") {
                        refreshLibrary()
                    }
                } message: {
                    Text("This will reload all songs, albums, artists, and playlists from your music library.")
                }
                
                // Music Library Permission
                Button(action: {
                    if let url = URL(string: UIApplication.openSettingsURLString) {
                        UIApplication.shared.open(url)
                    }
                }) {
                    HStack {
                        Image(systemName: "lock.shield")
                            .foregroundColor(.blue)
                            .font(.system(size: 16))
                        
                        Text("Manage Permissions")
                            .foregroundColor(.blue)
                    }
                }
                
                // Analytics Toggle
                Toggle("Allow Anonymous Analytics", isOn: $allowAnalytics)
            }
            
            // App information section
            Section(header: Text("APP INFORMATION")) {
                Button(action: {
                    showingAbout = true
                }) {
                    HStack {
                        Image(systemName: "info.circle")
                            .foregroundColor(.blue)
                        Text("About Music Memory")
                            .foregroundColor(.blue)
                    }
                }
                .sheet(isPresented: $showingAbout) {
                    AboutView()
                }
            }
            
            // Legal section
            Section(header: Text("LEGAL")) {
                NavigationLink(destination: TermsView()) {
                    HStack {
                        Image(systemName: "doc.text")
                            .foregroundColor(AppStyles.accentColor)
                        Text("Terms of Service")
                    }
                }
                
                NavigationLink(destination: PrivacyPolicyView()) {
                    HStack {
                        Image(systemName: "hand.raised")
                            .foregroundColor(AppStyles.accentColor)
                        Text("Privacy Policy")
                    }
                }
            }
        }
        .navigationTitle("Settings")
        .navigationBarTitleDisplayMode(.inline)
        .listStyle(InsetGroupedListStyle())
        .onAppear {
            // Set initial appearance
            updateAppearance()
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

struct SettingsView_Previews: PreviewProvider {
    static var previews: some View {
        SettingsView()
            .environmentObject(MusicLibraryModel())
    }
}
