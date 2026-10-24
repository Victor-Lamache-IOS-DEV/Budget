import XCTest
@testable import Budget

final class CycleBoundaryTests: XCTestCase {
    
    var calendar: Calendar!
    
    override func setUp() {
        super.setUp()
        var cal = Calendar(identifier: .gregorian)
        cal.timeZone = TimeZone(secondsFromGMT: 0)!
        cal.locale = Locale(identifier: "fr_FR")
        calendar = cal
    }
    
    func makeDate(year: Int, month: Int, day: Int, hour: Int = 12) -> Date {
        var components = DateComponents()
        components.year = year
        components.month = month
        components.day = day
        components.hour = hour
        return calendar.date(from: components)!
    }
    
    // MARK: - Regular Payday Tests
    
    func testRegularPaydayCycle() {
        // Payday on 25th
        // Date: 26 October 2026
        let testDate = makeDate(year: 2026, month: 10, day: 26)
        let cycle = BudgetCalculator.cycleForDate(testDate, payday: 25, calendar: calendar)
        
        let expectedStart = calendar.startOfDay(for: makeDate(year: 2026, month: 10, day: 25))
        let nextStart = calendar.startOfDay(for: makeDate(year: 2026, month: 11, day: 25))
        let expectedEnd = nextStart.addingTimeInterval(-1)
        
        XCTAssertEqual(cycle.startDate, expectedStart)
        XCTAssertEqual(cycle.endDate, expectedEnd)
        XCTAssertTrue(cycle.contains(testDate))
    }
    
    func testDayBeforePaydayBelongsToPreviousCycle() {
        // Payday on 25th, Date: 24 October 2026
        let testDate = makeDate(year: 2026, month: 10, day: 24)
        let cycle = BudgetCalculator.cycleForDate(testDate, payday: 25, calendar: calendar)
        
        let expectedStart = calendar.startOfDay(for: makeDate(year: 2026, month: 9, day: 25))
        let nextStart = calendar.startOfDay(for: makeDate(year: 2026, month: 10, day: 25))
        let expectedEnd = nextStart.addingTimeInterval(-1)
        
        XCTAssertEqual(cycle.startDate, expectedStart)
        XCTAssertEqual(cycle.endDate, expectedEnd)
        XCTAssertTrue(cycle.contains(testDate))
    }
    
    // MARK: - Payday 31 Edge Cases
    
    func testPayday31InJanuaryNonLeapYear() {
        // Payday 31. Date: 31 January 2026.
        // February 2026 has 28 days -> clamped to Feb 28.
        let testDate = makeDate(year: 2026, month: 1, day: 31)
        let cycle = BudgetCalculator.cycleForDate(testDate, payday: 31, calendar: calendar)
        
        let expectedStart = calendar.startOfDay(for: makeDate(year: 2026, month: 1, day: 31))
        let nextStart = calendar.startOfDay(for: makeDate(year: 2026, month: 2, day: 28))
        let expectedEnd = nextStart.addingTimeInterval(-1)
        
        XCTAssertEqual(cycle.startDate, expectedStart)
        XCTAssertEqual(cycle.endDate, expectedEnd)
        XCTAssertTrue(cycle.contains(testDate))
    }
    
    func testPayday31InJanuaryLeapYear() {
        // Payday 31. 2024 is a leap year (February 29 days).
        let testDate = makeDate(year: 2024, month: 1, day: 31)
        let cycle = BudgetCalculator.cycleForDate(testDate, payday: 31, calendar: calendar)
        
        let expectedStart = calendar.startOfDay(for: makeDate(year: 2024, month: 1, day: 31))
        let nextStart = calendar.startOfDay(for: makeDate(year: 2024, month: 2, day: 29))
        let expectedEnd = nextStart.addingTimeInterval(-1)
        
        XCTAssertEqual(cycle.startDate, expectedStart)
        XCTAssertEqual(cycle.endDate, expectedEnd)
    }
    
    func testPayday31InFebruaryRunsThroughMarch30() {
        // Date: 28 February 2026. Payday = 31.
        // March has 31 days -> next cycle starts March 31.
        // So Feb cycle ends March 30 at 23:59:59.
        let testDate = makeDate(year: 2026, month: 2, day: 28)
        let cycle = BudgetCalculator.cycleForDate(testDate, payday: 31, calendar: calendar)
        
        let expectedStart = calendar.startOfDay(for: makeDate(year: 2026, month: 2, day: 28))
        let nextStart = calendar.startOfDay(for: makeDate(year: 2026, month: 3, day: 31))
        let expectedEnd = nextStart.addingTimeInterval(-1)
        
        XCTAssertEqual(cycle.startDate, expectedStart)
        XCTAssertEqual(cycle.endDate, expectedEnd)
    }
    
    func testPayday31InAprilRunsThroughMay30() {
        // April has 30 days -> clamped payday is April 30.
        // May has 31 days -> next cycle starts May 31.
        let testDate = makeDate(year: 2026, month: 4, day: 30)
        let cycle = BudgetCalculator.cycleForDate(testDate, payday: 31, calendar: calendar)
        
        let expectedStart = calendar.startOfDay(for: makeDate(year: 2026, month: 4, day: 30))
        let nextStart = calendar.startOfDay(for: makeDate(year: 2026, month: 5, day: 31))
        let expectedEnd = nextStart.addingTimeInterval(-1)
        
        XCTAssertEqual(cycle.startDate, expectedStart)
        XCTAssertEqual(cycle.endDate, expectedEnd)
    }
    
    // MARK: - Days Remaining Tests
    
    func testDaysRemainingIncludesToday() {
        // Cycle from Oct 25 to Nov 24.
        let start = calendar.startOfDay(for: makeDate(year: 2026, month: 10, day: 25))
        let end = calendar.startOfDay(for: makeDate(year: 2026, month: 11, day: 25)).addingTimeInterval(-1)
        let cycle = CyclePeriod(startDate: start, endDate: end, payday: 25)
        
        // On the final day (Nov 24): 1 day left (today included)
        let lastDay = makeDate(year: 2026, month: 11, day: 24, hour: 10)
        XCTAssertEqual(cycle.daysRemaining(relativeTo: lastDay, calendar: calendar), 1)
        
        // On Nov 23: 2 days left (Nov 23 and Nov 24)
        let twoDaysBefore = makeDate(year: 2026, month: 11, day: 23, hour: 10)
        XCTAssertEqual(cycle.daysRemaining(relativeTo: twoDaysBefore, calendar: calendar), 2)
        
        // On start day (Oct 25): 31 days in total
        let firstDay = makeDate(year: 2026, month: 10, day: 25, hour: 8)
        XCTAssertEqual(cycle.daysRemaining(relativeTo: firstDay, calendar: calendar), 31)
    }
    
    // MARK: - Custom Cycle Start Override
    
    func testCustomCycleStartOverride() {
        let baseStart = calendar.startOfDay(for: makeDate(year: 2026, month: 10, day: 25))
        let customStart = calendar.startOfDay(for: makeDate(year: 2026, month: 10, day: 23))
        
        let override = CycleOverride(
            cycleStartDate: baseStart,
            salaryOverride: 2800,
            customStartDate: customStart
        )
        
        let testDate = makeDate(year: 2026, month: 10, day: 26)
        let cycle = BudgetCalculator.cycleForDate(testDate, payday: 25, overrides: [override], calendar: calendar)
        
        XCTAssertEqual(cycle.startDate, customStart)
    }
}
