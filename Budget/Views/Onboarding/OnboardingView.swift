import SwiftUI
import SwiftData

public struct OnboardingView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var settingsList: [UserSettings]
    @Query private var categories: [BudgetCategory]
    
    @State private var baseCurrency: Currency = .EUR
    @State private var initialBalanceString: String = "1500"
    @State private var salaryString: String = "2500"
    @State private var paydayDay: Int = 25
    @State private var savingsGoalString: String = "400"
    @State private var rateString: String = "11.12"
    
    public var onComplete: () -> Void
    
    public var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    // Header
                    VStack(spacing: 10) {
                        Image(systemName: "wallet.pass.fill")
                            .font(.system(size: 54))
                            .foregroundStyle(Color.accentColor)
                        
                        Text("Bienvenue sur Budget")
                            .font(.largeTitle)
                            .fontWeight(.bold)
                            .multilineTextAlignment(.center)
                        
                        Text("Sachez en un coup d'œil combien vous pouvez dépenser sans compromettre votre épargne.")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal)
                    }
                    .padding(.top, 16)
                    
                    // Step 1: Reference Currency
                    VStack(alignment: .leading, spacing: 10) {
                        Label("1. Devise de référence", systemImage: "eurosign.circle.fill")
                            .font(.headline)
                        
                        Picker("Devise de référence", selection: $baseCurrency) {
                            ForEach(Currency.allCases) { curr in
                                Text(curr.displayName).tag(curr)
                            }
                        }
                        .pickerStyle(.segmented)
                        
                        Text("Par défaut en EUR (idéal pour compte N26). Toutes vos métriques seront calculées dans cette devise.")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    .padding(16)
                    .background(Color(.secondarySystemBackground))
                    .clipShape(RoundedRectangle(cornerRadius: 16))
                    .padding(.horizontal)
                    
                    // Step 2: Account balance anchor
                    VStack(alignment: .leading, spacing: 10) {
                        Label("2. Solde actuel du compte", systemImage: "banknote.fill")
                            .font(.headline)
                        
                        HStack {
                            TextField("Ex: 1500", text: $initialBalanceString)
                                .keyboardType(.decimalPad)
                                .font(.title3.weight(.bold))
                            Text(baseCurrency.symbol)
                                .foregroundStyle(.secondary)
                                .font(.title3.weight(.semibold))
                        }
                        .padding(10)
                        .background(Color(.tertiarySystemFill))
                        .clipShape(RoundedRectangle(cornerRadius: 10))
                        
                        Text("Votre point d'ancrage pour estimer l'évolution de votre solde bancaire.")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    .padding(16)
                    .background(Color(.secondarySystemBackground))
                    .clipShape(RoundedRectangle(cornerRadius: 16))
                    .padding(.horizontal)
                    
                    // Step 3: Salary & Payday
                    VStack(alignment: .leading, spacing: 12) {
                        Label("3. Salaire net & Jour de paie", systemImage: "calendar.badge.clock")
                            .font(.headline)
                        
                        HStack {
                            Text("Salaire net :")
                                .font(.subheadline)
                            Spacer()
                            TextField("Ex: 2500", text: $salaryString)
                                .keyboardType(.decimalPad)
                                .multilineTextAlignment(.trailing)
                                .font(.body.weight(.bold))
                                .frame(maxWidth: 100)
                            Text(baseCurrency.symbol)
                                .foregroundStyle(.secondary)
                        }
                        .padding(10)
                        .background(Color(.tertiarySystemFill))
                        .clipShape(RoundedRectangle(cornerRadius: 10))
                        
                        HStack {
                            Text("Jour de paie :")
                                .font(.subheadline)
                            Spacer()
                            Picker("Jour", selection: $paydayDay) {
                                ForEach(1...31, id: \.self) { day in
                                    Text("Le \(day)").tag(day)
                                }
                            }
                            .tint(.primary)
                        }
                        .padding(8)
                        .background(Color(.tertiarySystemFill))
                        .clipShape(RoundedRectangle(cornerRadius: 10))
                        
                        Text("Votre cycle budgétaire court de paie à paie (ex: du 25 au 24 du mois suivant).")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    .padding(16)
                    .background(Color(.secondarySystemBackground))
                    .clipShape(RoundedRectangle(cornerRadius: 16))
                    .padding(.horizontal)
                    
                    // Step 4: Savings goal
                    VStack(alignment: .leading, spacing: 10) {
                        Label("4. Objectif d'épargne", systemImage: "target")
                            .font(.headline)
                        
                        HStack {
                            TextField("Ex: 400", text: $savingsGoalString)
                                .keyboardType(.decimalPad)
                                .font(.title3.weight(.bold))
                            Text(baseCurrency.symbol)
                                .foregroundStyle(.secondary)
                                .font(.title3.weight(.semibold))
                        }
                        .padding(10)
                        .background(Color(.tertiarySystemFill))
                        .clipShape(RoundedRectangle(cornerRadius: 10))
                        
                        Text("Montant mis de côté dès le 1er jour du cycle pour garantir votre épargne.")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    .padding(16)
                    .background(Color(.secondarySystemBackground))
                    .clipShape(RoundedRectangle(cornerRadius: 16))
                    .padding(.horizontal)
                    
                    // Step 5: Exchange rate EUR / SEK
                    VStack(alignment: .leading, spacing: 10) {
                        Label("5. Taux de change EUR/SEK fixe", systemImage: "arrow.triangle.swap")
                            .font(.headline)
                        
                        HStack {
                            Text("1 € =")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                            TextField("11.12", text: $rateString)
                                .keyboardType(.decimalPad)
                                .font(.body.weight(.bold))
                                .frame(maxWidth: 80)
                            Text("SEK")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                        }
                        .padding(10)
                        .background(Color(.tertiarySystemFill))
                        .clipShape(RoundedRectangle(cornerRadius: 10))
                        
                        Text("Aucun appel réseau. Vous pouvez saisir vos dépenses en € ou en kr sans connexion internet.")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    .padding(16)
                    .background(Color(.secondarySystemBackground))
                    .clipShape(RoundedRectangle(cornerRadius: 16))
                    .padding(.horizontal)
                    
                    // Step 6: Categories preview
                    VStack(alignment: .leading, spacing: 10) {
                        Label("6. Catégories par défaut", systemImage: "tag.fill")
                            .font(.headline)
                        
                        Text("Courses, Transport, Restaurant, Shopping, Bar, Achat en ligne, Gros transport, Choses utiles...")
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                        
                        Text("Tout est personnalisable à tout moment dans les réglages.")
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    }
                    .padding(16)
                    .background(Color(.secondarySystemBackground))
                    .clipShape(RoundedRectangle(cornerRadius: 16))
                    .padding(.horizontal)
                    
                    // Submit button
                    Button {
                        completeOnboarding()
                    } label: {
                        Text("Commencer à suivre mon budget")
                            .font(.headline)
                            .fontWeight(.bold)
                            .foregroundStyle(.white)
                            .frame(maxWidth: .infinity)
                            .frame(height: 54)
                            .background(Color.accentColor)
                            .clipShape(RoundedRectangle(cornerRadius: 16))
                            .shadow(color: Color.accentColor.opacity(0.3), radius: 8, x: 0, y: 4)
                    }
                    .padding(.horizontal)
                    .padding(.bottom, 24)
                }
            }
            .navigationBarTitleDisplayMode(.inline)
        }
    }
    
    private func completeOnboarding() {
        let cleanInit = initialBalanceString.replacingOccurrences(of: ",", with: ".")
        let cleanSalary = salaryString.replacingOccurrences(of: ",", with: ".")
        let cleanSavings = savingsGoalString.replacingOccurrences(of: ",", with: ".")
        let cleanRate = rateString.replacingOccurrences(of: ",", with: ".")
        
        let initialBal = Decimal(string: cleanInit) ?? 1500
        let salary = Decimal(string: cleanSalary) ?? 2500
        let savings = Decimal(string: cleanSavings) ?? 400
        let rate = Decimal(string: cleanRate) ?? Decimal(string: "11.12")!
        
        if let existing = settingsList.first {
            existing.baseCurrency = baseCurrency
            existing.initialBalance = initialBal
            existing.defaultSalary = salary
            existing.paydayDay = paydayDay
            existing.savingsGoal = savings
            existing.eurSekRate = rate
            existing.hasCompletedOnboarding = true
        } else {
            let newSettings = UserSettings(
                baseCurrency: baseCurrency,
                paydayDay: paydayDay,
                defaultSalary: salary,
                salaryCurrency: baseCurrency,
                savingsGoal: savings,
                buffer: 0,
                eurSekRate: rate,
                initialBalance: initialBal,
                roundToUnit: false,
                hasCompletedOnboarding: true
            )
            modelContext.insert(newSettings)
        }
        
        // Populate default categories if empty
        if categories.isEmpty {
            for defaultCat in BudgetCategory.defaults {
                modelContext.insert(defaultCat)
            }
        }
        
        try? modelContext.save()
        Haptics.playSuccess()
        onComplete()
    }
}
