import Foundation

public struct BudgetCalculator {
    
    // MARK: - Days Clamping & Calendar Helpers
    
    public static func numberOfDaysInMonth(year: Int, month: Int, calendar: Calendar = .current) -> Int {
        var components = DateComponents()
        components.year = year
        components.month = month
        components.day = 1
        
        guard let date = calendar.date(from: components),
              let range = calendar.range(of: .day, in: .month, for: date) else {
            return 30
        }
        return range.count
    }
    
    public static func clampedPayday(year: Int, month: Int, desiredPayday: Int, calendar: Calendar = .current) -> Int {
        let maxDays = numberOfDaysInMonth(year: year, month: month, calendar: calendar)
        return min(max(desiredPayday, 1), maxDays)
    }
    
    // MARK: - Cycle Calculation
    
    public static func cycleForDate(
        _ date: Date,
        payday: Int,
        overrides: [CycleOverride] = [],
        calendar: Calendar = .current
    ) -> CyclePeriod {
        let year = calendar.component(.year, from: date)
        let month = calendar.component(.month, from: date)
        let day = calendar.component(.day, from: date)
        
        let paydayThisMonth = clampedPayday(year: year, month: month, desiredPayday: payday, calendar: calendar)
        
        let startYear: Int
        let startMonth: Int
        let startDay: Int
        
        let nextYear: Int
        let nextMonth: Int
        let nextDay: Int
        
        if day >= paydayThisMonth {
            // We are in the cycle that started this month
            startYear = year
            startMonth = month
            startDay = paydayThisMonth
            
            // Next cycle starts next month
            if month == 12 {
                nextYear = year + 1
                nextMonth = 1
            } else {
                nextYear = year
                nextMonth = month + 1
            }
            nextDay = clampedPayday(year: nextYear, month: nextMonth, desiredPayday: payday, calendar: calendar)
        } else {
            // We are in the cycle that started last month
            if month == 1 {
                startYear = year - 1
                startMonth = 12
            } else {
                startYear = year
                startMonth = month - 1
            }
            startDay = clampedPayday(year: startYear, month: startMonth, desiredPayday: payday, calendar: calendar)
            
            // Next cycle starts this month
            nextYear = year
            nextMonth = month
            nextDay = paydayThisMonth
        }
        
        var startComponents = DateComponents()
        startComponents.year = startYear
        startComponents.month = startMonth
        startComponents.day = startDay
        startComponents.hour = 0
        startComponents.minute = 0
        startComponents.second = 0
        
        var nextCycleComponents = DateComponents()
        nextCycleComponents.year = nextYear
        nextCycleComponents.month = nextMonth
        nextCycleComponents.day = nextDay
        nextCycleComponents.hour = 0
        nextCycleComponents.minute = 0
        nextCycleComponents.second = 0
        
        var calculatedStart = calendar.date(from: startComponents) ?? calendar.startOfDay(for: date)
        let calculatedNext = calendar.date(from: nextCycleComponents) ?? calendar.startOfDay(for: date)
        
        // Cycle ends 1 second before next cycle starts
        var calculatedEnd = calculatedNext.addingTimeInterval(-1)
        
        // Check overrides for custom cycle start
        for override in overrides {
            if let customStart = override.customStartDate {
                let overrideStart = calendar.startOfDay(for: customStart)
                // If override applies to this period
                if calendar.isDate(override.cycleStartDate, inSameDayAs: calculatedStart) {
                    calculatedStart = overrideStart
                }
            }
        }
        
        return CyclePeriod(startDate: calculatedStart, endDate: calculatedEnd, payday: payday)
    }
    
    public static func nextCycle(after cycle: CyclePeriod, calendar: Calendar = .current) -> CyclePeriod {
        let oneDayAfter = cycle.endDate.addingTimeInterval(2)
        return cycleForDate(oneDayAfter, payday: cycle.payday, overrides: [], calendar: calendar)
    }
    
    public static func previousCycle(before cycle: CyclePeriod, calendar: Calendar = .current) -> CyclePeriod {
        let oneDayBefore = cycle.startDate.addingTimeInterval(-2)
        return cycleForDate(oneDayBefore, payday: cycle.payday, overrides: [], calendar: calendar)
    }
    
    public static func recentCycles(
        count: Int,
        around date: Date = Date(),
        payday: Int,
        overrides: [CycleOverride] = [],
        calendar: Calendar = .current
    ) -> [CyclePeriod] {
        var result: [CyclePeriod] = []
        var current = cycleForDate(date, payday: payday, overrides: overrides, calendar: calendar)
        result.append(current)
        
        // Add past cycles
        var prev = current
        for _ in 1..<count {
            prev = previousCycle(before: prev, calendar: calendar)
            result.append(prev)
        }
        
        return result.sorted { $0.startDate > $1.startDate }
    }
    
    // MARK: - Currency Conversion
    
    public static func convert(
        amount: Decimal,
        from fromCurrency: Currency,
        to toCurrency: Currency,
        rate: Decimal
    ) -> Decimal {
        if fromCurrency == toCurrency {
            return roundDecimal(amount, scale: 2)
        }
        
        guard rate > 0 else {
            return roundDecimal(amount, scale: 2)
        }
        
        let converted: Decimal
        switch (fromCurrency, toCurrency) {
        case (.EUR, .SEK):
            // 1 EUR = rate SEK -> SEK = EUR * rate
            converted = amount * rate
        case (.SEK, .EUR):
            // 1 EUR = rate SEK -> EUR = SEK / rate
            converted = amount / rate
        default:
            converted = amount
        }
        
        return roundDecimal(converted, scale: 2)
    }
    
    // MARK: - Budget Calculations
    
    public static func calculateVariableBudget(
        salary: Decimal,
        savingsGoal: Decimal,
        fixedAllocations: Decimal,
        smoothedAllocations: Decimal,
        buffer: Decimal = 0
    ) -> Decimal {
        return salary - savingsGoal - fixedAllocations - smoothedAllocations - buffer
    }
    
    public static func calculateRemaining(
        variableBudget: Decimal,
        variableExpenses: Decimal
    ) -> Decimal {
        return variableBudget - variableExpenses
    }
    
    public static func dailyAllowance(
        remaining: Decimal,
        daysRemaining: Int
    ) -> Decimal {
        guard daysRemaining > 0 else {
            return remaining
        }
        return roundDecimal(remaining / Decimal(daysRemaining), scale: 2)
    }
    
    public static func projectedBalance(
        initialBalance: Decimal,
        totalIncomes: Decimal,
        totalActualExpenses: Decimal
    ) -> Decimal {
        return initialBalance + totalIncomes - totalActualExpenses
    }
    
    public static func progressRatio(
        spent: Decimal,
        cap: Decimal
    ) -> Double {
        guard cap > 0 else { return 0.0 }
        let ratio = spent / cap
        return Double(truncating: ratio as NSNumber)
    }
    
    public static func roundDecimal(_ value: Decimal, scale: Int, mode: NSDecimalNumber.RoundingMode = .plain) -> Decimal {
        var val = value
        var result = Decimal()
        NSDecimalRound(&result, &val, scale, mode)
        return result
    }
    
    public static func formatAmount(
        _ amount: Decimal,
        currency: Currency,
        roundToUnit: Bool = false
    ) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = currency.rawValue
        formatter.currencySymbol = currency.symbol
        formatter.locale = Locale(identifier: "fr_FR")
        
        if roundToUnit {
            formatter.minimumFractionDigits = 0
            formatter.maximumFractionDigits = 0
            let rounded = roundDecimal(amount, scale: 0)
            return formatter.string(from: rounded as NSDecimalNumber) ?? "\(rounded) \(currency.symbol)"
        } else {
            formatter.minimumFractionDigits = 2
            formatter.maximumFractionDigits = 2
            return formatter.string(from: amount as NSDecimalNumber) ?? "\(amount) \(currency.symbol)"
        }
    }
}
