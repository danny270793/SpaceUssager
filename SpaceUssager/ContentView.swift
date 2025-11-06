//
//  ContentView.swift
//  SpaceUssager
//
//  Created by dvaca on 6/11/25.
//

import SwiftUI
import UniformTypeIdentifiers

struct FileItem: Identifiable, Equatable {
    let name: String
    let size: Int64
    let path: String
    let isDirectory: Bool
    
    var id: String { path }
    
    static func == (lhs: FileItem, rhs: FileItem) -> Bool {
        lhs.path == rhs.path && lhs.size == rhs.size
    }
}

class FileScanner: ObservableObject {
    @Published var files: [FileItem] = []
    @Published var totalSize: Int64 = 0
    @Published var isScanning = false
    @Published var selectedPath: String = ""
    
    private var shouldCancelScan = false
    
    func cancelCurrentScan() {
        shouldCancelScan = true
    }
    
    func scanDirectory(at url: URL) {
        // Cancel any ongoing scan
        cancelCurrentScan()
        
        // Wait a brief moment for the old scan to recognize the cancel
        Thread.sleep(forTimeInterval: 0.05)
        
        shouldCancelScan = false
        isScanning = true
        selectedPath = url.path
        files = []
        totalSize = 0
        
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            var scannedFiles: [FileItem] = []
            var total: Int64 = 0
            
            let fileManager = FileManager.default
            
            // Get only first level of contents
            guard let contents = try? fileManager.contentsOfDirectory(
                at: url,
                includingPropertiesForKeys: [.isDirectoryKey, .fileSizeKey, .nameKey],
                options: [.skipsHiddenFiles]
            ) else {
                DispatchQueue.main.async {
                    self?.isScanning = false
                }
                return
            }
            
            for itemURL in contents {
                // Check if scan was cancelled
                if self?.shouldCancelScan == true {
                    DispatchQueue.main.async {
                        self?.isScanning = false
                    }
                    return
                }
                
                do {
                    let resourceValues = try itemURL.resourceValues(forKeys: [.isDirectoryKey, .nameKey])
                    let isDirectory = resourceValues.isDirectory ?? false
                    let fileName = resourceValues.name ?? itemURL.lastPathComponent
                    
                    // For files, get size immediately and update UI
                    if !isDirectory {
                        let itemSize = self?.getFileSize(url: itemURL) ?? 0
                        
                        let fileItem = FileItem(
                            name: fileName,
                            size: itemSize,
                            path: itemURL.path,
                            isDirectory: isDirectory
                        )
                        
                        scannedFiles.append(fileItem)
                        total += itemSize
                        
                        // Update UI with current progress
                        DispatchQueue.main.async {
                            self?.files = scannedFiles.sorted { $0.size > $1.size }
                            self?.totalSize = total
                        }
                    } else {
                        // For directories, add with size 0 first, then calculate
                        let fileItem = FileItem(
                            name: fileName,
                            size: 0,
                            path: itemURL.path,
                            isDirectory: isDirectory
                        )
                        
                        scannedFiles.append(fileItem)
                        
                        // Update UI to show the folder
                        DispatchQueue.main.async {
                            self?.files = scannedFiles.sorted { $0.size > $1.size }
                        }
                        
                        // Check if scan was cancelled before calculating directory size
                        if self?.shouldCancelScan == true {
                            DispatchQueue.main.async {
                                self?.isScanning = false
                            }
                            return
                        }
                        
                        // Calculate directory size
                        let itemSize = self?.calculateDirectorySize(url: itemURL) ?? 0
                        
                        // Check again after potentially long calculation
                        if self?.shouldCancelScan == true {
                            DispatchQueue.main.async {
                                self?.isScanning = false
                            }
                            return
                        }
                        
                        // Update the item with the calculated size
                        if let index = scannedFiles.firstIndex(where: { $0.path == itemURL.path }) {
                            scannedFiles[index] = FileItem(
                                name: fileName,
                                size: itemSize,
                                path: itemURL.path,
                                isDirectory: isDirectory
                            )
                        }
                        
                        total += itemSize
                        
                        // Update UI with new size
                        DispatchQueue.main.async {
                            self?.files = scannedFiles.sorted { $0.size > $1.size }
                            self?.totalSize = total
                        }
                    }
                } catch {
                    print("Error reading item: \(error)")
                }
            }
            
            // Final update
            DispatchQueue.main.async {
                self?.files = scannedFiles.sorted { $0.size > $1.size }
                self?.totalSize = total
                self?.isScanning = false
            }
        }
    }
    
    private func getFileSize(url: URL) -> Int64 {
        do {
            let resourceValues = try url.resourceValues(forKeys: [.fileSizeKey])
            return Int64(resourceValues.fileSize ?? 0)
        } catch {
            return 0
        }
    }
    
    private func calculateDirectorySize(url: URL) -> Int64 {
        var totalSize: Int64 = 0
        let fileManager = FileManager.default
        
        guard let enumerator = fileManager.enumerator(
            at: url,
            includingPropertiesForKeys: [.isDirectoryKey, .fileSizeKey],
            options: [.skipsHiddenFiles]
        ) else {
            return 0
        }
        
        for case let fileURL as URL in enumerator {
            // Check if scan was cancelled
            if shouldCancelScan {
                return totalSize
            }
            
            do {
                let resourceValues = try fileURL.resourceValues(forKeys: [.isDirectoryKey, .fileSizeKey])
                let isDirectory = resourceValues.isDirectory ?? false
                
                // Only count files, not directories themselves
                if !isDirectory {
                    let fileSize = Int64(resourceValues.fileSize ?? 0)
                    totalSize += fileSize
                }
            } catch {
                // Skip files we can't read
                continue
            }
        }
        
        return totalSize
    }
    
    func formatBytes(_ bytes: Int64) -> String {
        let formatter = ByteCountFormatter()
        formatter.allowedUnits = [.useAll]
        formatter.countStyle = .file
        formatter.includesUnit = true
        formatter.isAdaptive = true
        return formatter.string(fromByteCount: bytes)
    }
}

struct ContentView: View {
    @StateObject private var scanner = FileScanner()
    @State private var showingFolderPicker = false
    
    var canGoBack: Bool {
        guard !scanner.selectedPath.isEmpty else { return false }
        let currentURL = URL(fileURLWithPath: scanner.selectedPath)
        let parentURL = currentURL.deletingLastPathComponent()
        return parentURL.path != currentURL.path
    }
    
    var fileCount: Int {
        scanner.files.filter { !$0.isDirectory }.count
    }
    
    var folderCount: Int {
        scanner.files.filter { $0.isDirectory }.count
    }
    
    func goToParentDirectory() {
        let currentURL = URL(fileURLWithPath: scanner.selectedPath)
        let parentURL = currentURL.deletingLastPathComponent()
        if parentURL.path != currentURL.path {
            scanner.scanDirectory(at: parentURL)
        }
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Text("Space Ussager")
                    .font(.title)
                    .bold()
                
                Spacer()
                
                Button(action: {
                    showingFolderPicker = true
                }) {
                    Label("Select Folder", systemImage: "folder")
                }
                .buttonStyle(.borderedProminent)
            }
            .padding()
            
            if !scanner.selectedPath.isEmpty {
                HStack {
                    Text("Scanning: \(scanner.selectedPath)")
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
                    Text("No folder selected")
                        .font(.title2)
                    Text("Click 'Select Folder' to analyze disk usage")
                        .foregroundColor(.secondary)
                }
                Spacer()
            } else {
                List {
                    // Loading indicator at the top while scanning
                    if scanner.isScanning {
                        HStack {
                            ProgressView()
                                .scaleEffect(0.8)
                            Text("Scanning...")
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
                                .foregroundColor(.blue)
                                .frame(width: 20)
                            
                            Text("..")
                                .lineLimit(1)
                            
                            Spacer()
                            
                            Text("Parent Folder")
                                .foregroundColor(.secondary)
                                .font(.caption)
                        }
                        .padding(.vertical, 2)
                        .contentShape(Rectangle())
                        .onTapGesture {
                            goToParentDirectory()
                        }
                    }
                    
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
                        .contentShape(Rectangle())
                        .onTapGesture {
                            if file.isDirectory {
                                let url = URL(fileURLWithPath: file.path)
                                scanner.scanDirectory(at: url)
                            }
                        }
                    }
                }
                .listStyle(.plain)
            }
            
            Divider()
            
            // Bottom Bar
            HStack {
                Label("Total Size:", systemImage: "info.circle")
                    .font(.headline)
                
                Spacer()
                
                Text(scanner.formatBytes(scanner.totalSize))
                    .font(.system(.title3, design: .monospaced))
                    .bold()
                
                Text("(\(fileCount) files, \(folderCount) folders)")
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
            switch result {
            case .success(let urls):
                if let url = urls.first {
                    // Start accessing the security-scoped resource
                    if url.startAccessingSecurityScopedResource() {
                        scanner.scanDirectory(at: url)
                        // Note: In a production app, you should stop accessing when done
                        // url.stopAccessingSecurityScopedResource()
                    }
                }
            case .failure(let error):
                print("Error selecting folder: \(error)")
            }
        }
    }
}

#Preview {
    ContentView()
}
