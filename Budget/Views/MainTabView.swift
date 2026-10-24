import SwiftUI
import SwiftData

public struct MainTabView: View {
    @Query private var settingsList: [UserSettings]
    @State private var selectedTab: Int = 0
    @State private var showOnboarding: Bool = false
    
    private var hasCompletedOnboarding: Bool {
        settingsList.first?.hasCompletedOnboarding ?? false
    }
    
    public var body: some View {
        Group {
            if hasCompletedOnboarding {
                TabView(selection: $selectedTab) {
                    HomeView()
                        .tabItem {
                            Label("Accueil", systemImage: "house.fill")
                        }
                        .tag(0)
                    
                    HistoryView()
                        .tabItem {
                            Label("Historique", systemImage: "clock.fill")
                        }
                        .tag(1)
                    
                    SettingsView()
                        .tabItem {
                            Label("Réglages", systemImage: "gearshape.fill")
                        }
                        .tag(2)
                }
            } else {
                OnboardingView {
                    showOnboarding = false
                }
            }
        }
    }
}
