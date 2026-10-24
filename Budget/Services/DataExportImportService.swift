import Foundation
import SwiftData

public struct BackupData: Codable {
    public struct SettingsDTO: Codable {
        public var baseCurrency: String
        public var paydayDay: Int
        public var defaultSalary: Decimal
        public var salaryCurrency: String
        public var savingsGoal: Decimal
        public var buffer: Decimal
        public var eurSekRate: Decimal
        public var initialBalance: Decimal
        public var roundToUnit: Bool
    }
    
    public struct CategoryDTO: Codable {
        public var id: UUID
        public var name: String
        public var icon: String
        public var colorHex: String
        public var typeRaw: String
        public var monthlyCap: Decimal?
        public var order: Int
    }
    
    public struct TransactionDTO: Codable {
        public var id: UUID
        public var date: Date
        public var originalAmount: Decimal
        public var originalCurrency: String
        public var rateUsed: Decimal
        public var baseAmount: Decimal
        public var categoryID: UUID?
        public var note: String
    }
    
    public struct IncomeDTO: Codable {
        public var id: UUID
        public var date: Date
        public var originalAmount: Decimal
        public var currency: String
        public var rateUsed: Decimal
        public var baseAmount: Decimal
        public var label: String
        public var cycleStartDate: Date
    }
    
    public struct CycleOverrideDTO: Codable {
        public var id: UUID
        public var cycleStartDate: Date
        public var salaryOverride: Decimal?
        public var customStartDate: Date?
    }
    
    public var version: Int = 1
    public var exportDate: Date = Date()
    public var settings: SettingsDTO
    public var categories: [CategoryDTO]
    public var transactions: [TransactionDTO]
    public var incomes: [IncomeDTO]
    public var overrides: [CycleOverrideDTO]
}

public struct DataExportImportService {
    
    public static func createExportJSON(
        settings: UserSettings,
        categories: [BudgetCategory],
        transactions: [Transaction],
        incomes: [Income],
        overrides: [CycleOverride]
    ) throws -> String {
        let settingsDTO = BackupData.SettingsDTO(
            baseCurrency: settings.baseCurrencyRaw,
            paydayDay: settings.paydayDay,
            defaultSalary: settings.defaultSalary,
            salaryCurrency: settings.salaryCurrencyRaw,
            savingsGoal: settings.savingsGoal,
            buffer: settings.buffer,
            eurSekRate: settings.eurSekRate,
            initialBalance: settings.initialBalance,
            roundToUnit: settings.roundToUnit
        )
        
        let categoryDTOs = categories.map {
            BackupData.CategoryDTO(
                id: $0.id,
                name: $0.name,
                icon: $0.icon,
                colorHex: $0.colorHex,
                typeRaw: $0.typeRaw,
                monthlyCap: $0.monthlyCap,
                order: $0.order
            )
        }
        
        let transactionDTOs = transactions.map {
            BackupData.TransactionDTO(
                id: $0.id,
                date: $0.date,
                originalAmount: $0.originalAmount,
                originalCurrency: $0.originalCurrencyRaw,
                rateUsed: $0.rateUsed,
                baseAmount: $0.baseAmount,
                categoryID: $0.categoryID,
                note: $0.note
            )
        }
        
        let incomeDTOs = incomes.map {
            BackupData.IncomeDTO(
                id: $0.id,
                date: $0.date,
                originalAmount: $0.originalAmount,
                currency: $0.currencyRaw,
                rateUsed: $0.rateUsed,
                baseAmount: $0.baseAmount,
                label: $0.label,
                cycleStartDate: $0.cycleStartDate
            )
        }
        
        let overrideDTOs = overrides.map {
            BackupData.CycleOverrideDTO(
                id: $0.id,
                cycleStartDate: $0.cycleStartDate,
                salaryOverride: $0.salaryOverride,
                customStartDate: $0.customStartDate
            )
        }
        
        let backup = BackupData(
            settings: settingsDTO,
            categories: categoryDTOs,
            transactions: transactionDTOs,
            incomes: incomeDTOs,
            overrides: overrideDTOs
        )
        
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        encoder.dateEncodingStrategy = .iso8601
        let data = try encoder.encode(backup)
        return String(decoding: data, as: UTF8.self)
    }
    
    public static func decodeBackup(from jsonString: String) throws -> BackupData {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        guard let data = jsonString.data(using: .utf8) else {
            throw NSError(domain: "DataExportImportService", code: -1, userInfo: [NSLocalizedDescriptionKey: "Format de texte JSON invalide."])
        }
        return try decoder.decode(BackupData.self, from: data)
    }
}
