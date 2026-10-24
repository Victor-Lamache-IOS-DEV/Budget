import SwiftUI
import SwiftData

public struct HomeView: View {
    @Environment(\.modelContext) private var modelContext
    
    @Query private var settingsList: [UserSettings]
    @Query private var categories: [BudgetCategory]
    @Query(sort: \Transaction.date, order: .reverse) private var transactions: [Transaction]
    @Query private var overrides: [CycleOverride]
    @Query private var incomes: [Income]
    
    @State private var showAddExpenseSheet: Bool = false
    
    private var settings: UserSettings {
        settingsList.first ?? UserSettings()
    }
    
    private var currentCycle: CyclePeriod {
        BudgetCalculator.cycleForDate(
            Date(),
            payday: settings.paydayDay,
            overrides: overrides
        )
    }
    
    private var cycleOverride: CycleOverride? {
        overrides.first { Calendar.current.isDate($0.cycleStartDate, inSameDayAs: currentCycle.startDate) }
    }
    
    private var effectiveSalary: Decimal {
        if let overrideVal = cycleOverride?.salaryOverride {
            return overrideVal
        }
        // If defaultSalary was defined in salaryCurrency != baseCurrency, convert
        if settings.salaryCurrency != settings.baseCurrency {
            return BudgetCalculator.convert(
                amount: settings.defaultSalary,
                from: settings.salaryCurrency,
                to: settings.baseCurrency,
                rate: settings.eurSekRate
            )
        }
        return settings.defaultSalary
    }
    
    // Cycle transactions
    private var cycleTransactions: [Transaction] {
        transactions.filter { currentCycle.contains($0.date) }
    }
    
    // Fixed and smoothed allocations
    private var totalFixedAllocations: Decimal {
        categories
            .filter { $0.type == .fixed }
            .reduce(0) { $0 + ($1.monthlyCap ?? 0) }
    }
    
    private var totalSmoothedAllocations: Decimal {
        categories
            .filter { $0.type == .smoothed }
            .reduce(0) { $0 + ($1.monthlyCap ?? 0) }
    }
    
    // Variable budget
    private var variableBudget: Decimal {
        BudgetCalculator.calculateVariableBudget(
            salary: effectiveSalary,
            savingsGoal: settings.savingsGoal,
            fixedAllocations: totalFixedAllocations,
            smoothedAllocations: totalSmoothedAllocations,
            buffer: settings.buffer
        )
    }
    
    // Variable spent
    private var variableExpenses: Decimal {
        let variableCategoryIDs = Set(categories.filter { $0.type == .variable }.map { $0.id })
        return cycleTransactions
            .filter { tx in
                guard let catID = tx.categoryID else { return true } // uncategorized is variable
                return variableCategoryIDs.contains(catID)
            }
            .reduce(0) { $0 + $1.baseAmount }
    }
    
    // Remaining to spend
    private var remainingToSpend: Decimal {
        BudgetCalculator.calculateRemaining(
            variableBudget: variableBudget,
            variableExpenses: variableExpenses
        )
    }
    
    private var daysRemaining: Int {
        currentCycle.daysRemaining(relativeTo: Date())
    }
    
    private var dailyAllowance: Decimal {
        BudgetCalculator.dailyAllowance(remaining: remainingToSpend, daysRemaining: daysRemaining)
    }
    
    // Projected Account Balance
    private var projectedBalance: Decimal {
        let totalAllTimeIncomes = incomes.reduce(Decimal(0)) { $0 + $1.baseAmount } + effectiveSalary
        let totalAllTimeExpenses = transactions.reduce(Decimal(0)) { $0 + $1.baseAmount }
        return BudgetCalculator.projectedBalance(
            initialBalance: settings.initialBalance,
            totalIncomes: totalAllTimeIncomes,
            totalActualExpenses: totalAllTimeExpenses
        )
    }
    
    public var body: some View {
        NavigationStack {
            ZStack(alignment: .bottomTrailing) {
                ScrollView {
                    VStack(spacing: 20) {
                        // MARK: - Cycle Badge
                        HStack {
                            Image(systemName: "calendar.badge.clock")
                                .foregroundStyle(.secondary)
                            Text("Cycle en cours : \(currentCycle.shortDescription)")
                                .font(.footnote)
                                .fontWeight(.medium)
                                .foregroundStyle(.secondary)
                            Spacer()
                        }
                        .padding(.horizontal)
                        
                        // MARK: - Hero Card: Reste à dépenser
                        VStack(spacing: 12) {
                            Text("Reste à dépenser")
                                .font(.subheadline)
                                .fontWeight(.semibold)
                                .foregroundStyle(remainingToSpend < 0 ? .red.opacity(0.9) : .secondary)
                            
                            HStack(alignment: .firstTextBaseline, spacing: 4) {
                                Text(BudgetCalculator.formatAmount(
                                    remainingToSpend,
                                    currency: settings.baseCurrency,
                                    roundToUnit: settings.roundToUnit
                                ))
                                .font(.system(size: 44, weight: .bold, design: .rounded))
                                .foregroundStyle(remainingToSpend < 0 ? .red : .primary)
                                .lineLimit(1)
                                .minimumScaleFactor(0.6)
                            }
                            
                            // Negative overrun alert
                            if remainingToSpend < 0 {
                                let overrun = abs(remainingToSpend)
                                HStack(spacing: 6) {
                                    Image(systemName: "exclamationmark.triangle.fill")
                                    Text("Dépassement de " + BudgetCalculator.formatAmount(overrun, currency: settings.baseCurrency, roundToUnit: settings.roundToUnit))
                                }
                                .font(.footnote)
                                .fontWeight(.bold)
                                .foregroundStyle(.white)
                                .padding(.horizontal, 12)
                                .padding(.vertical, 6)
                                .background(Color.red)
                                .clipShape(Capsule())
                            }
                            
                            Divider()
                                .padding(.horizontal, 8)
                            
                            // Daily allowance & Days remaining
                            HStack(spacing: 16) {
                                VStack(spacing: 2) {
                                    Text("Par jour")
                                        .font(.caption2)
                                        .foregroundStyle(.secondary)
                                    Text(BudgetCalculator.formatAmount(
                                        dailyAllowance,
                                        currency: settings.baseCurrency,
                                        roundToUnit: settings.roundToUnit
                                    ))
                                    .font(.headline)
                                    .fontWeight(.bold)
                                    .foregroundStyle(remainingToSpend < 0 ? .red : .primary)
                                }
                                .frame(maxWidth: .infinity)
                                
                                Divider()
                                    .frame(height: 30)
                                
                                VStack(spacing: 2) {
                                    Text("Temps restant")
                                        .font(.caption2)
                                        .foregroundStyle(.secondary)
                                    Text("\(daysRemaining) jour\(daysRemaining > 1 ? "s" : "")")
                                        .font(.headline)
                                        .fontWeight(.bold)
                                        .foregroundStyle(.primary)
                                }
                                .frame(maxWidth: .infinity)
                            }
                        }
                        .padding(20)
                        .background(Color(.secondarySystemBackground))
                        .clipShape(RoundedRectangle(cornerRadius: 22))
                        .overlay(
                            RoundedRectangle(cornerRadius: 22)
                                .stroke(remainingToSpend < 0 ? Color.red.opacity(0.4) : Color.clear, lineWidth: 2)
                        )
                        .padding(.horizontal)
                        
                        // MARK: - Secondary Summary Cards
                        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 14) {
                            // Savings Goal
                            QuickStatCard(
                                title: "Épargne",
                                value: BudgetCalculator.formatAmount(
                                    settings.savingsGoal,
                                    currency: settings.baseCurrency,
                                    roundToUnit: settings.roundToUnit
                                ),
                                subtitle: "Objectif du cycle",
                                icon: "banknote.fill",
                                iconColor: .green,
                                progress: 1.0,
                                progressColor: .green
                            )
                            
                            // Projected balance
                            QuickStatCard(
                                title: "Solde projeté",
                                value: BudgetCalculator.formatAmount(
                                    projectedBalance,
                                    currency: settings.baseCurrency,
                                    roundToUnit: settings.roundToUnit
                                ),
                                subtitle: "Fin de cycle estimée",
                                icon: "chart.line.uptrend.xyaxis",
                                iconColor: .blue
                            )
                        }
                        .padding(.horizontal)
                        
                        // MARK: - Mini-List Categories with Progress
                        VStack(alignment: .leading, spacing: 12) {
                            HStack {
                                Text("Suivi des catégories")
                                    .font(.headline)
                                    .fontWeight(.bold)
                                Spacer()
                                Text("Budget prévu")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                            
                            VStack(spacing: 10) {
                                ForEach(categories.sorted { $0.order < $1.order }) { cat in
                                    let spent = cycleTransactions
                                        .filter { $0.categoryID == cat.id }
                                        .reduce(0) { $0 + $1.baseAmount }
                                    
                                    CategoryProgressBarRow(
                                        category: cat,
                                        spent: spent,
                                        baseCurrency: settings.baseCurrency,
                                        roundToUnit: settings.roundToUnit
                                    )
                                    
                                    if cat.id != categories.sorted(by: { $0.order < $1.order }).last?.id {
                                        Divider()
                                    }
                                }
                            }
                            .padding(16)
                            .background(Color(.secondarySystemBackground))
                            .clipShape(RoundedRectangle(cornerRadius: 18))
                        }
                        .padding(.horizontal)
                        
                        // Extra bottom spacing so content isn't hidden under floating button
                        Spacer()
                            .frame(height: 70)
                    }
                    .padding(.top, 10)
                }
                
                // MARK: - Floating Add Button
                Button {
                    Haptics.playMedium()
                    showAddExpenseSheet = true
                } label: {
                    Image(systemName: "plus")
                        .font(.system(size: 24, weight: .bold))
                        .foregroundStyle(.white)
                        .frame(width: 60, height: 60)
                        .background(Color.accentColor)
                        .clipShape(Circle())
                        .shadow(color: Color.accentColor.opacity(0.4), radius: 10, x: 0, y: 5)
                }
                .padding(.trailing, 22)
                .padding(.bottom, 20)
            }
            .navigationTitle("Budget")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        Haptics.playLight()
                        showAddExpenseSheet = true
                    } label: {
                        Image(systemName: "plus.circle.fill")
                            .font(.title3)
                    }
                }
            }
            .sheet(isPresented: $showAddExpenseSheet) {
                AddExpenseView(settings: settings, categories: categories)
            }
        }
    }
}
