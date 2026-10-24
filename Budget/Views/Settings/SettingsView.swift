import SwiftUI
import SwiftData

public struct SettingsView: View {
    @Environment(\.modelContext) private var modelContext
    
    @Query private var settingsList: [UserSettings]
    @Query private var categories: [BudgetCategory]
    @Query private var transactions: [Transaction]
    @Query private var incomes: [Income]
    @Query private var overrides: [CycleOverride]
    
    @State private var salaryString: String = ""
    @State private var savingsGoalString: String = ""
    @State private var bufferString: String = ""
    @State private var rateString: String = ""
    @State private var initialBalanceString: String = ""
    @State private var showConfirmStartCycleNow: Bool = false
    @State private var feedbackNotice: String?
    @State private var showNoticeAlert: Bool = false
    
    private var settings: UserSettings {
        settingsList.first ?? UserSettings()
    }
    
    private var currentCycle: CyclePeriod {
        BudgetCalculator.cycleForDate(Date(), payday: settings.paydayDay, overrides: overrides)
    }
    
    private var cycleOverride: CycleOverride? {
        overrides.first { Calendar.current.isDate($0.cycleStartDate, inSameDayAs: currentCycle.startDate) }
    }
    
    public var body: some View {
        NavigationStack {
            Form {
                // MARK: - Cycle & Rémunération
                Section {
                    HStack {
                        Text("Salaire net du cycle")
                        Spacer()
                        TextField("Montant", text: $salaryString)
                            .keyboardType(.decimalPad)
                            .multilineTextAlignment(.trailing)
                            .font(.body.weight(.semibold))
                            .frame(maxWidth: 120)
                            .onChange(of: salaryString) { _, newValue in
                                updateSalary(newValue)
                            }
                        Text(settings.baseCurrency.symbol)
                            .foregroundStyle(.secondary)
                    }
                    
                    Picker("Jour de paie", selection: Binding(
                        get: { settings.paydayDay },
                        set: { newDay in
                            settings.paydayDay = newDay
                            try? modelContext.save()
                        }
                    )) {
                        ForEach(1...31, id: \.self) { day in
                            Text("Le \(day) du mois").tag(day)
                        }
                    }
                    
                    Button {
                        showConfirmStartCycleNow = true
                    } label: {
                        Label("Démarrer le nouveau cycle aujourd'hui", systemImage: "arrow.clockwise.circle.fill")
                            .font(.subheadline)
                    }
                } header: {
                    Text("Cycle de paie")
                } footer: {
                    Text("Cycle actuel : du \(currentCycle.shortDescription). Modifier le salaire recalcule immédiatement ce cycle.")
                }
                
                // MARK: - Objectifs
                Section("Objectifs budgétaires") {
                    HStack {
                        Text("Objectif d'épargne")
                        Spacer()
                        TextField("Montant", text: $savingsGoalString)
                            .keyboardType(.decimalPad)
                            .multilineTextAlignment(.trailing)
                            .font(.body.weight(.semibold))
                            .frame(maxWidth: 120)
                            .onChange(of: savingsGoalString) { _, newValue in
                                updateSavingsGoal(newValue)
                            }
                        Text(settings.baseCurrency.symbol)
                            .foregroundStyle(.secondary)
                    }
                    
                    HStack {
                        Text("Tampon d'imprévus")
                        Spacer()
                        TextField("0", text: $bufferString)
                            .keyboardType(.decimalPad)
                            .multilineTextAlignment(.trailing)
                            .font(.body.weight(.semibold))
                            .frame(maxWidth: 120)
                            .onChange(of: bufferString) { _, newValue in
                                updateBuffer(newValue)
                            }
                        Text(settings.baseCurrency.symbol)
                            .foregroundStyle(.secondary)
                    }
                }
                
                // MARK: - Devises & Taux
                Section("Devises & Taux fixe") {
                    Picker("Devise de référence", selection: Binding(
                        get: { settings.baseCurrency },
                        set: { newCurr in
                            settings.baseCurrency = newCurr
                            try? modelContext.save()
                        }
                    )) {
                        ForEach(Currency.allCases) { curr in
                            Text(curr.displayName).tag(curr)
                        }
                    }
                    
                    HStack {
                        Text("Taux de change fixe")
                        Spacer()
                        Text("1 € =")
                            .foregroundStyle(.secondary)
                        TextField("11.12", text: $rateString)
                            .keyboardType(.decimalPad)
                            .multilineTextAlignment(.trailing)
                            .font(.body.weight(.semibold))
                            .frame(maxWidth: 70)
                            .onChange(of: rateString) { _, newValue in
                                updateRate(newValue)
                            }
                        Text("SEK")
                            .foregroundStyle(.secondary)
                    }
                }
                
                // MARK: - Solde initial
                Section {
                    HStack {
                        Text("Solde initial (point d'ancrage)")
                        Spacer()
                        TextField("Solde", text: $initialBalanceString)
                            .keyboardType(.decimalPad)
                            .multilineTextAlignment(.trailing)
                            .font(.body.weight(.semibold))
                            .frame(maxWidth: 120)
                            .onChange(of: initialBalanceString) { _, newValue in
                                updateInitialBalance(newValue)
                            }
                        Text(settings.baseCurrency.symbol)
                            .foregroundStyle(.secondary)
                    }
                } header: {
                    Text("Solde du compte")
                } footer: {
                    Text("Sert de point de départ pour calculer votre solde bancaire projeté.")
                }
                
                // MARK: - Affichage
                Section("Affichage") {
                    Toggle("Arrondir à l'unité sur l'accueil", isOn: Binding(
                        get: { settings.roundToUnit },
                        set: {
                            settings.roundToUnit = $0
                            try? modelContext.save()
                        }
                    ))
                }
                
                // MARK: - Catégories & Données
                Section("Organisation & Données") {
                    NavigationLink {
                        CategoryManagementView(baseCurrency: settings.baseCurrency)
                    } label: {
                        Label("Gérer les catégories", systemImage: "folder.fill")
                    }
                    
                    NavigationLink {
                        DataBackupView(
                            settings: settings,
                            categories: categories,
                            transactions: transactions,
                            incomes: incomes,
                            overrides: overrides
                        )
                    } label: {
                        Label("Sauvegarde et Export JSON", systemImage: "arrow.triangle.2.circlepath.doc.on.clipboard")
                    }
                }
                
                // MARK: - À propos
                Section("À propos") {
                    HStack {
                        Text("Application")
                        Spacer()
                        Text("Budget 1.0.0")
                            .foregroundStyle(.secondary)
                    }
                    HStack {
                        Text("Stockage")
                        Spacer()
                        Text("Local & Privé (SwiftData)")
                            .foregroundStyle(.secondary)
                    }
                }
            }
            .navigationTitle("Réglages")
            .onAppear {
                loadInitialValues()
            }
            .confirmationDialog(
                "Démarrer le nouveau cycle aujourd'hui ?",
                isPresented: $showConfirmStartCycleNow,
                titleVisibility: .visible
            ) {
                Button("Démarrer aujourd'hui") {
                    startCycleToday()
                }
                Button("Annuler", role: .cancel) {}
            } message: {
                Text("Utile si votre salaire a été versé en avance (week-end ou jour férié). Le cycle en cours se clôturera hier.")
            }
            .alert("Information", isPresented: $showNoticeAlert) {
                Button("OK", role: .cancel) {}
            } message: {
                Text(feedbackNotice ?? "")
            }
        }
    }
    
    private func loadInitialValues() {
        let currentEffectiveSalary = cycleOverride?.salaryOverride ?? settings.defaultSalary
        salaryString = "\(currentEffectiveSalary)"
        savingsGoalString = "\(settings.savingsGoal)"
        bufferString = "\(settings.buffer)"
        rateString = "\(settings.eurSekRate)"
        initialBalanceString = "\(settings.initialBalance)"
    }
    
    private func updateSalary(_ text: String) {
        let cleaned = text.replacingOccurrences(of: ",", with: ".")
        guard let val = Decimal(string: cleaned) else { return }
        
        settings.defaultSalary = val
        if let overrideObj = cycleOverride {
            overrideObj.salaryOverride = val
        } else {
            let newOverride = CycleOverride(
                cycleStartDate: currentCycle.startDate,
                salaryOverride: val
            )
            modelContext.insert(newOverride)
        }
        try? modelContext.save()
    }
    
    private func updateSavingsGoal(_ text: String) {
        let cleaned = text.replacingOccurrences(of: ",", with: ".")
        guard let val = Decimal(string: cleaned) else { return }
        settings.savingsGoal = val
        try? modelContext.save()
    }
    
    private func updateBuffer(_ text: String) {
        let cleaned = text.replacingOccurrences(of: ",", with: ".")
        guard let val = Decimal(string: cleaned) else { return }
        settings.buffer = val
        try? modelContext.save()
    }
    
    private func updateRate(_ text: String) {
        let cleaned = text.replacingOccurrences(of: ",", with: ".")
        guard let val = Decimal(string: cleaned), val > 0 else { return }
        settings.eurSekRate = val
        try? modelContext.save()
    }
    
    private func updateInitialBalance(_ text: String) {
        let cleaned = text.replacingOccurrences(of: ",", with: ".")
        guard let val = Decimal(string: cleaned) else { return }
        settings.initialBalance = val
        try? modelContext.save()
    }
    
    private func startCycleToday() {
        let today = Calendar.current.startOfDay(for: Date())
        let newOverride = CycleOverride(
            cycleStartDate: currentCycle.startDate,
            salaryOverride: settings.defaultSalary,
            customStartDate: today
        )
        modelContext.insert(newOverride)
        try? modelContext.save()
        
        feedbackNotice = "Le cycle a bien été démarré à la date d'aujourd'hui !"
        showNoticeAlert = true
        Haptics.playSuccess()
    }
}
