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
    @Namespace var doodleAnim
    @State var animatingDoodle = false
    @State var animatingPath: [CLLocationCoordinate2D]? = nil
    @State var animatingWalkId: UUID? = nil
    @State var selectedWalk: Walk? = nil
    var body: some View {
        NavigationView {
            ZStack(alignment: .bottom) {
                Group {
                    if isTracking {
                        trackingView
                    } else {
                        notTrackingView
                    }
                }
                .animation(.spring(), value: isTracking)
                if animatingDoodle, let animPath = animatingPath, let animId = animatingWalkId {
                    DoodleView(path: animPath)
                        .frame(width: 220, height: 220)
                        .matchedGeometryEffect(id: animId, in: doodleAnim)
                        .zIndex(2)
                }
            }
            .onAppear { walks = loadWalks(core.context).sorted { ($0.endDate ?? $0.startDate) > ($1.endDate ?? $1.startDate) } }
            .onChange(of: location.locations) {
                guard isTracking else { return }
                let filtered = location.locations.filter { $0.horizontalAccuracy < 20 }
                let coords = filtered.reduce(into: [CLLocationCoordinate2D]()) { arr, loc in
                    let coord = CLLocationCoordinate2D(latitude: loc.coordinate.latitude, longitude: loc.coordinate.longitude)
                    if let last = arr.last {
                        if last.distance(from: coord) >= 3 { arr.append(coord) }
                    } else {
                        arr.append(coord)
                    }
                }
                path = coords
                distance = totalDistance(path)
            }
            .onChange(of: isTracking) { tracking in
                if tracking { startTimer() } else { stopTimer() }
            }
            .background(
                NavigationLink(destination: selectedWalk.map { WalkDetailView(walk: $0, doodleAnim: doodleAnim, walks: $walks, selectedWalk: $selectedWalk).environmentObject(core) }, isActive: Binding(get: { selectedWalk != nil }, set: { if !$0 { selectedWalk = nil } })) { EmptyView() }
                    .hidden()
            )
        }
    }
    var trackingView: some View {
        VStack(spacing: 0) {
            Spacer()
            DoodleView(path: path)
                .frame(width: 220, height: 220)
                .opacity(animatingDoodle ? 0 : 1)
            HStack(spacing: 32) {
                Text("pace: \(distance > 0 ? String(format: "%.1f", elapsed / max(distance, 1)) : "-") s/m")
                Text("time: \(Int(elapsed))s")
                Text("dist: \(distance, specifier: "%.1f")m")
            }
            .font(.system(size: 18, weight: .medium, design: .rounded))
            .padding(.vertical, 24)
            Spacer()
            Button(action: {
                let newId = UUID()
                animatingWalkId = newId
                animatingPath = path
                animatingDoodle = true
                let walk = Walk(id: newId, startDate: startDate ?? Date(), endDate: Date(), path: path, distance: distance, duration: elapsed)
                saveWalk(walk, core.context)
                walks = loadWalks(core.context).sorted { ($0.endDate ?? $0.startDate) > ($1.endDate ?? $1.startDate) }
                trackedWalk = nil
                isTracking = false
                elapsed = 0
                distance = 0
                path = []
                startDate = nil
                location.stop()
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) {
                    withAnimation(.spring()) {
                        animatingDoodle = false
                        animatingWalkId = nil
                        animatingPath = nil
                    }
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
        .background(Color(red: 0.929, green: 0.918, blue: 0.914).ignoresSafeArea())
    }
    var notTrackingView: some View {
        VStack(spacing: 0) {
            if walks.isEmpty {
                Spacer()
                Text("no walks yet")
                    .font(.custom("IndieFlower", size: 22))
                    .foregroundColor(.primary)
                Spacer()
            } else {
                ScrollView {
                    LazyVGrid(columns: columns, spacing: 12) {
                        ForEach(walks) { walk in
                            DoodleView(path: walk.path)
                                .frame(height: 120)
                                .cornerRadius(16)
                                .matchedGeometryEffect(id: walk.id, in: doodleAnim, isSource: true)
                                .opacity(selectedWalk?.id == walk.id ? 0 : 1)
                                .onTapGesture { selectedWalk = walk }
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.top, 12)
                }
                .refreshable { walks = loadWalks(core.context).sorted { ($0.endDate ?? $0.startDate) > ($1.endDate ?? $1.startDate) } }
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
        locations.append(contentsOf: locs.filter { $0.horizontalAccuracy < 20 })
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
                let margin: CGFloat = 10
                let minLat = path.map { $0.latitude }.min() ?? 0
                let maxLat = path.map { $0.latitude }.max() ?? 1
                let minLon = path.map { $0.longitude }.min() ?? 0
                let maxLon = path.map { $0.longitude }.max() ?? 1
                let w = max(maxLon - minLon, 0.0001)
                let h = max(maxLat - minLat, 0.0001)
                let scale = min((size.width - 2 * margin) / w, (size.height - 2 * margin) / h)
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

struct WalkDetailView: View {
    let walk: Walk
    var doodleAnim: Namespace.ID
    @EnvironmentObject var core: CoreDataStack
    @Environment(\.presentationMode) var presentation
    @Binding var walks: [Walk]
    @Binding var selectedWalk: Walk?
    var body: some View {
        ZStack {
            Color(red: 0.929, green: 0.918, blue: 0.914).ignoresSafeArea()
            VStack(spacing: 32) {
                ZStack {
                    DoodleView(path: walk.path)
                        .frame(width: 220, height: 140)
                        .matchedGeometryEffect(id: walk.id, in: doodleAnim, isSource: true)
                        .clipped()
                }
                HStack(spacing: 32) {
                    Text("\(walk.distance > 0 ? String(format: "%.1f", walk.duration / max(walk.distance, 1)) : "-") s/m")
                        .font(.custom("IndieFlower", size: 20))
                        .foregroundColor(.primary)
                    Text("\(Int(walk.duration))s")
                        .font(.custom("IndieFlower", size: 20))
                        .foregroundColor(.primary)
                    Text("\(walk.distance, specifier: "%.1f")m")
                        .font(.custom("IndieFlower", size: 20))
                        .foregroundColor(.primary)
                }
                Text("delete walk")
                    .font(.custom("IndieFlower", size: 20))
                    .foregroundColor(.red)
                    .onTapGesture {
                        deleteWalk(walk, core.context)
                        walks = loadWalks(core.context).sorted { ($0.endDate ?? $0.startDate) > ($1.endDate ?? $1.startDate) }
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                            selectedWalk = nil
                        }
                    }
            }
            .padding()
        }
        .navigationBarTitleDisplayMode(.inline)
        .navigationBarBackButtonHidden(true)
        .toolbar { ToolbarItem(placement: .navigationBarLeading) { EmptyView() } }
    }
} 