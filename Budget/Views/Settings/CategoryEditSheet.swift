import SwiftUI
import SwiftData

public struct CategoryEditSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    
    var existingCategory: BudgetCategory?
    let baseCurrency: Currency
    
    @State private var name: String
    @State private var icon: String
    @State private var colorHex: String
    @State private var selectedType: CategoryType
    @State private var capString: String
    
    private let availableIcons = [
        "cart.fill", "fork.knife", "wineglass.fill", "bag.fill",
        "tram.fill", "car.fill", "airplane", "fuelpump.fill",
        "house.fill", "bolt.fill", "phone.fill", "cross.case.fill",
        "tv.fill", "gamecontroller.fill", "gift.fill", "tag.fill",
        "globe", "cup.and.saucer.fill", "bed.double.fill", "shield.fill"
    ]
    
    private let availableColors = [
        "#34C759", "#007AFF", "#FF9500", "#AF52DE",
        "#FF2D55", "#5856D6", "#00C7BE", "#64D2FF",
        "#FF3B30", "#FFCC00", "#5AC8FA"
    ]
    
    public init(existingCategory: BudgetCategory? = nil, baseCurrency: Currency = .EUR) {
        self.existingCategory = existingCategory
        self.baseCurrency = baseCurrency
        
        _name = State(initialValue: existingCategory?.name ?? "")
        _icon = State(initialValue: existingCategory?.icon ?? "tag.fill")
        _colorHex = State(initialValue: existingCategory?.colorHex ?? "#34C759")
        _selectedType = State(initialValue: existingCategory?.type ?? .variable)
        _capString = State(initialValue: existingCategory?.monthlyCap != nil ? "\(existingCategory!.monthlyCap!)" : "")
    }
    
    private var numericCap: Decimal? {
        let cleaned = capString.replacingOccurrences(of: ",", with: ".")
        guard !cleaned.isEmpty, let value = Decimal(string: cleaned), value > 0 else {
            return nil
        }
        return value
    }
    
    public var body: some View {
        NavigationStack {
            Form {
                Section("Détails de la catégorie") {
                    TextField("Nom de la catégorie", text: $name)
                    
                    Picker("Type de catégorie", selection: $selectedType) {
                        ForEach(CategoryType.allCases) { type in
                            Text(type.title).tag(type)
                        }
                    }
                    
                    Text(selectedType.description)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                
                Section(header: Text(capSectionTitle)) {
                    HStack {
                        TextField("Montant (ex: 150)", text: $capString)
                            .keyboardType(.decimalPad)
                        Text(baseCurrency.symbol)
                            .foregroundStyle(.secondary)
                    }
                    Text(capSectionFooter)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                
                Section("Icône") {
                    LazyVGrid(columns: [GridItem(.adaptive(minimum: 44))], spacing: 10) {
                        ForEach(availableIcons, id: \.self) { sym in
                            Button {
                                Haptics.playLight()
                                icon = sym
                            } label: {
                                ZStack {
                                    Circle()
                                        .fill(icon == sym ? Color(hex: colorHex).opacity(0.2) : Color(.tertiarySystemFill))
                                        .frame(width: 44, height: 44)
                                    Image(systemName: sym)
                                        .font(.system(size: 20))
                                        .foregroundStyle(icon == sym ? Color(hex: colorHex) : Color.primary)
                                }
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding(.vertical, 4)
                }
                
                Section("Couleur") {
                    LazyVGrid(columns: [GridItem(.adaptive(minimum: 38))], spacing: 10) {
                        ForEach(availableColors, id: \.self) { hex in
                            Button {
                                Haptics.playLight()
                                colorHex = hex
                            } label: {
                                ZStack {
                                    Circle()
                                        .fill(Color(hex: hex))
                                        .frame(width: 36, height: 36)
                                    if colorHex == hex {
                                        Image(systemName: "checkmark")
                                            .font(.footnote)
                                            .fontWeight(.bold)
                                            .foregroundStyle(.white)
                                    }
                                }
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding(.vertical, 4)
                }
            }
            .navigationTitle(existingCategory == nil ? "Nouvelle catégorie" : "Modifier la catégorie")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Annuler") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .confirmationAction) {
                    Button("Enregistrer") {
                        save()
                    }
                    .fontWeight(.bold)
                    .disabled(name.trimmingCharacters(in: .whitespaces).isEmpty)
                }
            }
        }
    }
    
    private var capSectionTitle: String {
        switch selectedType {
        case .variable: return "Plafond mensuel (optionnel)"
        case .fixed: return "Montant fixe du cycle"
        case .smoothed: return "Montant lissé réservé par cycle"
        }
    }
    
    private var capSectionFooter: String {
        switch selectedType {
        case .variable:
            return "Une barre de progression s'affichera sur l'accueil pour suivre les dépenses de cette catégorie."
        case .fixed:
            return "Ce montant est déduit de votre budget variable dès le début du cycle."
        case .smoothed:
            return "Exemple : Pour un billet de 120 € dans 3 mois, allouez 40 € chaque cycle."
        }
    }
    
    private func save() {
        let trimmedName = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedName.isEmpty else { return }
        
        if let existing = existingCategory {
            existing.name = trimmedName
            existing.icon = icon
            existing.colorHex = colorHex
            existing.type = selectedType
            existing.monthlyCap = numericCap
        } else {
            let newCat = BudgetCategory(
                name: trimmedName,
                icon: icon,
                colorHex: colorHex,
                type: selectedType,
                monthlyCap: numericCap,
                order: 99
            )
            modelContext.insert(newCat)
        }
        
        try? modelContext.save()
        Haptics.playSuccess()
        dismiss()
    }
}
