import Foundation

public struct CyclePeriod: Equatable, Hashable, Identifiable {
    public var id: String {
        "\(Int(startDate.timeIntervalSince1970))_\(Int(endDate.timeIntervalSince1970))"
    }
    
    public let startDate: Date
    public let endDate: Date
    public let payday: Int
    
    public init(startDate: Date, endDate: Date, payday: Int) {
        self.startDate = startDate
        self.endDate = endDate
        self.payday = payday
    }
    
    public func contains(_ date: Date) -> Bool {
        return date >= startDate && date <= endDate
    }
    
    public var totalDays: Int {
        let calendar = Calendar.current
        let startDay = calendar.startOfDay(for: startDate)
        let endDay = calendar.startOfDay(for: endDate)
        let components = calendar.dateComponents([.day], from: startDay, to: endDay)
        return (components.day ?? 0) + 1
    }
    
    public func daysRemaining(relativeTo today: Date = Date(), calendar: Calendar = .current) -> Int {
        let currentDayStart = calendar.startOfDay(for: today)
        let cycleEndDayStart = calendar.startOfDay(for: endDate)
        
        if currentDayStart > cycleEndDayStart {
            return 0
        }
        if currentDayStart < calendar.startOfDay(for: startDate) {
            return totalDays
        }
        
        let components = calendar.dateComponents([.day], from: currentDayStart, to: cycleEndDayStart)
        // Today is included in remaining days
        return max(0, (components.day ?? 0) + 1)
    }
    
    public var formattedRange: String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "fr_FR")
        formatter.dateFormat = "d MMM"
        
        let yearFormatter = DateFormatter()
        yearFormatter.dateFormat = "yyyy"
        
        let startStr = formatter.string(from: startDate)
        let endStr = formatter.string(from: endDate)
        let yearStr = yearFormatter.string(from: endDate)
        
        return "\(startStr) – \(endStr) \(yearStr)"
    }
    
    public var shortDescription: String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "fr_FR")
        formatter.dateFormat = "d MMM"
        return "\(formatter.string(from: startDate)) – \(formatter.string(from: endDate))"
    }
}
