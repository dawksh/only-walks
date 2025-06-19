//
//  ContentView.swift
//  only walks
//
//  Created by Daksh Kulshrestha on 19/06/25.
//

import SwiftUI

struct ContentView: View {
    @EnvironmentObject var authState: AuthState
    var body: some View {
        Group {
            if authState.isAuthenticated {
                Text("Walk Gallery")
            } else {
                Button("Login") { authState.isAuthenticated = true }
            }
        }
        .padding()
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(red: 0.929, green: 0.918, blue: 0.914).ignoresSafeArea())
    }
}

#Preview {
    ContentView().environmentObject(AuthState())
}
