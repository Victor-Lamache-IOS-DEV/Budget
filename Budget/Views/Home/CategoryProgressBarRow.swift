import SwiftUI

public struct CategoryProgressBarRow: View {
    let category: BudgetCategory
    let spent: Decimal
    let baseCurrency: Currency
    let roundToUnit: Bool
    
    var cap: Decimal? {
        category.monthlyCap
    }
    
    var progress: Double {
        guard let cap = cap, cap > 0 else { return 0 }
        return BudgetCalculator.progressRatio(spent: spent, cap: cap)
    }
    
    var progressColor: Color {
        if progress > 1.0 {
            return .red
        } else if progress >= 0.8 {
            return .orange
        } else {
            return Color(hex: category.colorHex)
        }
    }
    
    public var body: some View {
        VStack(spacing: 8) {
            HStack(spacing: 10) {
                ZStack {
                    Circle()
                        .fill(Color(hex: category.colorHex).opacity(0.18))
                        .frame(width: 36, height: 36)
                    Image(systemName: category.icon)
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundStyle(Color(hex: category.colorHex))
                }
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(category.name)
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundStyle(.primary)
                    
                    Text(category.type.title)
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: 2) {
                    Text(BudgetCalculator.formatAmount(spent, currency: baseCurrency, roundToUnit: roundToUnit))
                        .font(.subheadline)
                        .fontWeight(.bold)
                        .foregroundStyle(progress > 1.0 ? .red : .primary)
                    
                    if let cap = cap {
                        Text("sur " + BudgetCalculator.formatAmount(cap, currency: baseCurrency, roundToUnit: roundToUnit))
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    }
                }
            }
            
            if let _ = cap {
                GeometryReader { geo in
                    ZStack(alignment: .leading) {
                        Capsule()
                            .fill(Color(.tertiarySystemFill))
                            .frame(height: 7)
                        
                        Capsule()
                            .fill(progressColor)
                            .frame(
                                width: min(geo.size.width, geo.size.width * CGFloat(min(max(progress, 0), 1.0))),
                                height: 7
                            )
                    }
                }
                .frame(height: 7)
            }
        }
        .padding(.vertical, 6)
    }
}
