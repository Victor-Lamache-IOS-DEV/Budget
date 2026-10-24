import Foundation
import SwiftData

@Model
public final class UserSettings {
    public var id: UUID
    public var baseCurrencyRaw: String
    public var paydayDay: Int
    public var defaultSalary: Decimal
    public var salaryCurrencyRaw: String
    public var savingsGoal: Decimal
    public var buffer: Decimal
    public var eurSekRate: Decimal
    public var initialBalance: Decimal
    public var roundToUnit: Bool
    public var hasCompletedOnboarding: Bool
    
    public var baseCurrency: Currency {
        get {
            Currency(rawValue: baseCurrencyRaw) ?? .EUR
        }
        set {
            baseCurrencyRaw = newValue.rawValue
        }
    }
    
    public var salaryCurrency: Currency {
        get {
            Currency(rawValue: salaryCurrencyRaw) ?? baseCurrency
        }
        set {
            salaryCurrencyRaw = newValue.rawValue
        }
    }
    
    public init(
        id: UUID = UUID(),
        baseCurrency: Currency = .EUR,
        paydayDay: Int = 25,
        defaultSalary: Decimal = 2500,
        salaryCurrency: Currency = .EUR,
        savingsGoal: Decimal = 400,
        buffer: Decimal = 0,
        eurSekRate: Decimal = Decimal(string: "11.12") ?? 11.12,
        initialBalance: Decimal = 0,
        roundToUnit: Bool = false,
        hasCompletedOnboarding: Bool = false
    ) {
        self.id = id
        self.baseCurrencyRaw = baseCurrency.rawValue
        self.paydayDay = min(max(paydayDay, 1), 31)
        self.defaultSalary = defaultSalary
        self.salaryCurrencyRaw = salaryCurrency.rawValue
        self.savingsGoal = savingsGoal
        self.buffer = buffer
        self.eurSekRate = eurSekRate
        self.initialBalance = initialBalance
        self.roundToUnit = roundToUnit
        self.hasCompletedOnboarding = hasCompletedOnboarding
    }
}
