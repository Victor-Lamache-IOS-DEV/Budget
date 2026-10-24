import SwiftUI
import SwiftData

public struct CategoryManagementView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \BudgetCategory.order) private var categories: [BudgetCategory]
    
    let baseCurrency: Currency
    
    @State private var editingCategory: BudgetCategory?
    @State private var showAddSheet: Bool = false
    
    public var body: some View {
        List {
            ForEach(CategoryType.allCases) { catType in
                let itemsOfType = categories.filter { $0.type == catType }
                if !itemsOfType.isEmpty {
                    Section(header: Text(catType.title + "s")) {
                        ForEach(itemsOfType) { cat in
                            CategoryRow(
                                category: cat,
                                baseCurrency: baseCurrency
                            )
                            .contentShape(Rectangle())
                            .onTapGesture {
                                editingCategory = cat
                            }
                        }
                        .onDelete { indexSet in
                            deleteCategory(from: itemsOfType, at: indexSet)
                        }
                    }
                }
            }
        }
        .navigationTitle("Catégories")
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    Haptics.playLight()
                    showAddSheet = true
                } label: {
                    Image(systemName: "plus")
                }
            }
        }
        .sheet(item: $editingCategory) { cat in
            CategoryEditSheet(existingCategory: cat, baseCurrency: baseCurrency)
        }
        .sheet(isPresented: $showAddSheet) {
            CategoryEditSheet(baseCurrency: baseCurrency)
        }
    }
    
    private func deleteCategory(from list: [BudgetCategory], at offsets: IndexSet) {
        for index in offsets {
            let cat = list[index]
            modelContext.delete(cat)
        }
        try? modelContext.save()
        Haptics.playMedium()
    }
}

struct CategoryRow: View {
    let category: BudgetCategory
    let baseCurrency: Currency
    
    var body: some View {
        HStack(spacing: 12) {
            ZStack {
                Circle()
                    .fill(Color(hex: category.colorHex).opacity(0.18))
                    .frame(width: 36, height: 36)
                Image(systemName: category.icon)
                    .foregroundStyle(Color(hex: category.colorHex))
            }
            
            VStack(alignment: .leading, spacing: 2) {
                Text(category.name)
                    .font(.body)
                    .fontWeight(.medium)
                
                Text(category.type.title)
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
            
            Spacer()
            
            if let cap = category.monthlyCap {
                Text(BudgetCalculator.formatAmount(cap, currency: baseCurrency))
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(.vertical, 4)
    }
}
