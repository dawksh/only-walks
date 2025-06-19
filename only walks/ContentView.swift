//
//  ContentView.swift
//  only walks
//
//  Created by Daksh Kulshrestha on 19/06/25.
//

import SwiftUI

struct Walk: Identifiable {
    let id: UUID
    let doodle: Image
}

struct HomeView: View {
    @State var walks: [Walk] = []
    var columns: [GridItem] {
        [GridItem(.adaptive(minimum: 120), spacing: 8)]
    }
    var body: some View {
        VStack(spacing: 0) {
            if walks.isEmpty {
                Spacer()
                Text("no walks yet")
                    .font(.custom("IndieFlower", size: 22))
                    .foregroundColor(.secondary)
                Spacer()
            } else {
                ScrollView {
                    LazyVGrid(columns: columns, spacing: 12) {
                        ForEach(walks) { walk in
                            walk.doodle
                                .resizable()
                                .scaledToFit()
                                .frame(height: 120)
                                .background(Color.white)
                                .cornerRadius(16)
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.top, 12)
                }
                .refreshable { walks.shuffle() }
            }
        }
        .background(Color(red: 0.929, green: 0.918, blue: 0.914).ignoresSafeArea())
    }
}

struct ContentView: View {
    @EnvironmentObject var authState: AuthState
    var body: some View {
        Group {
            if authState.isAuthenticated {
                HomeView()
            } else {
                Button(action: { authState.isAuthenticated = true }) {
                    Text("login")
                        .font(.custom("IndieFlower", size: 24))
                }
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
