import SwiftUI

enum AppPage: Hashable {
    case palette                                      
    case drawing(colors: [NamedColor])                
    case breakImage(image: UIImage, colors: [NamedColor]) 
    case soulAssembly(image: UIImage, fragments: [Fragment], colors: [NamedColor]) 
    case postcard(image: UIImage, colors: [NamedColor]) 
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(self.index)
        switch self {
        case .palette:
            break
        case .drawing(let colors):
            hasher.combine(colors)
        case .breakImage(_, let colors):
            hasher.combine(colors)
        case .soulAssembly(_, let fragments, let colors):
            hasher.combine(fragments)
            hasher.combine(colors)
        case .postcard(_, let colors):
            hasher.combine(colors)
        }
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
        switch (lhs, rhs) {
        case (.palette, .palette):
            return true
        case (.drawing(let lColors), .drawing(let rColors)):
            return lColors == rColors
        case (.breakImage(let lImg, let lColors), .breakImage(let rImg, let rColors)):
            return lImg == rImg && lColors == rColors
        case (.soulAssembly(let lImg, let lFrags, let lColors), .soulAssembly(let rImg, let rFrags, let rColors)):
            return lImg == rImg && lFrags == rFrags && lColors == rColors
        case (.postcard(let lImg, let lColors), .postcard(let rImg, let rColors)):
            return lImg == rImg && lColors == rColors
        default:
            return false
        }
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
