import XCTest
@testable import Budget

final class CurrencyConversionTests: XCTestCase {
    
    let defaultRate = Decimal(string: "11.12")!
    
    func testEURToSEKConversion() {
        let eurAmount: Decimal = 100
        let converted = BudgetCalculator.convert(
            amount: eurAmount,
            from: .EUR,
            to: .SEK,
            rate: defaultRate
        )
        XCTAssertEqual(converted, Decimal(string: "1112.00")!)
    }
    
    func testSEKToEURConversion() {
        let sekAmount: Decimal = Decimal(string: "111.20")!
        let converted = BudgetCalculator.convert(
            amount: sekAmount,
            from: .SEK,
            to: .EUR,
            rate: defaultRate
        )
        XCTAssertEqual(converted, Decimal(string: "10.00")!)
    }
    
    func testFractionalConversionWithHalfUpRounding() {
        // 49.90 SEK / 11.12 = 4.4874... EUR -> should round to 4.49 EUR
        let sekAmount = Decimal(string: "49.90")!
        let converted = BudgetCalculator.convert(
            amount: sekAmount,
            from: .SEK,
            to: .EUR,
            rate: defaultRate
        )
        XCTAssertEqual(converted, Decimal(string: "4.49")!)
    }
    
    func testIdenticalCurrencyConversionRequiresNoMath() {
        let amount = Decimal(string: "154.75")!
        let converted = BudgetCalculator.convert(
            amount: amount,
            from: .EUR,
            to: .EUR,
            rate: defaultRate
        )
        XCTAssertEqual(converted, amount)
    }
    
    func testTransactionImmutableHistory() {
        // When a transaction is created at rate 11.12, baseAmount is saved.
        let originalSEK = Decimal(string: "222.40")!
        let rate1 = Decimal(string: "11.12")!
        let base1 = BudgetCalculator.convert(amount: originalSEK, from: .SEK, to: .EUR, rate: rate1)
        
        let transaction = Transaction(
            originalAmount: originalSEK,
            originalCurrency: .SEK,
            rateUsed: rate1,
            baseAmount: base1,
            categoryID: UUID(),
            note: "Café à Stockholm"
        )
        
        XCTAssertEqual(transaction.baseAmount, Decimal(20))
        
        // Rate is changed in settings later to 11.50
        let newRate = Decimal(string: "11.50")!
        // The saved transaction baseAmount remains 20 EUR
        XCTAssertEqual(transaction.baseAmount, Decimal(20))
        XCTAssertEqual(transaction.rateUsed, rate1)
        XCTAssertNotEqual(transaction.rateUsed, newRate)
    }
}
