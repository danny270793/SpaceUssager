//
//  HelpView.swift
//  SpaceUssager
//
//  Created by SpaceUssager on 11/7/25.
//

import SwiftUI

struct HelpView: View {
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 30) {
                // Header
                VStack(alignment: .leading, spacing: 10) {
                    HStack {
                        Image(systemName: "questionmark.circle.fill")
                            .font(.system(size: 50))
                            .foregroundColor(.accentColor)
                        
                        Spacer()
                        
                        Button(action: { dismiss() }) {
                            Image(systemName: "xmark.circle.fill")
                                .font(.title2)
                                .foregroundColor(.secondary)
                        }
                        .buttonStyle(.plain)
                    }
                    
                    Text(String(localized: "help.title", defaultValue: "SpaceUssager Help"))
                        .font(.largeTitle)
                        .fontWeight(.bold)
                    
                    Text(String(localized: "help.subtitle", defaultValue: "Learn how to analyze your disk space"))
                        .font(.title3)
                        .foregroundColor(.secondary)
                }
                
                Divider()
                
                // Getting Started
                HelpSection(
                    title: String(localized: "help.gettingStarted.title", defaultValue: "Getting Started"),
                    icon: "play.circle.fill",
                    content: [
                        HelpItem(
                            title: String(localized: "help.gettingStarted.step1.title", defaultValue: "Select a Folder"),
                            description: String(localized: "help.gettingStarted.step1.description", defaultValue: "Click the 'Select Folder' button in the toolbar or press ⌘O to choose a folder to analyze.")
                        ),
                        HelpItem(
                            title: String(localized: "help.gettingStarted.step2.title", defaultValue: "Wait for Scan"),
                            description: String(localized: "help.gettingStarted.step2.description", defaultValue: "The app will scan the folder and calculate sizes. Large folders may take a few moments.")
                        ),
                        HelpItem(
                            title: String(localized: "help.gettingStarted.step3.title", defaultValue: "Explore Results"),
                            description: String(localized: "help.gettingStarted.step3.description", defaultValue: "Files and folders are sorted by size, with the largest items at the top.")
                        )
                    ]
                )
                
                Divider()
                
                // Navigation
                HelpSection(
                    title: String(localized: "help.navigation.title", defaultValue: "Navigation"),
                    icon: "arrow.left.arrow.right.circle.fill",
                    content: [
                        HelpItem(
                            title: String(localized: "help.navigation.enterFolder.title", defaultValue: "Enter a Folder"),
                            description: String(localized: "help.navigation.enterFolder.description", defaultValue: "Click on any folder in the list to navigate into it and see its contents.")
                        ),
                        HelpItem(
                            title: String(localized: "help.navigation.goBack.title", defaultValue: "Go Back"),
                            description: String(localized: "help.navigation.goBack.description", defaultValue: "Click the '..' item at the top of the list to go back to the parent folder.")
                        ),
                        HelpItem(
                            title: String(localized: "help.navigation.breadcrumb.title", defaultValue: "Current Path"),
                            description: String(localized: "help.navigation.breadcrumb.description", defaultValue: "The current folder path is always displayed at the top of the window.")
                        )
                    ]
                )
                
                Divider()
                
                // Features
                HelpSection(
                    title: String(localized: "help.features.title", defaultValue: "Features"),
                    icon: "star.circle.fill",
                    content: [
                        HelpItem(
                            title: String(localized: "help.features.search.title", defaultValue: "Search"),
                            description: String(localized: "help.features.search.description", defaultValue: "Use the search bar in the toolbar to filter files and folders by name. Press ⌘F to focus the search.")
                        ),
                        HelpItem(
                            title: String(localized: "help.features.sizes.title", defaultValue: "Size Display"),
                            description: String(localized: "help.features.sizes.description", defaultValue: "File sizes are shown in human-readable format (KB, MB, GB). Folder sizes include all their contents.")
                        ),
                        HelpItem(
                            title: String(localized: "help.features.stats.title", defaultValue: "Statistics"),
                            description: String(localized: "help.features.stats.description", defaultValue: "The bottom bar shows total size, file count, and folder count for the current view.")
                        ),
                        HelpItem(
                            title: String(localized: "help.features.progressive.title", defaultValue: "Progressive Loading"),
                            description: String(localized: "help.features.progressive.description", defaultValue: "Results appear as they're scanned, so you can start exploring immediately.")
                        )
                    ]
                )
                
                Divider()
                
                // Keyboard Shortcuts
                HelpSection(
                    title: String(localized: "help.shortcuts.title", defaultValue: "Keyboard Shortcuts"),
                    icon: "command.circle.fill",
                    content: [
                        HelpItem(
                            title: "⌘O",
                            description: String(localized: "help.shortcuts.open", defaultValue: "Open folder selector")
                        ),
                        HelpItem(
                            title: "⌘F",
                            description: String(localized: "help.shortcuts.search", defaultValue: "Focus search field")
                        ),
                        HelpItem(
                            title: "⌘?",
                            description: String(localized: "help.shortcuts.help", defaultValue: "Show this help window")
                        )
                    ]
                )
                
                Divider()
                
                // Tips
                VStack(alignment: .leading, spacing: 15) {
                    HStack {
                        Image(systemName: "lightbulb.fill")
                            .foregroundColor(.yellow)
                        Text(String(localized: "help.tips.title", defaultValue: "Tips"))
                            .font(.title2)
                            .fontWeight(.semibold)
                    }
                    
                    VStack(alignment: .leading, spacing: 10) {
                        TipRow(String(localized: "help.tips.tip1", defaultValue: "Wait for the scan to complete before navigating to get accurate sizes"))
                        TipRow(String(localized: "help.tips.tip2", defaultValue: "Use search to quickly find specific files or folders"))
                        TipRow(String(localized: "help.tips.tip3", defaultValue: "The largest files appear at the top - perfect for finding space hogs"))
                        TipRow(String(localized: "help.tips.tip4", defaultValue: "Hidden files are not shown in the results"))
                    }
                }
            }
            .padding(30)
        }
        .frame(width: 600, height: 700)
    }
}

private struct HelpSection: View {
    let title: String
    let icon: String
    let content: [HelpItem]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 15) {
            HStack {
                Image(systemName: icon)
                    .foregroundColor(.accentColor)
                Text(title)
                    .font(.title2)
                    .fontWeight(.semibold)
            }
            
            VStack(alignment: .leading, spacing: 12) {
                ForEach(content) { item in
                    VStack(alignment: .leading, spacing: 4) {
                        Text(item.title)
                            .font(.headline)
                        Text(item.description)
                            .font(.body)
                            .foregroundColor(.secondary)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }
            }
        }
    }
}

private struct HelpItem: Identifiable {
    let id = UUID()
    let title: String
    let description: String
}

private struct TipRow: View {
    let text: String
    
    init(_ text: String) {
        self.text = text
    }
    
    var body: some View {
        HStack(alignment: .top, spacing: 8) {
            Text("•")
                .foregroundColor(.secondary)
            Text(text)
                .font(.body)
                .foregroundColor(.secondary)
                .fixedSize(horizontal: false, vertical: true)
        }
    }
}

#Preview {
    HelpView()
}

