import Foundation
import SwiftData

@Model
public final class CycleOverride {
    public var id: UUID
    public var cycleStartDate: Date
    public var salaryOverride: Decimal?
    public var customStartDate: Date?
    
    public init(
        id: UUID = UUID(),
        cycleStartDate: Date,
        salaryOverride: Decimal? = nil,
        customStartDate: Date? = nil
    ) {
        self.id = id
        self.cycleStartDate = cycleStartDate
        self.salaryOverride = salaryOverride
        self.customStartDate = customStartDate
    }
}
