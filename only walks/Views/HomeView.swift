import SwiftUI

struct PointerAnimation: View {
    @State var animate = false
    var body: some View {
        Image(systemName: "hand.point.up.left.fill")
            .font(.system(size: 40))
            .foregroundColor(.blue)
            .opacity(0.8)
            .offset(y: animate ? -16 : 8)
            .scaleEffect(animate ? 1.1 : 0.95)
            .animation(Animation.easeInOut(duration: 0.7).repeatForever(autoreverses: true), value: animate)
            .onAppear { animate = true }
    }
}

struct HomeView: View {
    @State var walks: [Walk] = []
    var columns: [GridItem] {
        [GridItem(.adaptive(minimum: 120), spacing: 8)]
    }
    @State var isTracking = false
    var body: some View {
        ZStack(alignment: .bottom) {
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
            Button(action: { isTracking.toggle() }) {
                HStack {
                    
                    Text(isTracking ? "stop walk" : "start walk")
                        .font(.custom("IndieFlower", size: 22))
                }
                .frame(maxWidth: .infinity)
                .frame(height: 54)
                .background(Color.clear)
                .foregroundColor(.blue)
                .overlay(
                    RoundedRectangle(cornerRadius: 27)
                        .stroke(Color.blue, lineWidth: 2)
                )
            }
            .padding(.horizontal, 16)
            .padding(.bottom, 20)
            .shadow(radius: 0)
        }
    }
} 