//
//  ContentView.swift
//  SpaceUssager
//
//  Created by dvaca on 6/11/25.
//

import SwiftUI
import UniformTypeIdentifiers

struct ContentView: View {
    @StateObject private var scanner = FileScanner()
    @State private var showingFolderPicker = false
    
    var canGoBack: Bool {
        guard !scanner.selectedPath.isEmpty else { return false }
        let currentURL = URL(fileURLWithPath: scanner.selectedPath)
        let parentURL = currentURL.deletingLastPathComponent()
        return parentURL.path != currentURL.path && !parentURL.path.isEmpty
    }
    
    var fileCount: Int {
        scanner.files.filter { !$0.isDirectory }.count
    }
    
    var folderCount: Int {
        scanner.files.filter { $0.isDirectory }.count
    }
    
    func goToParentDirectory() {
        print("⬆️ [NAV] \(String(localized: "log.nav.parentRequested", defaultValue: "Go to parent requested"))")
        
        guard !scanner.selectedPath.isEmpty else {
            print("⚠️ [NAV] \(String(localized: "log.nav.noPath", defaultValue: "No current path, cannot go to parent"))")
            return
        }
        
        let currentURL = URL(fileURLWithPath: scanner.selectedPath)
        let parentURL = currentURL.deletingLastPathComponent()
        
        print("   \(String(format: String(localized: "log.nav.current", defaultValue: "Current: %@"), currentURL.path))")
        print("   \(String(format: String(localized: "log.nav.parent", defaultValue: "Parent: %@"), parentURL.path))")
        
        // Only navigate if the parent is different and not empty
        if parentURL.path != currentURL.path && !parentURL.path.isEmpty {
            print("✅ [NAV] \(String(localized: "log.nav.navigating", defaultValue: "Navigating to parent"))")
            scanner.scanDirectory(at: parentURL)
        } else {
            print("⚠️ [NAV] \(String(localized: "log.nav.cannotNavigate", defaultValue: "Cannot navigate to parent (at root or invalid)"))")
        }
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Text(String(localized: "app.title", defaultValue: "Space Ussager"))
                    .font(.title)
                    .bold()
                
                Spacer()
                
                Button(action: {
                    if !scanner.isScanning {
                        print("📁 [UI] \(String(localized: "log.ui.selectFolderClicked", defaultValue: "Select Folder button clicked"))")
                        showingFolderPicker = true
                    } else {
                        print("⚠️ [UI] \(String(localized: "log.ui.selectFolderBlocked", defaultValue: "Select Folder blocked - scan in progress"))")
                    }
                }) {
                    Label(String(localized: "button.selectFolder", defaultValue: "Select Folder"), systemImage: "folder")
                }
                .buttonStyle(.borderedProminent)
                .disabled(scanner.isScanning)
            }
            .padding()
            
            if !scanner.selectedPath.isEmpty {
                HStack {
                    Text(String(format: String(localized: "scanning.path", defaultValue: "Scanning: %@"), scanner.selectedPath))
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Spacer()
                }
                .padding(.horizontal)
                .padding(.bottom, 8)
            }
            
            Divider()
            
            // File List
            if scanner.files.isEmpty && !scanner.isScanning {
                Spacer()
                VStack(spacing: 16) {
                    Image(systemName: "folder.badge.questionmark")
                        .font(.system(size: 60))
                        .foregroundColor(.secondary)
                    Text(String(localized: "empty.noFolder", defaultValue: "No folder selected"))
                        .font(.title2)
                    Text(String(localized: "empty.instruction", defaultValue: "Click 'Select Folder' to analyze disk usage"))
                        .foregroundColor(.secondary)
                }
                Spacer()
            } else {
                ScrollViewReader { proxy in
                    List {
                        // Invisible anchor for scrolling to top
                        Color.clear
                            .frame(height: 0)
                            .id("top")
                        
                        // Loading indicator at the top while scanning
                        if scanner.isScanning {
                            HStack {
                                ProgressView()
                                    .scaleEffect(0.8)
                                Text(String(localized: "scanning.text", defaultValue: "Scanning..."))
                                    .foregroundColor(.secondary)
                                    .font(.caption)
                                Spacer()
                            }
                            .padding(.vertical, 4)
                        }
                    
                    // Add ".." item to go to parent directory
                    if canGoBack {
                        HStack {
                            Image(systemName: "arrow.up.backward")
                                .foregroundColor(scanner.isScanning ? .gray : .blue)
                                .frame(width: 20)
                            
                            Text(String(localized: "nav.parent", defaultValue: ".."))
                                .lineLimit(1)
                                .opacity(scanner.isScanning ? 0.5 : 1.0)
                            
                            Spacer()
                            
                            Text(String(localized: "button.parentFolder", defaultValue: "Parent Folder"))
                                .foregroundColor(.secondary)
                                .font(.caption)
                        }
                        .padding(.vertical, 2)
                        .contentShape(Rectangle())
                        .onTapGesture {
                            if !scanner.isScanning {
                                print("⬆️ [UI] \(String(localized: "log.ui.parentClicked", defaultValue: "'..' item clicked"))")
                                goToParentDirectory()
                            } else {
                                print("⚠️ [UI] \(String(localized: "log.ui.parentBlocked", defaultValue: "'..' blocked - scan in progress"))")
                            }
                        }
                    }
                    
                    // Regular files and folders
                    ForEach(scanner.files) { file in
                        HStack {
                            Image(systemName: file.isDirectory ? "folder.fill" : "doc.fill")
                                .foregroundColor(file.isDirectory ? (scanner.isScanning ? .gray : .blue) : .gray)
                                .frame(width: 20)
                            
                            Text(file.name)
                                .lineLimit(1)
                            
                            Spacer()
                            
                            Text(scanner.formatBytes(file.size))
                                .foregroundColor(.secondary)
                                .font(.system(.body, design: .monospaced))
                            
                            if file.isDirectory {
                                Image(systemName: "chevron.right")
                                    .foregroundColor(.secondary)
                                    .font(.caption)
                                    .opacity(scanner.isScanning ? 0.5 : 1.0)
                            }
                        }
                        .padding(.vertical, 2)
                        .opacity(file.isDirectory && scanner.isScanning ? 0.5 : 1.0)
                        .contentShape(Rectangle())
                        .onTapGesture {
                            if file.isDirectory {
                                if !scanner.isScanning {
                                    print("📂 [UI] \(String(format: String(localized: "log.ui.folderClicked", defaultValue: "Folder clicked: %@"), file.name))")
                                    let url = URL(fileURLWithPath: file.path)
                                    scanner.scanDirectory(at: url)
                                } else {
                                    print("⚠️ [UI] \(String(localized: "log.ui.folderBlocked", defaultValue: "Folder click blocked - scan in progress"))")
                                }
                            } else {
                                print("📄 [UI] \(String(format: String(localized: "log.ui.fileClicked", defaultValue: "File clicked (no action): %@"), file.name))")
                            }
                        }
                    }
                    }
                    .listStyle(.plain)
                    .onChange(of: scanner.selectedPath) { newPath in
                        // Scroll to top when a new scan starts
                        if scanner.isScanning {
                            print("📜 [UI] \(String(format: String(localized: "log.ui.scrolling", defaultValue: "Scrolling to top for: %@"), newPath))")
                            withAnimation {
                                proxy.scrollTo("top", anchor: .top)
                            }
                        }
                    }
                }
            }
            
            Divider()
            
            // Bottom Bar
            HStack {
                Label(String(localized: "bottom.totalSize", defaultValue: "Total Size:"), systemImage: "info.circle")
                    .font(.headline)
                
                Spacer()
                
                Text(scanner.formatBytes(scanner.totalSize))
                    .font(.system(.title3, design: .monospaced))
                    .bold()
                
                Text(String(format: String(localized: "bottom.stats", defaultValue: "(%d files, %d folders)"), fileCount, folderCount))
                    .foregroundColor(.secondary)
            }
            .padding()
            //.background(Color(nsColor: .controlBackgroundColor))
        }
        .frame(minWidth: 600, minHeight: 400)
        .fileImporter(
            isPresented: $showingFolderPicker,
            allowedContentTypes: [.folder],
            allowsMultipleSelection: false
        ) { result in
            print("📂 [PICKER] \(String(localized: "log.picker.callback", defaultValue: "File picker callback triggered"))")
            
            switch result {
            case .success(let urls):
                if let url = urls.first {
                    print("✅ [PICKER] \(String(format: String(localized: "log.picker.selected", defaultValue: "Folder selected: %@"), url.path))")
                    
                    // Start accessing the security-scoped resource
                    let hasAccess = url.startAccessingSecurityScopedResource()
                    let accessStatus = hasAccess ? String(localized: "log.picker.access.granted", defaultValue: "granted") : String(localized: "log.picker.access.notNeeded", defaultValue: "not needed")
                    print("🔐 [PICKER] \(String(format: String(localized: "log.picker.access", defaultValue: "Security-scoped access: %@"), accessStatus))")
                    
                    if hasAccess {
                        scanner.scanDirectory(at: url)
                        // Note: In a production app, you should stop accessing when done
                        // url.stopAccessingSecurityScopedResource()
                    } else {
                        // Try scanning anyway for non-sandboxed paths
                        print("⚠️ [PICKER] \(String(localized: "log.picker.noAccess", defaultValue: "Attempting scan without security scope"))")
                        scanner.scanDirectory(at: url)
                    }
                } else {
                    print("⚠️ [PICKER] \(String(localized: "log.picker.noUrl", defaultValue: "No folder URL returned"))")
                }
            case .failure(let error):
                print("❌ [PICKER] \(String(format: String(localized: "log.picker.error", defaultValue: "Error selecting folder: %@"), error.localizedDescription))")
            }
        }
    }
}

#Preview("Empty State") {
    ContentView()
}

#Preview("With Mock Data") {
    ContentViewWithMockData()
}

// Mock preview with sample data
private struct ContentViewWithMockData: View {
    @StateObject private var scanner: FileScanner = {
        let scanner = FileScanner()
        // Simulate scanned data
        scanner.selectedPath = "/Users/demo/Documents"
        scanner.files = [
            FileItem(name: "Projects", size: 15_680_000_000, path: "/Users/demo/Documents/Projects", isDirectory: true),
            FileItem(name: "Videos", size: 8_450_000_000, path: "/Users/demo/Documents/Videos", isDirectory: true),
            FileItem(name: "Photos", size: 5_230_000_000, path: "/Users/demo/Documents/Photos", isDirectory: true),
            FileItem(name: "presentation.key", size: 2_450_000_000, path: "/Users/demo/Documents/presentation.key", isDirectory: false),
            FileItem(name: "Music", size: 1_850_000_000, path: "/Users/demo/Documents/Music", isDirectory: true),
            FileItem(name: "Archive.zip", size: 980_000_000, path: "/Users/demo/Documents/Archive.zip", isDirectory: false),
            FileItem(name: "Downloads", size: 650_000_000, path: "/Users/demo/Documents/Downloads", isDirectory: true),
            FileItem(name: "document.pdf", size: 45_000_000, path: "/Users/demo/Documents/document.pdf", isDirectory: false),
            FileItem(name: "notes.txt", size: 15_000, path: "/Users/demo/Documents/notes.txt", isDirectory: false)
        ]
        scanner.totalSize = scanner.files.reduce(0) { $0 + $1.size }
        scanner.isScanning = false
        return scanner
    }()
    @State private var showingFolderPicker = false
    
    var canGoBack: Bool {
        guard !scanner.selectedPath.isEmpty else { return false }
        let currentURL = URL(fileURLWithPath: scanner.selectedPath)
        let parentURL = currentURL.deletingLastPathComponent()
        return parentURL.path != currentURL.path && !parentURL.path.isEmpty
    }
    
    var fileCount: Int {
        scanner.files.filter { !$0.isDirectory }.count
    }
    
    var folderCount: Int {
        scanner.files.filter { $0.isDirectory }.count
    }
    
    func goToParentDirectory() {
        // Mock implementation for preview
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Text(String(localized: "app.title", defaultValue: "Space Ussager"))
                    .font(.title)
                    .bold()
                
                Spacer()
                
                Button(action: {}) {
                    Label(String(localized: "button.selectFolder", defaultValue: "Select Folder"), systemImage: "folder")
                }
                .buttonStyle(.borderedProminent)
            }
            .padding()
            
            if !scanner.selectedPath.isEmpty {
                HStack {
                    Text(String(format: String(localized: "scanning.path", defaultValue: "Scanning: %@"), scanner.selectedPath))
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Spacer()
                }
                .padding(.horizontal)
                .padding(.bottom, 8)
            }
            
            Divider()
            
            // File List
            List {
                // Regular files and folders
                ForEach(scanner.files) { file in
                    HStack {
                        Image(systemName: file.isDirectory ? "folder.fill" : "doc.fill")
                            .foregroundColor(file.isDirectory ? .blue : .gray)
                            .frame(width: 20)
                        
                        Text(file.name)
                            .lineLimit(1)
                        
                        Spacer()
                        
                        Text(scanner.formatBytes(file.size))
                            .foregroundColor(.secondary)
                            .font(.system(.body, design: .monospaced))
                        
                        if file.isDirectory {
                            Image(systemName: "chevron.right")
                                .foregroundColor(.secondary)
                                .font(.caption)
                        }
                    }
                    .padding(.vertical, 2)
                }
            }
            .listStyle(.plain)
            
            Divider()
            
            // Bottom Bar
            HStack {
                Label(String(localized: "bottom.totalSize", defaultValue: "Total Size:"), systemImage: "info.circle")
                    .font(.headline)
                
                Spacer()
                
                Text(scanner.formatBytes(scanner.totalSize))
                    .font(.system(.title3, design: .monospaced))
                    .bold()
                
                Text(String(format: String(localized: "bottom.stats", defaultValue: "(%d files, %d folders)"), fileCount, folderCount))
                    .foregroundColor(.secondary)
            }
            .padding()
        }
        .frame(minWidth: 600, minHeight: 400)
    }
}
