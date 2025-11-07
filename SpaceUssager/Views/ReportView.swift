//
//  ReportView.swift
//  SpaceUssager
//
//  Created by SpaceUssager on 11/7/25.
//

import SwiftUI
import Charts

enum ItemFilter: String, CaseIterable, Identifiable {
    case all = "All"
    case filesOnly = "Files Only"
    case foldersOnly = "Folders Only"
    
    var id: String { self.rawValue }
}

struct ReportView: View {
    @Environment(\.dismiss) private var dismiss
    let files: [FileItem]
    let totalSize: Int64
    let folderPath: String
    let scanner: FileScanner
    
    @State private var selectedFilter: ItemFilter = .all
    @State private var isRecursive = false
    @State private var recursiveFiles: [FileItem] = []
    @State private var isLoadingRecursive = false
    
    var currentFiles: [FileItem] {
        isRecursive ? recursiveFiles : files
    }
    
    var filteredFiles: [FileItem] {
        switch selectedFilter {
        case .all:
            return currentFiles
        case .filesOnly:
            return currentFiles.filter { !$0.isDirectory }
        case .foldersOnly:
            return currentFiles.filter { $0.isDirectory }
        }
    }
    
    var fileCount: Int {
        filteredFiles.filter { !$0.isDirectory }.count
    }
    
    var folderCount: Int {
        filteredFiles.filter { $0.isDirectory }.count
    }
    
    var filteredTotalSize: Int64 {
        filteredFiles.reduce(0) { $0 + $1.size }
    }
    
    var largestItems: [FileItem] {
        Array(filteredFiles.prefix(10))
    }
    
    var fileTypeBreakdown: [(String, Int64)] {
        var typeMap: [String: Int64] = [:]
        
        for file in filteredFiles where !file.isDirectory {
            let ext = (file.name as NSString).pathExtension.lowercased()
            let displayType = ext.isEmpty ? "No Extension" : ext.uppercased()
            typeMap[displayType, default: 0] += file.size
        }
        
        // Add folders as a type
        let folderSize = filteredFiles.filter { $0.isDirectory }.reduce(0) { $0 + $1.size }
        if folderSize > 0 {
            typeMap["Folders"] = folderSize
        }
        
        return typeMap.sorted { $0.value > $1.value }.prefix(10).map { ($0.key, $0.value) }
    }
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 30) {
                    // Header
                    VStack(alignment: .leading, spacing: 8) {
                        Text(String(localized: "report.title", defaultValue: "Storage Report"))
                            .font(.largeTitle)
                            .fontWeight(.bold)
                        
                        HStack {
                            Image(systemName: "folder.fill")
                                .foregroundColor(.secondary)
                            Text(folderPath)
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                                .lineLimit(1)
                                .truncationMode(.middle)
                        }
                        
                        Text(Date(), style: .date)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    .padding(.horizontal)
                    
                    // Filter Picker
                    Picker(String(localized: "report.filter.title", defaultValue: "Show"), selection: $selectedFilter) {
                        Text(String(localized: "report.filter.all", defaultValue: "All")).tag(ItemFilter.all)
                        Text(String(localized: "report.filter.files", defaultValue: "Files Only")).tag(ItemFilter.filesOnly)
                        Text(String(localized: "report.filter.folders", defaultValue: "Folders Only")).tag(ItemFilter.foldersOnly)
                    }
                    .pickerStyle(.segmented)
                    .padding(.horizontal)
                    
                    // Recursive Toggle
                    HStack {
                        Toggle(isOn: $isRecursive) {
                            HStack(spacing: 8) {
                                Image(systemName: "arrow.down.to.line.compact")
                                    .foregroundColor(isRecursive ? .accentColor : .secondary)
                                Text(String(localized: "report.recursive.title", defaultValue: "Include all subfolders (recursive)"))
                                    .font(.subheadline)
                                if isLoadingRecursive {
                                    ProgressView()
                                        .scaleEffect(0.7)
                                        .controlSize(.small)
                                }
                            }
                        }
                        .toggleStyle(.switch)
                        .disabled(isLoadingRecursive)
                        .onChange(of: isRecursive) { newValue in
                            if newValue && recursiveFiles.isEmpty {
                                loadRecursiveData()
                            }
                        }
                    }
                    .padding(.horizontal)
                    .padding(.vertical, 8)
                    
                    Divider()
                    
                    // Summary Statistics
                    VStack(alignment: .leading, spacing: 15) {
                        Text(String(localized: "report.summary", defaultValue: "Summary"))
                            .font(.title2)
                            .fontWeight(.semibold)
                        
                        HStack(spacing: 20) {
                            StatCard(
                                title: String(localized: "report.totalSize", defaultValue: "Total Size"),
                                value: scanner.formatBytes(filteredTotalSize),
                                icon: "internaldrive",
                                color: .blue
                            )
                            
                            StatCard(
                                title: String(localized: "report.files", defaultValue: "Files"),
                                value: "\(fileCount)",
                                icon: "doc",
                                color: .green
                            )
                            
                            StatCard(
                                title: String(localized: "report.folders", defaultValue: "Folders"),
                                value: "\(folderCount)",
                                icon: "folder",
                                color: .orange
                            )
                        }
                    }
                    .padding(.horizontal)
                    
                    Divider()
                    
                    // File Type Distribution Chart
                    if !fileTypeBreakdown.isEmpty {
                        VStack(alignment: .leading, spacing: 15) {
                            Text(String(localized: "report.typeDistribution", defaultValue: "Storage by Type"))
                                .font(.title2)
                                .fontWeight(.semibold)
                            
                            Chart(fileTypeBreakdown, id: \.0) { item in
                                SectorMark(
                                    angle: .value("Size", item.1),
                                    innerRadius: .ratio(0.5),
                                    angularInset: 1.5
                                )
                                .foregroundStyle(by: .value("Type", item.0))
                                .cornerRadius(4)
                            }
                            .frame(height: 300)
                            .chartLegend(position: .bottom, alignment: .leading)
                            
                            // Type list with sizes
                            VStack(alignment: .leading, spacing: 8) {
                                ForEach(fileTypeBreakdown, id: \.0) { type, size in
                                    HStack {
                                        Text(type)
                                            .font(.subheadline)
                                        Spacer()
                                        Text(scanner.formatBytes(size))
                                            .font(.subheadline)
                                            .foregroundColor(.secondary)
                                            .monospacedDigit()
                                        Text("(\(Int((Double(size) / Double(filteredTotalSize)) * 100))%)")
                                            .font(.caption)
                                            .foregroundColor(.secondary)
                                    }
                                }
                            }
                            .padding()
                            .background(Color(nsColor: .controlBackgroundColor))
                            .cornerRadius(8)
                        }
                        .padding(.horizontal)
                    }
                    
                    Divider()
                    
                    // Largest Items Chart
                    if !largestItems.isEmpty {
                        VStack(alignment: .leading, spacing: 15) {
                            Text(String(localized: "report.largestItems", defaultValue: "Largest Items"))
                                .font(.title2)
                                .fontWeight(.semibold)
                            
                            Chart(largestItems) { item in
                                BarMark(
                                    x: .value("Size", item.size),
                                    y: .value("Name", item.name)
                                )
                                .foregroundStyle(item.isDirectory ? Color.orange : Color.blue)
                                .cornerRadius(4)
                            }
                            .frame(height: CGFloat(largestItems.count * 40))
                            .chartXAxis {
                                AxisMarks(position: .bottom) { value in
                                    AxisValueLabel {
                                        if let size = value.as(Int64.self) {
                                            Text(scanner.formatBytes(size))
                                                .font(.caption)
                                        }
                                    }
                                }
                            }
                            
                            // Legend
                            HStack(spacing: 20) {
                                HStack(spacing: 4) {
                                    Circle()
                                        .fill(Color.blue)
                                        .frame(width: 8, height: 8)
                                    Text(String(localized: "report.legend.files", defaultValue: "Files"))
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                                HStack(spacing: 4) {
                                    Circle()
                                        .fill(Color.orange)
                                        .frame(width: 8, height: 8)
                                    Text(String(localized: "report.legend.folders", defaultValue: "Folders"))
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                            }
                        }
                        .padding(.horizontal)
                    }
                    
                    Divider()
                    
                    // Recommendations
                    VStack(alignment: .leading, spacing: 15) {
                        Text(String(localized: "report.insights", defaultValue: "Insights"))
                            .font(.title2)
                            .fontWeight(.semibold)
                        
                        VStack(alignment: .leading, spacing: 12) {
                            if let largest = largestItems.first {
                                InsightCard(
                                    icon: "star.fill",
                                    color: .yellow,
                                    title: String(localized: "report.insight.largest", defaultValue: "Largest Item"),
                                    description: String(format: String(localized: "report.insight.largestDesc", defaultValue: "\"%@\" uses %@"), largest.name, scanner.formatBytes(largest.size))
                                )
                            }
                            
                            if fileCount > 0 {
                                let avgFileSize = filteredTotalSize / Int64(fileCount)
                                InsightCard(
                                    icon: "chart.bar.fill",
                                    color: .blue,
                                    title: String(localized: "report.insight.average", defaultValue: "Average File Size"),
                                    description: scanner.formatBytes(avgFileSize)
                                )
                            }
                            
                            if !fileTypeBreakdown.isEmpty, let topType = fileTypeBreakdown.first {
                                let percentage = Int((Double(topType.1) / Double(filteredTotalSize)) * 100)
                                InsightCard(
                                    icon: "chart.pie.fill",
                                    color: .purple,
                                    title: String(localized: "report.insight.topType", defaultValue: "Most Common Type"),
                                    description: String(format: String(localized: "report.insight.topTypeDesc", defaultValue: "%@ files use %d%% of space"), topType.0, percentage)
                                )
                            }
                        }
                    }
                    .padding(.horizontal)
                    
                    Spacer(minLength: 30)
                }
                .padding(.vertical)
            }
            .navigationTitle(String(localized: "report.title", defaultValue: "Storage Report"))
            .toolbar {
                ToolbarItem(placement: .automatic) {
                    Button(action: { dismiss() }) {
                        Label(String(localized: "report.done", defaultValue: "Done"), systemImage: "xmark.circle.fill")
                    }
                }
            }
        }
    }
    
    private func loadRecursiveData() {
        isLoadingRecursive = true
        let url = URL(fileURLWithPath: folderPath)
        
        scanner.scanDirectoryRecursively(at: url) { items in
            recursiveFiles = items
            isLoadingRecursive = false
        }
    }
}

private struct StatCard: View {
    let title: String
    let value: String
    let icon: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(color)
            Text(value)
                .font(.title3)
                .fontWeight(.bold)
                .monospacedDigit()
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(Color(nsColor: .controlBackgroundColor))
        .cornerRadius(12)
    }
}

private struct InsightCard: View {
    let icon: String
    let color: Color
    let title: String
    let description: String
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundColor(color)
                .frame(width: 30)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.headline)
                Text(description)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color(nsColor: .controlBackgroundColor))
        .cornerRadius(8)
    }
}

#Preview {
    ReportView(
        files: [
            FileItem(name: "Documents", size: 5_000_000_000, path: "/test/Documents", isDirectory: true),
            FileItem(name: "Video.mp4", size: 2_000_000_000, path: "/test/Video.mp4", isDirectory: false),
            FileItem(name: "Photos", size: 1_500_000_000, path: "/test/Photos", isDirectory: true),
            FileItem(name: "Archive.zip", size: 1_000_000_000, path: "/test/Archive.zip", isDirectory: false)
        ],
        totalSize: 9_500_000_000,
        folderPath: "/Users/test/Documents",
        scanner: FileScanner()
    )
}

