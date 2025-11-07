//
//  WelcomeView.swift
//  SpaceUssager
//
//  Created by dvaca on 6/11/25.
//

import SwiftUI

struct WelcomeView: View {
    let onSelectFolder: () -> Void
    
    var body: some View {
        VStack(spacing: 32) {
            Spacer()
            
            // App Icon and Title
            VStack(spacing: 16) {
                Image(systemName: "internaldrive")
                    .font(.system(size: 80))
                    .foregroundStyle(.blue.gradient)
                
                Text(String(localized: "welcome.title", defaultValue: "Welcome to Space Ussager"))
                    .font(.system(.largeTitle, design: .rounded))
                    .fontWeight(.bold)
                
                Text(String(localized: "welcome.subtitle", defaultValue: "Analyze and understand your disk space usage"))
                    .font(.title3)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }
            .padding(.bottom, 24)
            
            // Features
            VStack(alignment: .leading, spacing: 20) {
                FeatureRow(
                    icon: "folder.fill.badge.gearshape",
                    title: String(localized: "welcome.feature1.title", defaultValue: "Scan Any Folder"),
                    description: String(localized: "welcome.feature1.description", defaultValue: "Quickly analyze the contents of any folder on your Mac")
                )
                
                FeatureRow(
                    icon: "chart.bar.fill",
                    title: String(localized: "welcome.feature2.title", defaultValue: "See File Sizes"),
                    description: String(localized: "welcome.feature2.description", defaultValue: "View files and folders sorted by size to identify space hogs")
                )
                
                FeatureRow(
                    icon: "magnifyingglass",
                    title: String(localized: "welcome.feature3.title", defaultValue: "Search & Filter"),
                    description: String(localized: "welcome.feature3.description", defaultValue: "Find specific files and folders with instant search")
                )
                
                FeatureRow(
                    icon: "arrow.left.arrow.right",
                    title: String(localized: "welcome.feature4.title", defaultValue: "Easy Navigation"),
                    description: String(localized: "welcome.feature4.description", defaultValue: "Navigate through your folder structure with ease")
                )
            }
            .padding(.horizontal, 40)
            .frame(maxWidth: 500)
            
            Spacer()
            
            // Get Started Button
            Button(action: onSelectFolder) {
                Label(String(localized: "welcome.getStarted", defaultValue: "Get Started"), systemImage: "arrow.right.circle.fill")
                    .font(.title3)
                    .fontWeight(.semibold)
                    .foregroundColor(.white)
                    .padding(.horizontal, 32)
                    .padding(.vertical, 16)
                    .background(
                        LinearGradient(
                            colors: [.blue, .blue.opacity(0.8)],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .cornerRadius(12)
                    .shadow(color: .blue.opacity(0.3), radius: 8, x: 0, y: 4)
            }
            .buttonStyle(.plain)
            .padding(.bottom, 40)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(
            LinearGradient(
                colors: [
                    Color(nsColor: .controlBackgroundColor),
                    Color(nsColor: .controlBackgroundColor).opacity(0.8)
                ],
                startPoint: .top,
                endPoint: .bottom
            )
        )
    }
}

struct FeatureRow: View {
    let icon: String
    let title: String
    let description: String
    
    var body: some View {
        HStack(alignment: .top, spacing: 16) {
            Image(systemName: icon)
                .font(.system(size: 28))
                .foregroundStyle(.blue.gradient)
                .frame(width: 40)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.headline)
                    .fontWeight(.semibold)
                
                Text(description)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
    }
}

#Preview {
    WelcomeView(onSelectFolder: {})
}

