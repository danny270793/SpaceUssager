//
//  ContentView.swift
//  SpaceUssager
//
//  Created by dvaca on 6/11/25.
//

import SwiftUI
import UniformTypeIdentifiers

struct FileItem: Identifiable {
    let id = UUID()
    let name: String
    let size: Int64
    let path: String
    let isDirectory: Bool
}

class FileScanner: ObservableObject {
    @Published var files: [FileItem] = []
    @Published var totalSize: Int64 = 0
    @Published var isScanning = false
    @Published var selectedPath: String = ""
    
    func scanDirectory(at url: URL) {
        isScanning = true
        selectedPath = url.path
        files = []
        totalSize = 0
        
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            var scannedFiles: [FileItem] = []
            var total: Int64 = 0
            
            let fileManager = FileManager.default
            
            guard let enumerator = fileManager.enumerator(
                at: url,
                includingPropertiesForKeys: [.isDirectoryKey, .fileSizeKey, .nameKey],
                options: [.skipsHiddenFiles]
            ) else {
                DispatchQueue.main.async {
                    self?.isScanning = false
                }
                return
            }
            
            for case let fileURL as URL in enumerator {
                do {
                    let resourceValues = try fileURL.resourceValues(forKeys: [.isDirectoryKey, .fileSizeKey, .nameKey])
                    let isDirectory = resourceValues.isDirectory ?? false
                    let fileSize = Int64(resourceValues.fileSize ?? 0)
                    let fileName = resourceValues.name ?? fileURL.lastPathComponent
                    
                    let fileItem = FileItem(
                        name: fileName,
                        size: fileSize,
                        path: fileURL.path,
                        isDirectory: isDirectory
                    )
                    
                    scannedFiles.append(fileItem)
                    if !isDirectory {
                        total += fileSize
                    }
                } catch {
                    print("Error reading file: \(error)")
                }
            }
            
            // Sort by size descending
            scannedFiles.sort { $0.size > $1.size }
            
            DispatchQueue.main.async {
                self?.files = scannedFiles
                self?.totalSize = total
                self?.isScanning = false
            }
        }
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
            if scanner.isScanning {
                Spacer()
                VStack {
                    ProgressView()
                        .scaleEffect(1.5)
                    Text("Scanning files...")
                        .padding(.top)
                }
                Spacer()
            } else if scanner.files.isEmpty {
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
                List(scanner.files) { file in
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
                    }
                    .padding(.vertical, 2)
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
                
                Text("(\(scanner.files.count) items)")
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
