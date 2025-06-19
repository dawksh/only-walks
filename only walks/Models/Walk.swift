import Foundation
import CoreLocation
import CoreData

struct CLLocationCoordinate2D: Codable, Hashable {
    var latitude: Double
    var longitude: Double
    func distance(from other: CLLocationCoordinate2D) -> Double {
        let dx = latitude - other.latitude
        let dy = longitude - other.longitude
        return sqrt(dx * dx + dy * dy) * 111_000
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

@objc(WalkEntity)
final class WalkEntity: NSManagedObject {
    @NSManaged var id: UUID
    @NSManaged var startDate: Date
    @NSManaged var endDate: Date
    @NSManaged var pathData: Data
    @NSManaged var distance: Double
    @NSManaged var duration: Double
}

extension WalkEntity {
    var walk: Walk {
        Walk(
            id: id,
            startDate: startDate,
            endDate: endDate,
            path: (try? JSONDecoder().decode([CLLocationCoordinate2D].self, from: pathData)) ?? [],
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