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
    @State private var searchText = ""
    @AppStorage("hasSeenWelcome") private var hasSeenWelcome = false
    private let logger = AppLogger.shared
    
    var filteredFiles: [FileItem] {
        if searchText.isEmpty {
            return scanner.files
        } else {
            return scanner.files.filter { $0.name.localizedCaseInsensitiveContains(searchText) }
        }
    }
    
    var canGoBack: Bool {
        guard !scanner.selectedPath.isEmpty else { return false }
        let currentURL = URL(fileURLWithPath: scanner.selectedPath)
        let parentURL = currentURL.deletingLastPathComponent()
        return parentURL.path != currentURL.path && !parentURL.path.isEmpty
    }
    
    var fileCount: Int {
        filteredFiles.filter { !$0.isDirectory }.count
    }
    
    var folderCount: Int {
        filteredFiles.filter { $0.isDirectory }.count
    }
    
    var totalFilteredSize: Int64 {
        filteredFiles.reduce(0) { $0 + $1.size }
    }
    
    func goToParentDirectory() {
        logger.navigation(String(localized: "log.nav.parentRequested", defaultValue: "Go to parent requested"))
        
        guard !scanner.selectedPath.isEmpty else {
            logger.warning(String(localized: "log.nav.noPath", defaultValue: "No current path, cannot go to parent"), category: .navigation)
            return
        }
        
        let currentURL = URL(fileURLWithPath: scanner.selectedPath)
        let parentURL = currentURL.deletingLastPathComponent()
        
        logger.info(String(format: String(localized: "log.nav.current", defaultValue: "Current: %@"), currentURL.path), category: .navigation)
        logger.info(String(format: String(localized: "log.nav.parent", defaultValue: "Parent: %@"), parentURL.path), category: .navigation)
        
        // Only navigate if the parent is different and not empty
        if parentURL.path != currentURL.path && !parentURL.path.isEmpty {
            logger.success(String(localized: "log.nav.navigating", defaultValue: "Navigating to parent"), category: .navigation)
            scanner.scanDirectory(at: parentURL)
        } else {
            logger.warning(String(localized: "log.nav.cannotNavigate", defaultValue: "Cannot navigate to parent (at root or invalid)"), category: .navigation)
        }
    }
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Path breadcrumb
                if !scanner.selectedPath.isEmpty {
                    HStack(spacing: 4) {
                        Image(systemName: "folder")
                            .foregroundColor(.secondary)
                            .font(.caption)
                        
                        Text(scanner.selectedPath)
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .lineLimit(1)
                            .truncationMode(.middle)
                        
                        Spacer()
                        
                        if scanner.isScanning {
                            HStack(spacing: 6) {
                                ProgressView()
                                    .scaleEffect(0.7)
                                    .controlSize(.small)
                                Text(String(localized: "scanning.text", defaultValue: "Scanning..."))
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                        }
                    }
                    .padding(.horizontal)
                    .padding(.vertical, 8)
                    .background(Color(nsColor: .controlBackgroundColor))
                }
            
            // File List or Welcome Screen
            if scanner.selectedPath.isEmpty && !scanner.isScanning && !hasSeenWelcome {
                WelcomeView(onSelectFolder: {
                    logger.ui(String(localized: "log.ui.selectFolderClicked", defaultValue: "Select Folder button clicked"))
                    hasSeenWelcome = true
                    showingFolderPicker = true
                })
            } else if scanner.selectedPath.isEmpty && !scanner.isScanning {
                ContentUnavailableView {
                    Label(String(localized: "empty.noFolder", defaultValue: "No folder selected"), systemImage: "folder.badge.questionmark")
                } description: {
                    Text(String(localized: "empty.instruction", defaultValue: "Click 'Select Folder' to analyze disk usage"))
                }
            } else {
                ScrollViewReader { proxy in
                    List {
                        // Invisible anchor for scrolling to top
                        Color.clear
                            .frame(height: 0)
                            .id("top")
                    
                    // Add ".." item to go to parent directory
                    if canGoBack {
                        HStack(spacing: 8) {
                            Image(systemName: "arrow.up.backward")
                                .foregroundColor(scanner.isScanning ? .secondary : .accentColor)
                                .font(.body)
                                .frame(width: 20)
                            
                            Text(String(localized: "nav.parent", defaultValue: ".."))
                                .font(.system(.body, design: .default))
                                .fontWeight(.medium)
                            
                            Spacer()
                            
                            Text(String(localized: "button.parentFolder", defaultValue: "Parent Folder"))
                                .foregroundColor(.secondary)
                                .font(.caption)
                        }
                        .padding(.vertical, 4)
                        .contentShape(Rectangle())
                        .disabled(scanner.isScanning)
                        .onTapGesture {
                            if !scanner.isScanning {
                                logger.ui(String(localized: "log.ui.parentClicked", defaultValue: "'..' item clicked"))
                                goToParentDirectory()
                            } else {
                                logger.warning(String(localized: "log.ui.parentBlocked", defaultValue: "'..' blocked - scan in progress"), category: .ui)
                            }
                        }
                    }
                    
                    // Regular files and folders
                    ForEach(filteredFiles) { file in
                        HStack(spacing: 8) {
                            Image(systemName: file.isDirectory ? "folder.fill" : "doc.fill")
                                .foregroundColor(file.isDirectory ? (scanner.isScanning ? .secondary : .accentColor) : Color(nsColor: .secondaryLabelColor))
                                .font(.body)
                                .frame(width: 20)
                            
                            VStack(alignment: .leading, spacing: 2) {
                                Text(file.name)
                                    .font(.system(.body))
                                    .lineLimit(1)
                                
                                if file.isDirectory {
                                    Text("\(scanner.formatBytes(file.size))")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                            }
                            
                            Spacer()
                            
                            if !file.isDirectory {
                                Text(scanner.formatBytes(file.size))
                                    .foregroundColor(.secondary)
                                    .font(.system(.callout, design: .monospaced))
                            }
                            
                            if file.isDirectory {
                                Image(systemName: "chevron.right")
                                    .foregroundColor(.secondary)
                                    .font(.caption2)
                                    .fontWeight(.semibold)
                            }
                        }
                        .padding(.vertical, 4)
                        .contentShape(Rectangle())
                        .disabled(file.isDirectory && scanner.isScanning)
                        .onTapGesture {
                            if file.isDirectory {
                                if !scanner.isScanning {
                                    logger.ui(String(format: String(localized: "log.ui.folderClicked", defaultValue: "Folder clicked: %@"), file.name))
                                    let url = URL(fileURLWithPath: file.path)
                                    scanner.scanDirectory(at: url)
                                } else {
                                    logger.warning(String(localized: "log.ui.folderBlocked", defaultValue: "Folder click blocked - scan in progress"), category: .ui)
                                }
                            } else {
                                logger.ui(String(format: String(localized: "log.ui.fileClicked", defaultValue: "File clicked (no action): %@"), file.name))
                            }
                        }
                        .contextMenu {
                            Button(role: .destructive) {
                                logger.ui(String(format: String(localized: "log.ui.deleteClicked", defaultValue: "Delete requested for: %@"), file.name))
                                scanner.deleteItem(at: file.path)
                            } label: {
                                Label(String(localized: "contextMenu.delete", defaultValue: "Delete"), systemImage: "trash")
                            }
                        }
                    }
                    }
                    .listStyle(.plain)
                    .onChange(of: scanner.selectedPath) { newPath in
                        // Scroll to top when a new scan starts
                        if scanner.isScanning {
                            logger.ui(String(format: String(localized: "log.ui.scrolling", defaultValue: "Scrolling to top for: %@"), newPath))
                            withAnimation {
                                proxy.scrollTo("top", anchor: .top)
                            }
                        }
                    }
                }
            }
            
            // Bottom Bar
            if !scanner.files.isEmpty || scanner.isScanning {
                Divider()
                
                HStack(spacing: 12) {
                    Image(systemName: "info.circle")
                        .foregroundColor(.secondary)
                    
                    VStack(alignment: .leading, spacing: 2) {
                        Text(scanner.formatBytes(searchText.isEmpty ? scanner.totalSize : totalFilteredSize))
                            .font(.system(.body, design: .monospaced))
                            .fontWeight(.medium)
                        
                        HStack(spacing: 4) {
                            Text(String(format: String(localized: "bottom.stats", defaultValue: "(%d files, %d folders)"), fileCount, folderCount))
                            
                            if !searchText.isEmpty {
                                Text("•")
                                Text("\(filteredFiles.count) of \(scanner.files.count)")
                            }
                        }
                        .font(.caption)
                        .foregroundColor(.secondary)
                    }
                    
                    Spacer()
                }
                .padding()
                .background(Color(nsColor: .controlBackgroundColor))
            }
        }
        .navigationTitle(String(localized: "app.title", defaultValue: "Space Ussager"))
        .searchable(
            text: $searchText,
            placement: .toolbar,
            prompt: Text(String(localized: "search.prompt", defaultValue: "Search files and folders"))
        )
        .toolbar {
            ToolbarItem(placement: .automatic) {
                Button(action: {
                    if !scanner.isScanning {
                        logger.ui(String(localized: "log.ui.selectFolderClicked", defaultValue: "Select Folder button clicked"))
                        showingFolderPicker = true
                    } else {
                        logger.warning(String(localized: "log.ui.selectFolderBlocked", defaultValue: "Select Folder blocked - scan in progress"), category: .ui)
                    }
                }) {
                    Label(String(localized: "button.selectFolder", defaultValue: "Select Folder"), systemImage: "folder")
                }
                .disabled(scanner.isScanning)
                .help(String(localized: "button.selectFolder", defaultValue: "Select Folder"))
            }
        }
        }
        .frame(minWidth: 700, idealWidth: 900, minHeight: 500, idealHeight: 700)
        .fileImporter(
            isPresented: $showingFolderPicker,
            allowedContentTypes: [.folder],
            allowsMultipleSelection: false
        ) { result in
            logger.picker(String(localized: "log.picker.callback", defaultValue: "File picker callback triggered"))
            
            switch result {
            case .success(let urls):
                if let url = urls.first {
                    logger.success(String(format: String(localized: "log.picker.selected", defaultValue: "Folder selected: %@"), url.path), category: .picker)
                    
                    // Start accessing the security-scoped resource
                    let hasAccess = url.startAccessingSecurityScopedResource()
                    let accessStatus = hasAccess ? String(localized: "log.picker.access.granted", defaultValue: "granted") : String(localized: "log.picker.access.notNeeded", defaultValue: "not needed")
                    logger.info(String(format: String(localized: "log.picker.access", defaultValue: "Security-scoped access: %@"), accessStatus), category: .picker)
                    
                    if hasAccess {
                        scanner.scanDirectory(at: url)
                        // Note: In a production app, you should stop accessing when done
                        // url.stopAccessingSecurityScopedResource()
                    } else {
                        // Try scanning anyway for non-sandboxed paths
                        logger.warning(String(localized: "log.picker.noAccess", defaultValue: "Attempting scan without security scope"), category: .picker)
                        scanner.scanDirectory(at: url)
                    }
                } else {
                    logger.warning(String(localized: "log.picker.noUrl", defaultValue: "No folder URL returned"), category: .picker)
                }
            case .failure(let error):
                logger.error(String(format: String(localized: "log.picker.error", defaultValue: "Error selecting folder: %@"), error.localizedDescription), category: .picker)
            }
        }
    }
}

#Preview("Empty State") {
    ContentView()
}
