import Foundation
import SwiftData

@Model
public final class BudgetCategory {
    public var id: UUID
    public var name: String
    public var icon: String
    public var colorHex: String
    public var typeRaw: String
    public var monthlyCap: Decimal?
    public var order: Int
    
    public var type: CategoryType {
        get {
            CategoryType(rawValue: typeRaw) ?? .variable
        }
        set {
            typeRaw = newValue.rawValue
        }
    }
    
    public init(
        id: UUID = UUID(),
        name: String,
        icon: String = "tag.fill",
        colorHex: String = "#34C759",
        type: CategoryType = .variable,
        monthlyCap: Decimal? = nil,
        order: Int = 0
    ) {
        self.id = id
        self.name = name
        self.icon = icon
        self.colorHex = colorHex
        self.typeRaw = type.rawValue
        self.monthlyCap = monthlyCap
        self.order = order
    }
    
    public static var defaults: [BudgetCategory] {
        [
            BudgetCategory(
                name: "Courses",
                icon: "cart.fill",
                colorHex: "#34C759",
                type: .variable,
                monthlyCap: 300,
                order: 0
            ),
            BudgetCategory(
                name: "Abonnement transport en commun",
                icon: "tram.fill",
                colorHex: "#007AFF",
                type: .fixed,
                monthlyCap: 85,
                order: 1
            ),
            BudgetCategory(
                name: "Restaurant",
                icon: "fork.knife",
                colorHex: "#FF9500",
                type: .variable,
                monthlyCap: 150,
                order: 2
            ),
            BudgetCategory(
                name: "Shopping",
                icon: "bag.fill",
                colorHex: "#AF52DE",
                type: .variable,
                monthlyCap: 100,
                order: 3
            ),
            BudgetCategory(
                name: "Bar",
                icon: "wineglass.fill",
                colorHex: "#FF2D55",
                type: .variable,
                monthlyCap: 80,
                order: 4
            ),
            BudgetCategory(
                name: "Achat en ligne",
                icon: "globe",
                colorHex: "#5856D6",
                type: .variable,
                monthlyCap: nil,
                order: 5
            ),
            BudgetCategory(
                name: "Gros transport",
                icon: "airplane",
                colorHex: "#00C7BE",
                type: .smoothed,
                monthlyCap: 40,
                order: 6
            ),
            BudgetCategory(
                name: "Choses utiles obligatoires",
                icon: "shield.fill",
                colorHex: "#64D2FF",
                type: .fixed,
                monthlyCap: 50,
                order: 7
            )
        ]
    }
}
