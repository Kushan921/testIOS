import Foundation
import CoreData


extension UEntity {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<UEntity> {
        return NSFetchRequest<UEntity>(entityName: "UEntity")
    }

    @NSManaged public var createdAt: Date?
    @NSManaged public var email: String?
    @NSManaged public var password: String?
    @NSManaged public var username: String?

}

extension UEntity : Identifiable {

}
