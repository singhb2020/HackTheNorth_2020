//
//  ContentView.swift
//  Halcyon
//
//  Created by Bishneet Singh on 2021-01-16.
//

import SwiftUI


struct ContentView: View {
    
    func runPermission()
    {
        BackendProcesses().requestAuthorization()
    }
    
    func runSync()
    {
        BackendProcesses().readHealthData()
    }
    
    var body: some View {
        Text("Hello, world!")
            .padding()
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
