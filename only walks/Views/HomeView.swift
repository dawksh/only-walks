import SwiftUI
import CoreLocation

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
    @State var elapsed: TimeInterval = 0
    @State var distance: Double = 0
    @State var path: [CLLocationCoordinate2D] = []
    @State var startDate: Date? = nil
    @StateObject var location = LocationTracker()
    let columns: [GridItem] = [GridItem(.adaptive(minimum: 120), spacing: 8)]
    var body: some View {
        ZStack(alignment: .bottom) {
            Group {
                if isTracking {
                    trackingView
                } else {
                    notTrackingView
                }
            }
            .animation(.spring(), value: isTracking)
        }
        .onAppear { walks = loadWalks(core.context) }
        .onChange(of: location.locations) {
            guard isTracking else { return }
            let coords = location.locations.map { CLLocationCoordinate2D(latitude: $0.coordinate.latitude, longitude: $0.coordinate.longitude) }
            path = coords
            distance = totalDistance(path)
        }
        .onChange(of: isTracking) { tracking in
            if tracking { startTimer() } else { stopTimer() }
        }
    }
    var trackingView: some View {
        VStack(spacing: 0) {
            VStack(spacing: 24) {
                Text("elapsed: \(Int(elapsed))s")
                Text("distance: \(distance, specifier: "%.1f")m")
                Text("points: \(path.count)")
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(Color(red: 0.929, green: 0.918, blue: 0.914).ignoresSafeArea())
            Button(action: {
                withAnimation(.spring()) {
                    let walk = Walk(id: UUID(), startDate: startDate ?? Date(), endDate: Date(), path: path, distance: distance, duration: elapsed)
                    saveWalk(walk, core.context)
                    walks = loadWalks(core.context)
                    trackedWalk = nil
                    isTracking = false
                    elapsed = 0
                    distance = 0
                    path = []
                    startDate = nil
                    location.stop()
                }
            }) {
                HStack {
                    Text("stop walk").font(.custom("IndieFlower", size: 22))
                }
                .frame(maxWidth: .infinity)
                .frame(height: 54)
                .background(Color.clear)
                .foregroundColor(.red)
                .overlay(RoundedRectangle(cornerRadius: 27).stroke(Color.red, lineWidth: 2))
            }
            .padding(.horizontal, 16)
            .padding(.bottom, 20)
            .transition(.move(edge: .bottom).combined(with: .opacity))
        }
    }
    var notTrackingView: some View {
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
                            DoodleView(path: walk.path)
                                .background(Color.white)
                                .frame(height: 120)
                                .cornerRadius(16)
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.top, 12)
                }
                .refreshable { walks = loadWalks(core.context) }
            }
            Button(action: { withAnimation(.spring()) {
                isTracking = true
                startDate = Date()
                path = []
                distance = 0
                elapsed = 0
                location.start()
            } }) {
                HStack {
                    Text("start walk").font(.custom("IndieFlower", size: 22))
                }
                .frame(maxWidth: .infinity)
                .frame(height: 54)
                .background(Color.clear)
                .foregroundColor(.blue)
                .overlay(RoundedRectangle(cornerRadius: 27).stroke(Color.blue, lineWidth: 2))
            }
            .padding(.horizontal, 16)
            .padding(.bottom, 20)
            .transition(.move(edge: .bottom).combined(with: .opacity))
        }
        .background(Color(red: 0.929, green: 0.918, blue: 0.914).ignoresSafeArea())
    }
    func startTimer() {
        Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { timer in
            if isTracking { elapsed += 1 } else { timer.invalidate() }
        }
    }
    func stopTimer() {}
}

final class LocationTracker: NSObject, ObservableObject, CLLocationManagerDelegate {
    @Published var locations: [CLLocation] = []
    private let manager = CLLocationManager()
    override init() {
        super.init()
        manager.delegate = self
        manager.desiredAccuracy = kCLLocationAccuracyBest
        manager.allowsBackgroundLocationUpdates = false
    }
    func start() {
        manager.requestWhenInUseAuthorization()
        manager.startUpdatingLocation()
    }
    func stop() {
        manager.stopUpdatingLocation()
        locations = []
    }
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locs: [CLLocation]) {
        locations.append(contentsOf: locs)
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

struct DoodleView: View {
    let path: [CLLocationCoordinate2D]
    var body: some View {
        GeometryReader { geo in
            Canvas { ctx, size in
                guard path.count > 1 else { return }
                let minLat = path.map { $0.latitude }.min() ?? 0
                let maxLat = path.map { $0.latitude }.max() ?? 1
                let minLon = path.map { $0.longitude }.min() ?? 0
                let maxLon = path.map { $0.longitude }.max() ?? 1
                let w = maxLon - minLon
                let h = maxLat - minLat
                let scale = min(size.width / (w == 0 ? 1 : w), size.height / (h == 0 ? 1 : h)) * 0.8
                let offsetX = (size.width - CGFloat(w) * scale) / 2
                let offsetY = (size.height - CGFloat(h) * scale) / 2
                var p = Path()
                for (i, c) in path.enumerated() {
                    let x = CGFloat(c.longitude - minLon) * scale + offsetX
                    let y = size.height - (CGFloat(c.latitude - minLat) * scale + offsetY)
                    if i == 0 { p.move(to: CGPoint(x: x, y: y)) } else { p.addLine(to: CGPoint(x: x, y: y)) }
                }
                ctx.stroke(p, with: .color(.blue), lineWidth: 2)
            }
        }
    }
} 