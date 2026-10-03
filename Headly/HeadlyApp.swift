//
//  HeadlyApp.swift
//  Headly
//
//  Created by Maoqi on 2026/5/13.
//

import SwiftUI

@main
struct HeadlyApp: App {
    @State private var store = HeadacheStore()

    var body: some Scene {
        WindowGroup {
            ContentView(store: store)
                .preferredColorScheme(.light)
                .environment(\.locale, Locale(identifier: "zh_CN"))
        }
    }
}
