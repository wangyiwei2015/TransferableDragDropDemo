//
//  cardbooktestApp.swift
//  cardbooktest
//
//  Created by leo on 2026.02.28.
//

import SwiftUI
import UniformTypeIdentifiers

extension UTType {
    static let cardType = UTType(exportedAs: "com.wyw.demo.cardinfo")
}

@main
struct cardbooktestApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}

struct ContentView: View {
    var body: some View {
        CollAndDeckDemo2()
    }
}
