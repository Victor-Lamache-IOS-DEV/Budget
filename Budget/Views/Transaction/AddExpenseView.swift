import SwiftUI
import SwiftData

public struct AddExpenseView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    
    let settings: UserSettings
    let categories: [BudgetCategory]
    
    @State private var amountString: String = ""
    @State private var selectedCurrency: Currency = .EUR
    @State private var selectedCategory: BudgetCategory?
    @State private var selectedDate: Date = Date()
    @State private var note: String = ""
    @State private var showDatePicker: Bool = false
    @State private var errorMessage: String?
    
    public init(settings: UserSettings, categories: [BudgetCategory]) {
        self.settings = settings
        self.categories = categories
        _selectedCurrency = State(initialValue: settings.baseCurrency)
    }
    
    private var numericAmount: Decimal {
        let cleaned = amountString.replacingOccurrences(of: ",", with: ".")
        return Decimal(string: cleaned) ?? 0
    }
    
    private var convertedAmountPreview: Decimal {
        BudgetCalculator.convert(
            amount: numericAmount,
            from: selectedCurrency,
            to: settings.baseCurrency,
            rate: settings.eurSekRate
        )
    }
    
    private var isDifferentCurrency: Bool {
        selectedCurrency != settings.baseCurrency
    }
    
    private var sortedCategories: [BudgetCategory] {
        categories.sorted { $0.order < $1.order }
    }
    
    public var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // MARK: - Amount & Currency Header
                VStack(spacing: 8) {
                    HStack(spacing: 12) {
                        Picker("Devise", selection: $selectedCurrency) {
                            ForEach(Currency.allCases) { curr in
                                Text(curr.symbol).tag(curr)
                            }
                        }
                        .pickerStyle(.segmented)
                        .frame(width: 120)
                        
                        Spacer()
                        
                        // Date Shortcut
                        Menu {
                            Button("Aujourd'hui") {
                                selectedDate = Date()
                            }
                            Button("Hier") {
                                selectedDate = Calendar.current.date(byAdding: .day, value: -1, to: Date()) ?? Date()
                            }
                            Button("Choisir une date...") {
                                showDatePicker = true
                            }
                        } label: {
                            HStack(spacing: 4) {
                                Image(systemName: "calendar")
                                Text(formattedSelectedDate)
                            }
                            .font(.caption)
                            .fontWeight(.medium)
                            .padding(.horizontal, 10)
                            .padding(.vertical, 6)
                            .background(Color(.tertiarySystemFill))
                            .clipShape(Capsule())
                        }
                    }
                    .padding(.horizontal)
                    .padding(.top, 8)
                    
                    // Large Amount Display
                    HStack(alignment: .firstTextBaseline, spacing: 4) {
                        Text(amountString.isEmpty ? "0" : amountString)
                            .font(.system(size: 46, weight: .bold, design: .rounded))
                            .foregroundStyle(amountString.isEmpty ? .secondary : .primary)
                            .lineLimit(1)
                            .minimumScaleFactor(0.5)
                        
                        Text(selectedCurrency.symbol)
                            .font(.system(size: 28, weight: .semibold, design: .rounded))
                            .foregroundStyle(.secondary)
                    }
                    .frame(height: 54)
                    
                    // Conversion hint if different currency
                    if isDifferentCurrency && numericAmount > 0 {
                        Text("≈ " + BudgetCalculator.formatAmount(convertedAmountPreview, currency: settings.baseCurrency))
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                }
                .padding(.bottom, 10)
                .background(Color(.secondarySystemBackground))
                
                Divider()
                
                // MARK: - Category Grid & Keypad
                ScrollView {
                    VStack(spacing: 16) {
                        // Category Selection Grid
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Catégorie")
                                .font(.caption)
                                .fontWeight(.semibold)
                                .foregroundStyle(.secondary)
                                .padding(.horizontal)
                            
                            LazyVGrid(columns: [GridItem(.adaptive(minimum: 100), spacing: 8)], spacing: 8) {
                                ForEach(sortedCategories) { cat in
                                    let isSelected = selectedCategory?.id == cat.id
                                    Button {
                                        Haptics.playLight()
                                        selectedCategory = cat
                                    } label: {
                                        VStack(spacing: 6) {
                                            ZStack {
                                                Circle()
                                                    .fill(Color(hex: cat.colorHex).opacity(isSelected ? 1.0 : 0.15))
                                                    .frame(width: 40, height: 40)
                                                Image(systemName: cat.icon)
                                                    .font(.system(size: 16, weight: .bold))
                                                    .foregroundStyle(isSelected ? .white : Color(hex: cat.colorHex))
                                            }
                                            
                                            Text(cat.name)
                                                .font(.caption2)
                                                .fontWeight(isSelected ? .bold : .medium)
                                                .foregroundStyle(isSelected ? Color.primary : Color.secondary)
                                                .lineLimit(1)
                                        }
                                        .frame(maxWidth: .infinity)
                                        .padding(.vertical, 10)
                                        .padding(.horizontal, 6)
                                        .background(isSelected ? Color(hex: cat.colorHex).opacity(0.12) : Color(.secondarySystemBackground))
                                        .overlay(
                                            RoundedRectangle(cornerRadius: 12)
                                                .stroke(isSelected ? Color(hex: cat.colorHex) : Color.clear, lineWidth: 2)
                                        )
                                        .clipShape(RoundedRectangle(cornerRadius: 12))
                                    }
                                    .buttonStyle(.plain)
                                }
                            }
                            .padding(.horizontal)
                        }
                        
                        // Optional Note Field
                        HStack {
                            Image(systemName: "note.text")
                                .foregroundStyle(.secondary)
                            TextField("Note optionnelle (ex: Déjeuner avec Thomas)", text: $note)
                                .font(.subheadline)
                        }
                        .padding(12)
                        .background(Color(.secondarySystemBackground))
                        .clipShape(RoundedRectangle(cornerRadius: 10))
                        .padding(.horizontal)
                        
                        // Custom Keypad for immediate taps
                        CustomNumericKeypad(
                            amountString: $amountString,
                            onCommit: saveExpense
                        )
                        .padding(.horizontal)
                    }
                    .padding(.vertical, 12)
                }
            }
            .navigationTitle("Nouvelle dépense")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Annuler") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .confirmationAction) {
                    Button("Enregistrer") {
                        saveExpense()
                    }
                    .fontWeight(.bold)
                    .disabled(numericAmount <= 0)
                }
            }
            .sheet(isPresented: $showDatePicker) {
                NavigationStack {
                    DatePicker("Date de la dépense", selection: $selectedDate, displayedComponents: [.date])
                        .datePickerStyle(.graphical)
                        .padding()
                        .navigationTitle("Sélectionner une date")
                        .navigationBarTitleDisplayMode(.inline)
                        .toolbar {
                            ToolbarItem(placement: .confirmationAction) {
                                Button("OK") {
                                    showDatePicker = false
                                }
                            }
                        }
                }
                .presentationDetents([.medium])
            }
        }
    }
    
    private var formattedSelectedDate: String {
        let calendar = Calendar.current
        if calendar.isDateInToday(selectedDate) {
            return "Aujourd'hui"
        } else if calendar.isDateInYesterday(selectedDate) {
            return "Hier"
        } else {
            let formatter = DateFormatter()
            formatter.locale = Locale(identifier: "fr_FR")
            formatter.dateFormat = "d MMM"
            return formatter.string(from: selectedDate)
        }
    }
    
    private func saveExpense() {
        guard numericAmount > 0 else { return }
        
        let rateToUse = settings.eurSekRate
        let baseAmount = BudgetCalculator.convert(
            amount: numericAmount,
            from: selectedCurrency,
            to: settings.baseCurrency,
            rate: rateToUse
        )
        
        let transaction = Transaction(
            date: selectedDate,
            originalAmount: numericAmount,
            originalCurrency: selectedCurrency,
            rateUsed: rateToUse,
            baseAmount: baseAmount,
            categoryID: selectedCategory?.id,
            note: note.trimmingCharacters(in: .whitespacesAndNewlines)
        )
        
        modelContext.insert(transaction)
        try? modelContext.save()
        Haptics.playSuccess()
        dismiss()
    }
}

// MARK: - Custom Compact Keypad

struct CustomNumericKeypad: View {
    @Binding var amountString: String
    let onCommit: () -> Void
    
    private let rows = [
        ["1", "2", "3"],
        ["4", "5", "6"],
        ["7", "8", "9"],
        [",", "0", "delete.left"]
    ]
    
    var body: some View {
        VStack(spacing: 8) {
            ForEach(rows, id: \.self) { row in
                HStack(spacing: 8) {
                    ForEach(row, id: \.self) { key in
                        Button {
                            handleKey(key)
                        } label: {
                            ZStack {
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(Color(.secondarySystemBackground))
                                    .frame(height: 50)
                                
                                if key == "delete.left" {
                                    Image(systemName: "delete.backward.fill")
                                        .font(.title3)
                                        .foregroundStyle(.secondary)
                                } else {
                                    Text(key)
                                        .font(.title2)
                                        .fontWeight(.semibold)
                                        .foregroundStyle(.primary)
                                }
                            }
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
        }
    }
    
    private func handleKey(_ key: String) {
        Haptics.playLight()
        if key == "delete.left" {
            if !amountString.isEmpty {
                amountString.removeLast()
            }
        } else if key == "," {
            if !amountString.contains(",") && !amountString.isEmpty {
                amountString.append(",")
            } else if amountString.isEmpty {
                amountString = "0,"
            }
        } else {
            // Check decimal limit: max 2 decimal digits
            if let commaIndex = amountString.firstIndex(of: ",") {
                let decimals = amountString[amountString.index(after: commaIndex)...]
                if decimals.count >= 2 {
                    return // do not allow 3rd decimal
                }
            }
            if amountString == "0" {
                amountString = key
            } else {
                amountString.append(key)
            }
        }
    }
}
