import Foundation
import CoreData


extension PEntity {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<PEntity> {
        return NSFetchRequest<PEntity>(entityName: "PEntity")
    }

    @NSManaged public var createdBy: String?
    @NSManaged public var isEditable: Bool
    @NSManaged public var projectDescription: String?
    @NSManaged public var title: String?
    @NSManaged public var category: String?
    @NSManaged public var date: Date?
    @NSManaged public var progress: Double

}

extension PEntity : Identifiable {

}
