import Foundation
import SwiftData

@Model
public final class Income {
    public var id: UUID
    public var date: Date
    public var originalAmount: Decimal
    public var currencyRaw: String
    public var rateUsed: Decimal
    public var baseAmount: Decimal
    public var label: String
    public var cycleStartDate: Date
    
    public var currency: Currency {
        get {
            Currency(rawValue: currencyRaw) ?? .EUR
        }
        set {
            currencyRaw = newValue.rawValue
        }
    }
    
    public init(
        id: UUID = UUID(),
        date: Date = Date(),
        originalAmount: Decimal,
        currency: Currency = .EUR,
        rateUsed: Decimal = 1,
        baseAmount: Decimal,
        label: String = "Salaire",
        cycleStartDate: Date
    ) {
        self.id = id
        self.date = date
        self.originalAmount = originalAmount
        self.currencyRaw = currency.rawValue
        self.rateUsed = rateUsed
        self.baseAmount = baseAmount
        self.label = label
        self.cycleStartDate = cycleStartDate
    }
}
