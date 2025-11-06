//
//  Logger.swift
//  SpaceUssager
//
//  Created by dvaca on 6/11/25.
//

import Foundation
import os.log

/// Centralized logger for the application
class AppLogger {
    static let shared = AppLogger()
    
    private let logger: os.Logger
    
    private init() {
        logger = os.Logger(subsystem: Bundle.main.bundleIdentifier ?? "com.spaceussager", category: "app")
    }
    
    // MARK: - Log Categories
    
    /// Log messages related to file scanning operations
    func scan(_ message: String, type: OSLogType = .default) {
        logger.log(level: type, "📂 [SCAN] \(message)")
    }
    
    /// Log messages related to navigation operations
    func navigation(_ message: String, type: OSLogType = .default) {
        logger.log(level: type, "⬆️ [NAV] \(message)")
    }
    
    /// Log messages related to UI interactions
    func ui(_ message: String, type: OSLogType = .default) {
        logger.log(level: type, "🖥️ [UI] \(message)")
    }
    
    /// Log messages related to file picker operations
    func picker(_ message: String, type: OSLogType = .default) {
        logger.log(level: type, "📂 [PICKER] \(message)")
    }
    
    // MARK: - Convenience Methods
    
    /// Log an error message
    func error(_ message: String, category: LogCategory = .general) {
        let prefix = category.emoji
        logger.error("\(prefix) [\(category.rawValue)] ❌ \(message)")
    }
    
    /// Log a warning message
    func warning(_ message: String, category: LogCategory = .general) {
        let prefix = category.emoji
        logger.warning("\(prefix) [\(category.rawValue)] ⚠️ \(message)")
    }
    
    /// Log an info message
    func info(_ message: String, category: LogCategory = .general) {
        let prefix = category.emoji
        logger.info("\(prefix) [\(category.rawValue)] ℹ️ \(message)")
    }
    
    /// Log a success message
    func success(_ message: String, category: LogCategory = .general) {
        let prefix = category.emoji
        logger.log(level: .default, "\(prefix) [\(category.rawValue)] ✅ \(message)")
    }
}

// MARK: - Log Category Enum

enum LogCategory: String {
    case scan = "SCAN"
    case navigation = "NAV"
    case ui = "UI"
    case picker = "PICKER"
    case general = "GENERAL"
    
    var emoji: String {
        switch self {
        case .scan: return "📂"
        case .navigation: return "⬆️"
        case .ui: return "🖥️"
        case .picker: return "📁"
        case .general: return "📋"
        }
    }
}

