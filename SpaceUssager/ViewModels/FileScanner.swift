//
//  FileScanner.swift
//  SpaceUssager
//
//  Created by dvaca on 6/11/25.
//

import Foundation
import Combine

class FileScanner: ObservableObject {
    @Published var files: [FileItem] = []
    @Published var totalSize: Int64 = 0
    @Published var isScanning = false
    @Published var selectedPath: String = ""
    
    private let logger = AppLogger.shared
    
    func scanDirectory(at url: URL) {
        logger.scan("\(String(localized: "log.scan.starting", defaultValue: "Starting scan of: %@")) \(url.path)")
        
        isScanning = true
        selectedPath = url.path
        files = []
        totalSize = 0
        
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            guard let self = self else {
                AppLogger.shared.warning("\(String(localized: "log.scan.deallocated", defaultValue: "Self was deallocated, aborting scan"))", category: .scan)
                return
            }
            
            var scannedFiles: [FileItem] = []
            var total: Int64 = 0
            
            let fileManager = FileManager.default
            
            // Get only first level of contents
            let contents: [URL]
            do {
                contents = try fileManager.contentsOfDirectory(
                    at: url,
                    includingPropertiesForKeys: [.isDirectoryKey, .fileSizeKey, .nameKey],
                    options: [.skipsHiddenFiles]
                )
            } catch {
                self.logger.error("\(String(localized: "log.scan.failed", defaultValue: "Failed to read directory contents: %@")) \(url.path)", category: .scan)
                self.logger.error("\(String(localized: "log.scan.reason", defaultValue: "Reason: %@")) \(error.localizedDescription)", category: .scan)
                DispatchQueue.main.async {
                    self.isScanning = false
                    // Clear the selected path on error to show empty/welcome state
                    self.selectedPath = ""
                    self.files = []
                    self.totalSize = 0
                }
                return
            }
            
            self.logger.scan(String(format: String(localized: "log.scan.found", defaultValue: "Found %d items to process"), contents.count))
            
            for itemURL in contents {
                do {
                    let resourceValues = try itemURL.resourceValues(forKeys: [.isDirectoryKey, .nameKey])
                    let isDirectory = resourceValues.isDirectory ?? false
                    let fileName = resourceValues.name ?? itemURL.lastPathComponent
                    
                    // For files, get size immediately and update UI
                    if !isDirectory {
                        let itemSize = self.getFileSize(url: itemURL)
                        self.logger.scan(String(format: String(localized: "log.scan.file", defaultValue: "File: %@ - %@"), fileName, self.formatBytes(itemSize)))
                        
                        let fileItem = FileItem(
                            name: fileName,
                            size: itemSize,
                            path: itemURL.path,
                            isDirectory: isDirectory
                        )
                        
                        scannedFiles.append(fileItem)
                        total += itemSize
                        
                        // Update UI with current progress
                        DispatchQueue.main.async { [weak self] in
                            self?.files = scannedFiles.sorted { $0.size > $1.size }
                            self?.totalSize = total
                        }
                    } else {
                        // For directories, add with size 0 first, then calculate
                        self.logger.scan(String(format: String(localized: "log.scan.folderFound", defaultValue: "Folder found: %@ - calculating size..."), fileName))
                        
                        let fileItem = FileItem(
                            name: fileName,
                            size: 0,
                            path: itemURL.path,
                            isDirectory: isDirectory
                        )
                        
                        scannedFiles.append(fileItem)
                        
                        // Update UI to show the folder
                        DispatchQueue.main.async { [weak self] in
                            self?.files = scannedFiles.sorted { $0.size > $1.size }
                        }
                        
                        // Calculate directory size
                        let startTime = Date()
                        let itemSize = self.calculateDirectorySize(url: itemURL)
                        let duration = Date().timeIntervalSince(startTime)
                        self.logger.scan(String(format: String(localized: "log.scan.folderComplete", defaultValue: "Folder: %@ - %@ (took %.2fs)"), fileName, self.formatBytes(itemSize), duration))
                        
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
                        DispatchQueue.main.async { [weak self] in
                            self?.files = scannedFiles.sorted { $0.size > $1.size }
                            self?.totalSize = total
                        }
                    }
                } catch {
                    self.logger.error(String(format: String(localized: "log.scan.error", defaultValue: "Error reading item: %@"), error.localizedDescription), category: .scan)
                }
            }
            
            // Final update
            DispatchQueue.main.async { [weak self] in
                guard let self = self else { return }
                self.files = scannedFiles.sorted { $0.size > $1.size }
                self.totalSize = total
                self.isScanning = false
                
                let fileCount = scannedFiles.filter { !$0.isDirectory }.count
                let folderCount = scannedFiles.filter { $0.isDirectory }.count
                self.logger.success(String(localized: "log.scan.completed", defaultValue: "Scan completed!"), category: .scan)
                self.logger.info(String(format: String(localized: "log.scan.total", defaultValue: "Total: %@"), self.formatBytes(total)), category: .scan)
                self.logger.info(String(format: String(localized: "log.scan.stats", defaultValue: "Files: %d, Folders: %d"), fileCount, folderCount), category: .scan)
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
    
    func scanDirectoryRecursively(at url: URL, completion: @escaping ([FileItem]) -> Void) {
        logger.scan(String(format: String(localized: "log.scan.recursive", defaultValue: "Starting recursive scan of: %@"), url.path))
        
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            guard let self = self else { return }
            
            var allFiles: [FileItem] = []
            let fileManager = FileManager.default
            
            guard let enumerator = fileManager.enumerator(
                at: url,
                includingPropertiesForKeys: [.isDirectoryKey, .fileSizeKey, .nameKey],
                options: [.skipsHiddenFiles]
            ) else {
                DispatchQueue.main.async {
                    completion([])
                }
                return
            }
            
            for case let fileURL as URL in enumerator {
                do {
                    let resourceValues = try fileURL.resourceValues(forKeys: [.isDirectoryKey, .nameKey, .fileSizeKey])
                    let isDirectory = resourceValues.isDirectory ?? false
                    let fileName = resourceValues.name ?? fileURL.lastPathComponent
                    
                    let itemSize: Int64
                    if isDirectory {
                        itemSize = self.calculateDirectorySize(url: fileURL)
                    } else {
                        itemSize = Int64(resourceValues.fileSize ?? 0)
                    }
                    
                    let fileItem = FileItem(
                        name: fileName,
                        size: itemSize,
                        path: fileURL.path,
                        isDirectory: isDirectory
                    )
                    
                    allFiles.append(fileItem)
                } catch {
                    continue
                }
            }
            
            // Sort by size
            let sortedFiles = allFiles.sorted { $0.size > $1.size }
            
            DispatchQueue.main.async {
                self.logger.success(String(format: String(localized: "log.scan.recursiveComplete", defaultValue: "Recursive scan completed: %d items found"), sortedFiles.count), category: .scan)
                completion(sortedFiles)
            }
        }
    }
    
    func deleteItem(at path: String) -> String? {
        logger.info(String(format: String(localized: "log.delete.attempting", defaultValue: "Attempting to delete: %@"), path), category: .general)
        
        let fileManager = FileManager.default
        let url = URL(fileURLWithPath: path)
        
        do {
            try fileManager.removeItem(at: url)
            logger.success(String(format: String(localized: "log.delete.success", defaultValue: "Successfully deleted: %@"), path), category: .general)
            
            // Refresh the current directory
            if !selectedPath.isEmpty {
                let currentURL = URL(fileURLWithPath: selectedPath)
                scanDirectory(at: currentURL)
            }
            return nil // Success, no error message
        } catch {
            let errorMessage = error.localizedDescription
            logger.error(String(format: String(localized: "log.delete.failed", defaultValue: "Failed to delete: %@"), path), category: .general)
            logger.error(String(format: String(localized: "log.delete.reason", defaultValue: "Reason: %@"), errorMessage), category: .general)
            return errorMessage // Return the error message
        }
    }
}

