//
//  TimePeriod.swift
//  Music Memory
//
//  Created by Jacob Rees on 11/05/2025.
//

import Foundation

/// Enumeration defining the available time periods
enum TimePeriod: String, CaseIterable, Identifiable {
    case week = "Week"
    case month = "Month"
    case year = "Year" 
    case allTime = "All Time"
    
    var id: String { self.rawValue }
    
    /// Returns the date for the start of this time period
    func startDate() -> Date? {
        let calendar = Calendar.current
        let now = Date()
        
        switch self {
        case .week:
            return calendar.date(byAdding: .day, value: -7, to: now)
        case .month:
            return calendar.date(byAdding: .month, value: -1, to: now)
        case .year:
            return calendar.date(byAdding: .year, value: -1, to: now)
        case .allTime:
            return nil // No start date restriction
        }
    }
}