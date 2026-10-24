import SwiftUI
import SwiftData

public struct DataBackupView: View {
    @Environment(\.modelContext) private var modelContext
    
    let settings: UserSettings
    let categories: [BudgetCategory]
    let transactions: [Transaction]
    let incomes: [Income]
    let overrides: [CycleOverride]
    
    @State private var exportText: String = ""
    @State private var importText: String = ""
    @State private var alertMessage: String?
    @State private var showAlert: Bool = false
    @State private var showConfirmImport: Bool = false
    
    public var body: some View {
        Form {
            Section("Sauvegarde des données (Export)") {
                Text("Exportez l'intégralité de vos dépenses, catégories et réglages au format JSON pour les conserver ou les transférer.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                
                Button {
                    generateExport()
                } label: {
                    Label("Générer l'export JSON", systemImage: "arrow.up.doc.fill")
                }
                
                if !exportText.isEmpty {
                    ShareLink(
                        item: exportText,
                        preview: SharePreview("Budget_Sauvegarde_\(Date().formatted(date: .numeric, time: .omitted)).json")
                    ) {
                        Label("Partager / Sauvegarder le fichier", systemImage: "square.and.arrow.up")
                    }
                }
            }
            
            Section("Restauration des données (Import)") {
                Text("Collez ci-dessous le contenu JSON d'une sauvegarde précédente.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                
                TextEditor(text: $importText)
                    .frame(height: 120)
                    .font(.caption.monospaced())
                
                Button(role: .destructive) {
                    showConfirmImport = true
                } label: {
                    Label("Restaurer ces données", systemImage: "arrow.down.doc.fill")
                }
                .disabled(importText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
            }
        }
        .navigationTitle("Sauvegarde & Restauration")
        .alert("Information", isPresented: $showAlert) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(alertMessage ?? "")
        }
        .confirmationDialog(
            "Confirmer la restauration",
            isPresented: $showConfirmImport,
            titleVisibility: .visible
        ) {
            Button("Restaurer (écrase les données actuelles)", role: .destructive) {
                performImport()
            }
            Button("Annuler", role: .cancel) {}
        } message: {
            Text("Attention : Toutes les données existantes seront remplacées par celles de la sauvegarde.")
        }
    }
    
    private func generateExport() {
        do {
            let json = try DataExportImportService.createExportJSON(
                settings: settings,
                categories: categories,
                transactions: transactions,
                incomes: incomes,
                overrides: overrides
            )
            exportText = json
            UIPasteboard.general.string = json
            alertMessage = "Sauvegarde générée avec succès et copiée dans le presse-papier !"
            showAlert = true
            Haptics.playSuccess()
        } catch {
            alertMessage = "Erreur lors de la création de la sauvegarde : \(error.localizedDescription)"
            showAlert = true
        }
    }
    
    private func performImport() {
        do {
            let backup = try DataExportImportService.decodeBackup(from: importText)
            
            // Delete current data
            for cat in categories { modelContext.delete(cat) }
            for tx in transactions { modelContext.delete(tx) }
            for inc in incomes { modelContext.delete(inc) }
            for ov in overrides { modelContext.delete(ov) }
            
            // Restore settings
            settings.baseCurrencyRaw = backup.settings.baseCurrency
            settings.paydayDay = backup.settings.paydayDay
            settings.defaultSalary = backup.settings.defaultSalary
            settings.salaryCurrencyRaw = backup.settings.salaryCurrency
            settings.savingsGoal = backup.settings.savingsGoal
            settings.buffer = backup.settings.buffer
            settings.eurSekRate = backup.settings.eurSekRate
            settings.initialBalance = backup.settings.initialBalance
            settings.roundToUnit = backup.settings.roundToUnit
            
            // Restore categories
            for catDTO in backup.categories {
                let cat = BudgetCategory(
                    id: catDTO.id,
                    name: catDTO.name,
                    icon: catDTO.icon,
                    colorHex: catDTO.colorHex,
                    type: CategoryType(rawValue: catDTO.typeRaw) ?? .variable,
                    monthlyCap: catDTO.monthlyCap,
                    order: catDTO.order
                )
                modelContext.insert(cat)
            }
            
            // Restore transactions
            for txDTO in backup.transactions {
                let tx = Transaction(
                    id: txDTO.id,
                    date: txDTO.date,
                    originalAmount: txDTO.originalAmount,
                    originalCurrency: Currency(rawValue: txDTO.originalCurrency) ?? .EUR,
                    rateUsed: txDTO.rateUsed,
                    baseAmount: txDTO.baseAmount,
                    categoryID: txDTO.categoryID,
                    note: txDTO.note
                )
                modelContext.insert(tx)
            }
            
            // Restore incomes
            for incDTO in backup.incomes {
                let inc = Income(
                    id: incDTO.id,
                    date: incDTO.date,
                    originalAmount: incDTO.originalAmount,
                    currency: Currency(rawValue: incDTO.currency) ?? .EUR,
                    rateUsed: incDTO.rateUsed,
                    baseAmount: incDTO.baseAmount,
                    label: incDTO.label,
                    cycleStartDate: incDTO.cycleStartDate
                )
                modelContext.insert(inc)
            }
            
            // Restore overrides
            for ovDTO in backup.overrides {
                let ov = CycleOverride(
                    id: ovDTO.id,
                    cycleStartDate: ovDTO.cycleStartDate,
                    salaryOverride: ovDTO.salaryOverride,
                    customStartDate: ovDTO.customStartDate
                )
                modelContext.insert(ov)
            }
            
            try modelContext.save()
            importText = ""
            alertMessage = "Les données ont été restaurées avec succès !"
            showAlert = true
            Haptics.playSuccess()
        } catch {
            alertMessage = "Erreur de restauration : vérifiez le format JSON."
            showAlert = true
        }
    }
}
