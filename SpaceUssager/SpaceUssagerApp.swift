//
//  SpaceUssagerApp.swift
//  SpaceUssager
//
//  Created by dvaca on 6/11/25.
//

import SwiftUI

@main
struct SpaceUssagerApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .windowStyle(.automatic)
        .windowToolbarStyle(.unified)
        .commands {
            CommandGroup(replacing: .newItem) { }
            HelpCommands()
        }
        
        Window(String(localized: "help.window.title", defaultValue: "Help"), id: "help") {
            HelpView()
        }
        .windowStyle(.hiddenTitleBar)
        .windowResizability(.contentSize)
        .defaultPosition(.center)
    }
}

// Custom Help Commands
struct HelpCommands: Commands {
    @Environment(\.openWindow) private var openWindow
    
    var body: some Commands {
        CommandGroup(replacing: .help) {
            Button(String(localized: "menu.help.spaceussager", defaultValue: "SpaceUssager Help")) {
                openWindow(id: "help")
            }
            .keyboardShortcut("?", modifiers: .command)
        }
    }
}
