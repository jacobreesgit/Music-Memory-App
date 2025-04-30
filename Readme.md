# Music Memory

A SwiftUI iOS 18 app that displays your music library sorted by play count with a unified design system.

## Overview

Music Memory analyzes your music listening habits by displaying your library sorted by play counts. The app provides insights into your most played songs, albums, and artists with a consistent, polished interface.

## Features

- **Dashboard View**: Quick overview of your top songs, albums, and artists
- **Library View**: Tabbed interface to browse your music collection
  - **Songs Tab**: Complete list of all songs sorted by play count
  - **Artists Tab**: Artists sorted by total play count with detailed views
  - **Albums Tab**: Albums sorted by total play count with detailed views
  - **Genres Tab**: Genres sorted by song count with detailed views
  - **Playlists Tab**: Playlists sorted by total play count with detailed views
- **Detailed Statistics**: In-depth play count and metadata statistics for each item
- **Search & Sort**: Search through your library and sort by different criteria
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
2. Open `Music Memory.xcodeproj` in Xcode
3. Select your target device/simulator
4. Build and run (⌘+R)

## Project Structure

The project follows a clean, modular architecture with clear separation of concerns:

```
Music Memory/
├── App/                  # Core app files
│   ├── Music_MemoryApp.swift
│   └── ContentView.swift
│
├── Models/               # Data models
│   ├── MusicLibraryModel.swift
│   ├── AlbumData.swift
│   ├── ArtistData.swift
│   ├── GenreData.swift
│   └── PlaylistData.swift
│
├── Views/                # Main screens organized by feature
│   ├── Dashboard/
│   ├── Library/
│   ├── Songs/
│   ├── Albums/
│   ├── Artists/
│   ├── Genres/
│   └── Playlists/
│
├── Components/           # Reusable UI components
│   ├── Design/           # Design system
│   ├── Lists/            # List items, rows
│   ├── Headers/          # Header components
│   ├── Search/           # Search components
│   └── Common/           # Other shared components
│
└── Utilities/            # Helper classes and extensions
```

## Design System

Music Memory uses a centralized design system implemented in `Components/Design/AppStyles.swift` that provides:

- Consistent color palette and typography
- Standardized UI components
- Unified layout and spacing rules
- View modifiers for common styling patterns
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

## Contributing

Contributions are welcome! If you'd like to improve Music Memory:

1. Fork the repository
2. Create a new branch (`git checkout -b feature/amazing-feature`)
3. Make your changes
4. Commit your changes (`git commit -m 'Add some amazing feature'`)
5. Push to the branch (`git push origin feature/amazing-feature`)
6. Open a Pull Request

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
