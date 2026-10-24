import SwiftUI
import SwiftData

@main
struct BudgetApp: App {
    let container: ModelContainer
    
    init() {
        do {
            let schema = Schema([
                UserSettings.self,
                BudgetCategory.self,
                Transaction.self,
                Income.self,
                CycleOverride.self
            ])
            let config = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)
            container = try ModelContainer(for: schema, configurations: [config])
            
            // Seed defaults if needed
            seedInitialDataIfNeeded(context: container.mainContext)
        } catch {
            fatalError("Failed to initialize SwiftData model container: \(error)")
        }
    }
    
    var body: some Scene {
        WindowGroup {
            MainTabView()
        }
        .modelContainer(container)
    }
    
    @MainActor
    private func seedInitialDataIfNeeded(context: ModelContext) {
        let settingsDesc = FetchDescriptor<UserSettings>()
        let settingsCount = (try? context.fetchCount(settingsDesc)) ?? 0
        if settingsCount == 0 {
            let initialSettings = UserSettings(
                baseCurrency: .EUR,
                paydayDay: 25,
                defaultSalary: 2500,
                salaryCurrency: .EUR,
                savingsGoal: 400,
                buffer: 0,
                eurSekRate: Decimal(string: "11.12") ?? 11.12,
                initialBalance: 0,
                roundToUnit: false,
                hasCompletedOnboarding: false
            )
            context.insert(initialSettings)
        }
        
        let catDesc = FetchDescriptor<BudgetCategory>()
        let catCount = (try? context.fetchCount(catDesc)) ?? 0
        if catCount == 0 {
            for cat in BudgetCategory.defaults {
                context.insert(cat)
            }
        }
        
        try? context.save()
    }
}
