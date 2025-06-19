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
    @EnvironmentObject var core: CoreDataStack
    @State var walks: [Walk] = []
    @State var isTracking = false
    @State var trackedWalk: Walk? = nil
    var columns: [GridItem] { [GridItem(.adaptive(minimum: 120), spacing: 8)] }
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
                                Rectangle()
                                    .foregroundColor(.white)
                                    .frame(height: 120)
                                    .cornerRadius(16)
                            }
                        }
                        .padding(.horizontal, 16)
                        .padding(.top, 12)
                    }
                    .refreshable { walks = loadWalks(core.context) }
                }
            }
            .background(Color(red: 0.929, green: 0.918, blue: 0.914).ignoresSafeArea())
            Button(action: { isTracking = true }) {
                HStack {
                    Text("start walk")
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
        .sheet(isPresented: $isTracking, onDismiss: {
            if let walk = trackedWalk { saveWalk(walk, core.context); walks = loadWalks(core.context) }
            trackedWalk = nil
        }) {
            WalkTrackingView(onFinish: { walk in trackedWalk = walk; isTracking = false })
        }
        .onAppear { walks = loadWalks(core.context) }
    }
}

struct WalkTrackingView: View {
    var onFinish: (Walk) -> Void
    @State var elapsed: TimeInterval = 0
    @State var distance: Double = 0
    @State var path: [CLLocationCoordinate2D] = []
    var body: some View {
        VStack(spacing: 24) {
            Text("elapsed: \(Int(elapsed))s")
            Text("distance: \(distance, specifier: "%.1f")m")
            Text("points: \(path.count)")
            Button("stop walk") {
                let walk = Walk(id: UUID(), startDate: Date().addingTimeInterval(-elapsed), endDate: Date(), path: path, distance: distance, duration: elapsed)
                onFinish(walk)
            }
        }
        .padding()
    }
} 