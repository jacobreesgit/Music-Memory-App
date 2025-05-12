//  MediaDetailView.swift
//  Music Memory

import SwiftUI
import MediaPlayer

/// A reusable container for detail views using a consistent layout pattern
struct MediaDetailView<Item: MediaDetailDisplayable, Content: View>: View {
    let item: Item
    let rank: Int?
    @ViewBuilder let additionalContent: (Item) -> Content
    
    init(item: Item, rank: Int? = nil, @ViewBuilder additionalContent: @escaping (Item) -> Content) {
        self.item = item
        self.rank = rank
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
    }
}
