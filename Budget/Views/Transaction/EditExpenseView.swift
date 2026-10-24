import SwiftUI
import SwiftData

public struct EditExpenseView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    
    let transaction: Transaction
    let settings: UserSettings
    let categories: [BudgetCategory]
    
    @State private var amountString: String
    @State private var selectedCurrency: Currency
    @State private var selectedCategoryID: UUID?
    @State private var selectedDate: Date
    @State private var note: String
    @State private var showDeleteConfirmation: Bool = false
    
    public init(transaction: Transaction, settings: UserSettings, categories: [BudgetCategory]) {
        self.transaction = transaction
        self.settings = settings
        self.categories = categories
        
        _amountString = State(initialValue: "\(transaction.originalAmount)")
        _selectedCurrency = State(initialValue: transaction.originalCurrency)
        _selectedCategoryID = State(initialValue: transaction.categoryID)
        _selectedDate = State(initialValue: transaction.date)
        _note = State(initialValue: transaction.note)
    }
    
    private var numericAmount: Decimal {
        let cleaned = amountString.replacingOccurrences(of: ",", with: ".")
        return Decimal(string: cleaned) ?? 0
    }
    
    public var body: some View {
        NavigationStack {
            Form {
                Section("Montant & Devise") {
                    HStack {
                        TextField("Montant", text: $amountString)
                            .keyboardType(.decimalPad)
                            .font(.title3)
                            .fontWeight(.bold)
                        
                        Picker("Devise", selection: $selectedCurrency) {
                            ForEach(Currency.allCases) { curr in
                                Text(curr.symbol).tag(curr)
                            }
                        }
                        .pickerStyle(.segmented)
                        .frame(width: 120)
                    }
                }
                
                Section("Catégorie") {
                    Picker("Catégorie", selection: $selectedCategoryID) {
                        Text("Aucune").tag(UUID?.none)
                        ForEach(categories) { cat in
                            Label(cat.name, systemImage: cat.icon)
                                .tag(UUID?.some(cat.id))
                        }
                    }
                }
                
                Section("Détails") {
                    DatePicker("Date", selection: $selectedDate, displayedComponents: [.date])
                    
                    TextField("Note optionnelle", text: $note)
                }
                
                Section("Informations de conversion") {
                    HStack {
                        Text("Taux appliqué à l'origine")
                        Spacer()
                        Text(verbatim: "1 € = \(transaction.rateUsed) SEK")
                            .foregroundStyle(.secondary)
                    }
                    HStack {
                        Text("Montant en devise de référence")
                        Spacer()
                        Text(BudgetCalculator.formatAmount(transaction.baseAmount, currency: settings.baseCurrency))
                            .fontWeight(.semibold)
                    }
                }
                
                Section {
                    Button(role: .destructive) {
                        showDeleteConfirmation = true
                    } label: {
                        Label("Supprimer cette dépense", systemImage: "trash")
                            .foregroundStyle(.red)
                    }
                }
            }
            .navigationTitle("Modifier la dépense")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Annuler") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .confirmationAction) {
                    Button("Enregistrer") {
                        saveChanges()
                    }
                    .fontWeight(.bold)
                    .disabled(numericAmount <= 0)
                }
            }
            .confirmationDialog(
                "Supprimer cette dépense ?",
                isPresented: $showDeleteConfirmation,
                titleVisibility: .visible
            ) {
                Button("Supprimer", role: .destructive) {
                    deleteTransaction()
                }
                Button("Annuler", role: .cancel) {}
            }
        }
    }
    
    private func saveChanges() {
        guard numericAmount > 0 else { return }
        
        transaction.originalAmount = numericAmount
        transaction.originalCurrency = selectedCurrency
        transaction.categoryID = selectedCategoryID
        transaction.date = selectedDate
        transaction.note = note.trimmingCharacters(in: .whitespacesAndNewlines)
        
        // Recalculate baseAmount using the stored rateUsed (preserving original rate as required)
        transaction.baseAmount = BudgetCalculator.convert(
            amount: numericAmount,
            from: selectedCurrency,
            to: settings.baseCurrency,
            rate: transaction.rateUsed
        )
        
        try? modelContext.save()
        Haptics.playSuccess()
        dismiss()
    }
    
    private func deleteTransaction() {
        modelContext.delete(transaction)
        try? modelContext.save()
        Haptics.playMedium()
        dismiss()
    }
}
