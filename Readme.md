# Music Memory

A SwiftUI iOS 18 app that displays your music library sorted by play count with a unified design system.

## Overview

Music Memory analyzes your music listening habits by displaying your library sorted by play counts. The app provides insights into your most played songs, albums, and artists with a consistent, polished interface.

## Features

- **Dashboard View**: Quick overview of your top songs, albums, and artists
- **Songs Tab**: Complete list of all songs sorted by play count
- **Albums Tab**: Albums sorted by total play count with detailed views
- **Artists Tab**: Artists sorted by total play count with detailed views
- **Auto-refresh**: Library refreshes each time the app is opened
- **Privacy-focused**: Only accesses your music library with explicit permission
- **Unified Design System**: Consistent UI experience across all screens

## Requirements

- iOS 18.0+
- Xcode 16.0+
- Swift 5.0+
- Access to a music library (Apple Music or local music)

## Installation

1. Clone or download this repository
2. Open `MusicMemory.xcodeproj` in Xcode
3. Select your target device/simulator
4. Build and run (⌘+R)

## Usage

1. Launch the app
2. Grant permission to access your music library when prompted
3. Navigate through tabs to explore your music listening habits:
   - Dashboard: Quick overview with visual stats
   - Songs: View all songs sorted by play count
   - Albums: View albums and their total play counts
   - Artists: View artists and their total play counts

## Project Structure

```
MusicMemory/
├── Music_MemoryApp.swift    # App entry point
├── ContentView.swift        # Main tab structure
├── MusicLibraryModel.swift  # Music library data model
├── Structures.swift         # Core data structures
├── Components.swift         # UI components and design system
├── Views/
│   ├── DashboardView.swift  # Dashboard tab
│   ├── SongsView.swift      # Songs tab
│   ├── AlbumsView.swift     # Albums tab with detail view
│   └── ArtistsView.swift    # Artists tab with detail view
```

## Design System

Music Memory uses a centralized design system implemented in `Components.swift` that provides:

- Consistent color palette and typography
- Standardized UI components
- Unified layout and spacing rules
- Consistent appearance across all screens

This approach ensures a cohesive user experience and simplifies future UI updates.

## Data Access

Music Memory accesses your music library data via Apple's MediaPlayer framework. The app:

- Requests explicit permission before accessing your library
- Never uploads or shares your music data
- Only reads play count and metadata information

## Permissions

The app requires the `NSAppleMusicUsageDescription` permission:

- Purpose: To read music metadata and play counts
- Usage: Local processing only, no data leaves your device

## Troubleshooting

If the app doesn't show your music:

1. Ensure you've granted music library permission
2. Check Settings > Privacy > Media & Apple Music > Music Memory
3. Verify your device has music in its library
4. Force quit and restart the app

## Credits

Created by Jacob Rees at Jaba

## License

MIT License

Copyright (c) 2025 Jacob Rees - Jaba

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.
