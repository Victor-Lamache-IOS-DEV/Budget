import Foundation

public enum CategoryType: String, CaseIterable, Codable, Identifiable {
    case variable = "variable"
    case fixed = "fixed"
    case smoothed = "smoothed"
    
    public var id: String { rawValue }
    
    public var title: String {
        switch self {
        case .variable: return "Variable"
        case .fixed: return "Fixe"
        case .smoothed: return "Lissée"
        }
    }
    
    public var description: String {
        switch self {
        case .variable:
            return "Déduite au fil des dépenses réelles."
        case .fixed:
            return "Budget connu d'avance, déduit dès le début du cycle."
        case .smoothed:
            return "Montant mis de côté chaque cycle pour un achat ponctuel futur."
        }
    }
}
