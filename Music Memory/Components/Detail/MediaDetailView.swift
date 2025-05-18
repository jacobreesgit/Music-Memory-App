//
//  MediaDetailView.swift
//  Music Memory
//  Updated to support bottom safe area

import SwiftUI
import MediaPlayer

/// A reusable container for detail views using a consistent layout pattern
struct MediaDetailView<Item: MediaDetailDisplayable, HeaderContent: View, Content: View>: View {
    let item: Item
    let rank: Int?
    @ViewBuilder let headerContent: (Item) -> HeaderContent
    @ViewBuilder let additionalContent: (Item) -> Content
    
    // Primary initializer with header content
    init(
        item: Item,
        rank: Int? = nil,
        @ViewBuilder headerContent: @escaping (Item) -> HeaderContent,
        @ViewBuilder additionalContent: @escaping (Item) -> Content
    ) {
        self.item = item
        self.rank = rank
        self.headerContent = headerContent
        self.additionalContent = additionalContent
    }
    
    var body: some View {
        List {
            // Header section with item details
            Section(header: VStack(alignment: .center, spacing: 4) {
                DetailHeaderView(
                    title: item.displayTitle,
                    subtitle: item.displaySubtitle,
                    plays: item.totalPlayCount,
                    songCount: item.itemCount,
                    artwork: item.artwork,
                    isAlbum: item.isAlbumType,
                    metadata: [],
                    rank: rank ?? item.displayRank
                )
            }) {
                // Empty section content for spacing
            }
            
            // New: Header content section (for sort buttons)
            headerContent(item)
            
            // Statistics section with metadata
            Section(header: Text("Statistics")
                .padding(.leading, -15)) {
                ForEach(item.getMetadataItems()) { metadataItem in
                    MetadataRow(
                        icon: metadataItem.iconName,
                        title: metadataItem.label,
                        value: metadataItem.value
                    )
                    .listRowSeparator(.hidden)
                }
            }
            
            // Custom content specific to each media type
            additionalContent(item)
        }
        .listSectionSpacing(0) // Consistent spacing
        .navigationTitle(item.displayTitle)
        .navigationBarTitleDisplayMode(.inline)
        // Apply the bottom safe area modifier to ensure content is visible
        .withBottomSafeArea()
    }
}

// Extension to provide convenience initializer for backward compatibility
extension MediaDetailView where HeaderContent == EmptyView {
    init(
        item: Item,
        rank: Int? = nil,
        @ViewBuilder additionalContent: @escaping (Item) -> Content
    ) {
        self.item = item
        self.rank = rank
        self.headerContent = { _ in EmptyView() }
        self.additionalContent = additionalContent
    }
}
