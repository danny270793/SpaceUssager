//
//  FileItem.swift
//  SpaceUssager
//
//  Created by dvaca on 6/11/25.
//

import Foundation

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

