//
//  TempyApp.swift
//  Tempy
//
//  Created by Bishneet Singh on 2021-01-16.
//

import SwiftUI

@main
struct TempyApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
                .requestAuthorization()
        }
    }
}

