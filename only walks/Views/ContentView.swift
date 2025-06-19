import SwiftUI

struct ContentView: View {
    var body: some View {
        HomeView()
            .padding()
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(Color(red: 0.929, green: 0.918, blue: 0.914).ignoresSafeArea())
    }
}

#Preview {
    ContentView()
} 