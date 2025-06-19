import SwiftUI

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