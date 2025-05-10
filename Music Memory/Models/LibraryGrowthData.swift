//
//  LibraryGrowthData.swift
//  Music Memory
//
//  Created by Jacob Rees on 01/05/2025.
//

import Foundation

struct LibraryGrowthData: Identifiable {
    let id = UUID()
    let month: String
    let count: Int
    let date: Date
}
