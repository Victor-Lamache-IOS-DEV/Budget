import Foundation
import SwiftData

@Model
public final class Transaction {
    public var id: UUID
    public var date: Date
    public var originalAmount: Decimal
    public var originalCurrencyRaw: String
    public var rateUsed: Decimal
    public var baseAmount: Decimal
    public var categoryID: UUID?
    public var note: String
    
    public var originalCurrency: Currency {
        get {
            Currency(rawValue: originalCurrencyRaw) ?? .EUR
        }
        set {
            originalCurrencyRaw = newValue.rawValue
        }
    }
    
    public init(
        id: UUID = UUID(),
        date: Date = Date(),
        originalAmount: Decimal,
        originalCurrency: Currency,
        rateUsed: Decimal,
        baseAmount: Decimal,
        categoryID: UUID?,
        note: String = ""
    ) {
        self.id = id
        self.date = date
        self.originalAmount = originalAmount
        self.originalCurrencyRaw = originalCurrency.rawValue
        self.rateUsed = rateUsed
        self.baseAmount = baseAmount
        self.categoryID = categoryID
        self.note = note
    }
}
