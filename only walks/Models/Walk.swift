import Foundation
import CoreLocation
import CoreData

struct CLLocationCoordinate2D: Codable, Hashable {
    var latitude: Double
    var longitude: Double
    func distance(from other: CLLocationCoordinate2D) -> Double {
        let r = 6371000.0
        let lat1 = latitude * .pi / 180
        let lat2 = other.latitude * .pi / 180
        let dlat = (other.latitude - latitude) * .pi / 180
        let dlon = (other.longitude - longitude) * .pi / 180
        let a = sin(dlat/2) * sin(dlat/2) + cos(lat1) * cos(lat2) * sin(dlon/2) * sin(dlon/2)
        let c = 2 * atan2(sqrt(a), sqrt(1-a))
        return r * c
    }
}

struct Walk: Identifiable, Codable {
    let id: UUID
    let startDate: Date
    let endDate: Date
    let path: [CLLocationCoordinate2D]
    let distance: Double
    let duration: TimeInterval
}

func totalDistance(_ path: [CLLocationCoordinate2D]) -> Double {
    zip(path, path.dropFirst()).reduce(0) {
        $0 + $1.0.distance(from: $1.1)
    }
}

extension WalkEntity {
    var walk: Walk {
        Walk(
            id: id ?? UUID(),
            startDate: startDate ?? .distantPast,
            endDate: endDate ?? .distantPast,
            path: (try? JSONDecoder().decode([CLLocationCoordinate2D].self, from: pathData ?? Data())) ?? [],
            distance: distance,
            duration: duration
        )
    }
    func update(from walk: Walk) {
        id = walk.id
        startDate = walk.startDate
        endDate = walk.endDate
        pathData = (try? JSONEncoder().encode(walk.path)) ?? Data()
        distance = walk.distance
        duration = walk.duration
    }
}

func saveWalk(_ walk: Walk, _ context: NSManagedObjectContext) {
    let entity = WalkEntity(context: context)
    entity.update(from: walk)
    try? context.save()
}

func loadWalks(_ context: NSManagedObjectContext) -> [Walk] {
    let req = NSFetchRequest<WalkEntity>(entityName: "WalkEntity")
    let entities = (try? context.fetch(req)) ?? []
    return entities.map { $0.walk }
}

func deleteWalk(_ walk: Walk, _ context: NSManagedObjectContext) {
    let req = NSFetchRequest<WalkEntity>(entityName: "WalkEntity")
    req.predicate = NSPredicate(format: "id == %@", walk.id as CVarArg)
    if let entities = try? context.fetch(req) {
        for entity in entities { context.delete(entity) }
        try? context.save()
    }
}

func simplifyPath(_ path: [CLLocationCoordinate2D], tolerance: Double) -> [CLLocationCoordinate2D] {
    guard path.count > 2 else { return path }
    func perpendicularDistance(_ p: CLLocationCoordinate2D, _ a: CLLocationCoordinate2D, _ b: CLLocationCoordinate2D) -> Double {
        let dx = b.longitude - a.longitude
        let dy = b.latitude - a.latitude
        if dx == 0 && dy == 0 { return p.distance(from: a) }
        let t = ((p.longitude - a.longitude) * dx + (p.latitude - a.latitude) * dy) / (dx * dx + dy * dy)
        let tClamped = max(0, min(1, t))
        let proj = CLLocationCoordinate2D(latitude: a.latitude + tClamped * dy, longitude: a.longitude + tClamped * dx)
        return p.distance(from: proj)
    }
    func dp(_ pts: [CLLocationCoordinate2D]) -> [CLLocationCoordinate2D] {
        if pts.count < 3 { return pts }
        let a = pts.first!, b = pts.last!
        let (maxDist, idx) = pts.enumerated().dropFirst().dropLast().map { (i, p) in (perpendicularDistance(p, a, b), i) }.max(by: { $0.0 < $1.0 }) ?? (0, 0)
        if maxDist > tolerance {
            let left = dp(Array(pts[0...idx]))
            let right = dp(Array(pts[idx...]))
            return left.dropLast() + right
        } else {
            return [a, b]
        }
    }
    return dp(path)
}

extension Walk {
    var paceKmHr: Double? { distance > 0 && duration > 0 ? (distance / duration) * 3.6 : nil }
    var formattedDuration: String? {
        guard duration > 0 else { return nil }
        let h = Int(duration) / 3600
        let m = (Int(duration) % 3600) / 60
        let s = Int(duration) % 60
        return String(format: "%02d:%02d:%02d", h, m, s)
    }
} 