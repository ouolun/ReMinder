import SwiftUI

struct ContentView: View {
    @StateObject private var navManager = NavigationManager()
    
    var body: some View {
        NavigationStack(path: $navManager.path) {
            // Initial view of the application lifecycle
            HomeView()
                .navigationDestination(for: AppPage.self) { page in
                    switch page {
                    case .palette:
                        Palette()
                        
                    case .drawing(let colors):
                        DrawingView(selectedNamedColors: colors)
                        
                    case .breakImage(let image, let colors):
                        BreakImageView(image: image, selectedNamedColors: colors)
                        
                    case .soulAssembly(let image, let fragments, let colors):
                        SoulAssemblyView(
                            originalImage: image, 
                            fragments: fragments, 
                            selectedNamedColors: colors
                        )
                        
                    case .postcard(let image, let colors):
                        PostcardView(finalImage: image, selectedNamedColors: colors)
                    }
                }
        }
        // Inject the navigation manager as an EnvironmentObject for global access
        .environmentObject(navManager)
    }
}
