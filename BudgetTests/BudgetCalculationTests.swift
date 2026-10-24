import XCTest
@testable import Budget

final class BudgetCalculationTests: XCTestCase {
    
    func testVariableBudgetCalculation() {
        let salary: Decimal = 2500
        let savings: Decimal = 400
        let fixed: Decimal = 135
        let smoothed: Decimal = 40
        let buffer: Decimal = 50
        
        let variableBudget = BudgetCalculator.calculateVariableBudget(
            salary: salary,
            savingsGoal: savings,
            fixedAllocations: fixed,
            smoothedAllocations: smoothed,
            buffer: buffer
        )
        
        // 2500 - 400 - 135 - 40 - 50 = 1875
        XCTAssertEqual(variableBudget, 1875)
    }
    
    func testRemainingVariableBudget() {
        let variableBudget: Decimal = 1875
        let spent: Decimal = 375
        
        let remaining = BudgetCalculator.calculateRemaining(
            variableBudget: variableBudget,
            variableExpenses: spent
        )
        
        XCTAssertEqual(remaining, 1500)
    }
    
    func testNegativeRemainingOverrun() {
        let variableBudget: Decimal = 1875
        let spent: Decimal = 1975
        
        let remaining = BudgetCalculator.calculateRemaining(
            variableBudget: variableBudget,
            variableExpenses: spent
        )
        
        // Negative remaining: -100 €
        XCTAssertEqual(remaining, -100)
    }
    
    func testDailyAllowanceCalculation() {
        let remaining: Decimal = 1500
        let daysLeft = 15
        
        let daily = BudgetCalculator.dailyAllowance(remaining: remaining, daysRemaining: daysLeft)
        XCTAssertEqual(daily, 100)
    }
    
    func testMidCycleSalaryChangeRecalculatesImmediately() {
        // Initial salary 2500
        var salary: Decimal = 2500
        let savings: Decimal = 400
        let fixed: Decimal = 135
        let smoothed: Decimal = 40
        let buffer: Decimal = 50
        let variableSpent: Decimal = 375
        
        let initialBudget = BudgetCalculator.calculateVariableBudget(
            salary: salary,
            savingsGoal: savings,
            fixedAllocations: fixed,
            smoothedAllocations: smoothed,
            buffer: buffer
        )
        let initialRemaining = BudgetCalculator.calculateRemaining(
            variableBudget: initialBudget,
            variableExpenses: variableSpent
        )
        XCTAssertEqual(initialRemaining, 1500)
        
        // Salary gets updated to 2750 mid-cycle (bonus or raise)
        salary = 2750
        let updatedBudget = BudgetCalculator.calculateVariableBudget(
            salary: salary,
            savingsGoal: savings,
            fixedAllocations: fixed,
            smoothedAllocations: smoothed,
            buffer: buffer
        )
        let updatedRemaining = BudgetCalculator.calculateRemaining(
            variableBudget: updatedBudget,
            variableExpenses: variableSpent
        )
        
        // 2750 - 400 - 135 - 40 - 50 = 2125
        // 2125 - 375 = 1750
        XCTAssertEqual(updatedBudget, 2125)
        XCTAssertEqual(updatedRemaining, 1750)
    }
    
    func testProjectedAccountBalance() {
        let initialBalance: Decimal = 1200
        let incomes: Decimal = 2500
        let totalExpenses: Decimal = 850
        
        let projected = BudgetCalculator.projectedBalance(
            initialBalance: initialBalance,
            totalIncomes: incomes,
            totalActualExpenses: totalExpenses
        )
        
        // 1200 + 2500 - 850 = 2850
        XCTAssertEqual(projected, 2850)
    }
    
    func testCategoryCapProgressRatio() {
        let cap: Decimal = 300
        let spent: Decimal = 150
        let ratio = BudgetCalculator.progressRatio(spent: spent, cap: cap)
        XCTAssertEqual(ratio, 0.5, accuracy: 0.0001)
        
        let overrunSpent: Decimal = 360
        let overrunRatio = BudgetCalculator.progressRatio(spent: overrunSpent, cap: cap)
        XCTAssertEqual(overrunRatio, 1.2, accuracy: 0.0001)
    }
}
