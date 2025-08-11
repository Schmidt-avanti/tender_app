import CoreData
import OSLog

final class CoreDataStack {
    static let shared = CoreDataStack()
    private(set) var container: NSPersistentContainer!
    var context: NSManagedObjectContext { container.viewContext }

    func bootstrap() {
        let model = NSManagedObjectModel()
        let notice = NSEntityDescription()
        notice.name = "NoticeEntity"; notice.managedObjectClassName = "NoticeEntity"
        var props: [NSPropertyDescription] = []

        func attr(_ name: String, _ type: NSAttributeType) -> NSAttributeDescription {
            let a = NSAttributeDescription(); a.name = name; a.attributeType = type; a.isOptional = true; return a
        }
        props.append(attr("publicationNumber", .stringAttributeType))
        props.append(attr("title", .stringAttributeType))
        props.append(attr("country", .stringAttributeType))
        props.append(attr("procedure", .stringAttributeType))
        props.append(attr("cpvTop", .stringAttributeType))
        props.append(attr("budget", .doubleAttributeType))
        props.append(attr("publicationDate", .dateAttributeType))
        let fav = attr("isFavorite", .booleanAttributeType); fav.isOptional = false; props.append(fav)

        notice.properties = props
        model.entities = [notice]

        container = NSPersistentContainer(name: "ProcureFinder", managedObjectModel: model)
        container.loadPersistentStores { _, error in
            if let error { fatalError("Core Data load error: \(error)") }
        }
    }
}

@objc(NoticeEntity)
final class NoticeEntity: NSManagedObject {
    @NSManaged var publicationNumber: String?
    @NSManaged var title: String?
    @NSManaged var country: String?
    @NSManaged var procedure: String?
    @NSManaged var cpvTop: String?
    @NSManaged var budget: Double
    @NSManaged var publicationDate: Date?
    @NSManaged var isFavorite: Bool
}

extension NoticeEntity {
    @nonobjc public class func fetchRequest() -> NSFetchRequest<NoticeEntity> {
        NSFetchRequest<NoticeEntity>(entityName: "NoticeEntity")
    }
}
