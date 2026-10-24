import SwiftUI
import SwiftData

struct DayGroup: Identifiable {
    var id: Date { date }
    let date: Date
    let transactions: [Transaction]
}

public struct HistoryView: View {
    @Environment(\.modelContext) private var modelContext
    
    @Query private var settingsList: [UserSettings]
    @Query private var categories: [BudgetCategory]
    @Query(sort: \Transaction.date, order: .reverse) private var transactions: [Transaction]
    @Query private var overrides: [CycleOverride]
    
    @State private var selectedCycle: CyclePeriod?
    @State private var editingTransaction: Transaction?
    @State private var searchText: String = ""
    
    private var settings: UserSettings {
        settingsList.first ?? UserSettings()
    }
    
    private var availableCycles: [CyclePeriod] {
        BudgetCalculator.recentCycles(
            count: 6,
            payday: settings.paydayDay,
            overrides: overrides
        )
    }
    
    private var activeCycle: CyclePeriod {
        selectedCycle ?? availableCycles.first ?? BudgetCalculator.cycleForDate(Date(), payday: settings.paydayDay)
    }
    
    private var filteredTransactions: [Transaction] {
        let cycleTx = transactions.filter { activeCycle.contains($0.date) }
        guard !searchText.isEmpty else { return cycleTx }
        
        return cycleTx.filter { tx in
            let categoryName = categories.first(where: { $0.id == tx.categoryID })?.name ?? ""
            return tx.note.localizedCaseInsensitiveContains(searchText) ||
                   categoryName.localizedCaseInsensitiveContains(searchText)
        }
    }
    
    // Grouped by day
    private var groupedTransactions: [DayGroup] {
        let calendar = Calendar.current
        let grouped = Dictionary(grouping: filteredTransactions) { tx in
            calendar.startOfDay(for: tx.date)
        }
        return grouped
            .map { DayGroup(date: $0.key, transactions: $0.value) }
            .sorted { $0.date > $1.date }
    }
    
    private var totalCycleSpent: Decimal {
        filteredTransactions.reduce(0) { $0 + $1.baseAmount }
    }
    
    public var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // MARK: - Cycle Selector
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        ForEach(availableCycles) { cycle in
                            let isSelected = activeCycle.startDate == cycle.startDate
                            Button {
                                Haptics.playLight()
                                selectedCycle = cycle
                            } label: {
                                Text(cycle.shortDescription)
                                    .font(.subheadline)
                                    .fontWeight(isSelected ? .bold : .medium)
                                    .padding(.horizontal, 14)
                                    .padding(.vertical, 8)
                                    .background(isSelected ? Color.accentColor : Color(.secondarySystemBackground))
                                    .foregroundStyle(isSelected ? .white : .primary)
                                    .clipShape(Capsule())
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding(.horizontal)
                    .padding(.vertical, 8)
                }
                .background(Color(.systemBackground))
                
                Divider()
                
                // MARK: - Cycle Summary Banner
                HStack {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Total dépensé")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        Text(BudgetCalculator.formatAmount(totalCycleSpent, currency: settings.baseCurrency, roundToUnit: settings.roundToUnit))
                            .font(.title3)
                            .fontWeight(.bold)
                    }
                    
                    Spacer()
                    
                    Text("\(filteredTransactions.count) dépense\(filteredTransactions.count > 1 ? "s" : "")")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }
                .padding(.horizontal)
                .padding(.vertical, 10)
                .background(Color(.secondarySystemBackground))
                
                // MARK: - Transactions List
                if filteredTransactions.isEmpty {
                    VStack(spacing: 12) {
                        Spacer()
                        Image(systemName: "tray")
                            .font(.system(size: 44))
                            .foregroundStyle(.secondary)
                        Text("Aucune dépense sur ce cycle")
                            .font(.headline)
                            .foregroundStyle(.secondary)
                        Spacer()
                    }
                } else {
                    List {
                        ForEach(groupedTransactions) { group in
                            Section(header: Text(formatSectionHeader(group.date))) {
                                ForEach(group.transactions) { tx in
                                    TransactionRow(
                                        transaction: tx,
                                        category: categories.first { $0.id == tx.categoryID },
                                        baseCurrency: settings.baseCurrency,
                                        roundToUnit: settings.roundToUnit
                                    )
                                    .contentShape(Rectangle())
                                    .onTapGesture {
                                        editingTransaction = tx
                                    }
                                    .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                                        Button(role: .destructive) {
                                            deleteTransaction(tx)
                                        } label: {
                                            Label("Supprimer", systemImage: "trash")
                                        }
                                    }
                                }
                            }
                        }
                    }
                    .listStyle(.insetGrouped)
                }
            }
            .navigationTitle("Historique")
            .searchable(text: $searchText, prompt: "Rechercher une note ou catégorie")
            .sheet(item: $editingTransaction) { tx in
                EditExpenseView(
                    transaction: tx,
                    settings: settings,
                    categories: categories
                )
            }
        }
    }
    
    private func formatSectionHeader(_ date: Date) -> String {
        let calendar = Calendar.current
        if calendar.isDateInToday(date) {
            return "Aujourd'hui"
        } else if calendar.isDateInYesterday(date) {
            return "Hier"
        } else {
            let formatter = DateFormatter()
            formatter.locale = Locale(identifier: "fr_FR")
            formatter.dateFormat = "EEEE d MMMM"
            return formatter.string(from: date).capitalized
        }
    }
    
    private func deleteTransaction(_ tx: Transaction) {
        modelContext.delete(tx)
        try? modelContext.save()
        Haptics.playMedium()
    }
}

// MARK: - Transaction Row Component

struct TransactionRow: View {
    let transaction: Transaction
    let category: BudgetCategory?
    let baseCurrency: Currency
    let roundToUnit: Bool
    
    var body: some View {
        HStack(spacing: 12) {
            ZStack {
                Circle()
                    .fill(category != nil ? Color(hex: category!.colorHex).opacity(0.18) : Color.gray.opacity(0.15))
                    .frame(width: 38, height: 38)
                Image(systemName: category?.icon ?? "cart.fill")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(category != nil ? Color(hex: category!.colorHex) : Color.gray)
            }
            
            VStack(alignment: .leading, spacing: 3) {
                Text(category?.name ?? "Non catégorisé")
                    .font(.subheadline)
                    .fontWeight(.semibold)
                
                if !transaction.note.isEmpty {
                    Text(transaction.note)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                }
            }
            
            Spacer()
            
            VStack(alignment: .trailing, spacing: 2) {
                Text("-" + BudgetCalculator.formatAmount(transaction.baseAmount, currency: baseCurrency, roundToUnit: roundToUnit))
                    .font(.subheadline)
                    .fontWeight(.bold)
                
                if transaction.originalCurrency != baseCurrency {
                    Text(BudgetCalculator.formatAmount(transaction.originalAmount, currency: transaction.originalCurrency))
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
            }
        }
        .padding(.vertical, 3)
    }
}
