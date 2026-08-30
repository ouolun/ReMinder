import SwiftUI

enum AppPage: Hashable {
    case palette                                      
    case drawing(colors: [NamedColor])                
    case breakImage(image: UIImage, colors: [NamedColor]) 
    case soulAssembly(image: UIImage, fragments: [Fragment], colors: [NamedColor]) 
    case postcard(image: UIImage, colors: [NamedColor]) 
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(self.index)
    }
    
    private var index: Int {
        switch self {
        case .palette: return 0
        case .drawing: return 1
        case .breakImage: return 2
        case .soulAssembly: return 3
        case .postcard: return 4
        }
    }
    
    static func == (lhs: AppPage, rhs: AppPage) -> Bool {
        lhs.index == rhs.index
    }
}

class NavigationManager: ObservableObject {
    @Published var path = NavigationPath()
    
    // Resets the navigation stack back to the initial view
    func popToRoot() {
        withAnimation(.easeInOut(duration: 0.4)) {
            path = NavigationPath()
        }
    }
}
