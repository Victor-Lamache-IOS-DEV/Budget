import Foundation

public enum Currency: String, CaseIterable, Codable, Identifiable {
    case EUR = "EUR"
    case SEK = "SEK"
    
    public var id: String { rawValue }
    
    public var symbol: String {
        switch self {
        case .EUR: return "€"
        case .SEK: return "kr"
        }
    }
    
    public var displayName: String {
        switch self {
        case .EUR: return "Euro (€)"
        case .SEK: return "Couronne suédoise (kr)"
        }
    }
    
    public var shortName: String {
        switch self {
        case .EUR: return "EUR"
        case .SEK: return "SEK"
        }
    }
}
