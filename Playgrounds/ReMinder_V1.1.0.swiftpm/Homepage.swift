import SwiftUI

struct HomeView: View {
    @State private var pos: CGPoint = .init(x: 500, y: 500)
    @State private var isActive: Bool = false
    @EnvironmentObject var navManager: NavigationManager
    @Environment(\.horizontalSizeClass) var sizeClass
    
    var isPad: Bool { sizeClass == .regular }
    
    // Theme Colors
    let color1 = Color(red: 1.0, green: 0.45, blue: 0.55)
    let color2 = Color(red: 1.0, green: 0.70, blue: 0.40)
    let color3 = Color(red: 0.55, green: 0.60, blue: 0.95)
    
    var body: some View {
        ZStack {
            // Layer 1: Background animated mesh
            AnimatedMeshGradientView(colors: [color1, color2, color3])
                .ignoresSafeArea()
            
            // Layer 2: Central Star Graphic
            Image("Star")
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: isPad ? 400 : 280, height: isPad ? 400 : 280)
                .shadow(color: .black.opacity(0.2), radius: 30)
            
            // Layer 3: Glass Morphism with Interactive Hole Mask
            Rectangle()
                .fill(.ultraThinMaterial)
                .ignoresSafeArea()
                .mask(
                    ZStack {
                        Color.white.opacity(0.95)
                        
                        // Creates a "clearing" effect where the user touches
                        RadialGradient(
                            stops: [
                                .init(color: .black, location: 0),
                                .init(color: .black, location: 0.5),
                                .init(color: .clear, location: 0.8)
                            ],
                            center: .center,
                            startRadius: 0,
                            endRadius: 180
                        )
                        .frame(width: 800, height: 800)
                        .position(pos)
                        .blendMode(.destinationOut)
                        .opacity(isActive ? 1 : 0)
                        .scaleEffect(isActive ? 1 : 0.5)
                    }
                        .compositingGroup()
                )
                .ignoresSafeArea()
            
            // Layer 4: Interaction Layer (placed between UI and Background)
            Color.clear
                .contentShape(Rectangle())
                .gesture(
                    DragGesture(minimumDistance: 0)
                        .onChanged { value in
                            pos = value.location
                            isActive = true
                        }
                        .onEnded { _ in
                            withAnimation(.spring(response: 0.5, dampingFraction: 0.8)) {
                                isActive = false
                            }
                        }
                )
            
            // Layer 5: Main UI Controls
            VStack(spacing: 30) {
                VStack(spacing: 12) {
                    Text("ReMinder")
                        .font(.system(size: isPad ? 60 : 48, weight: .black, design: .rounded))
                    
                    Text("Shatter the shadows, gather the pieces, Rebuild your pain into a Star of Hope.")
                        .font(.system(size: isPad ? 25 : 18, design: .serif))
                        .italic()
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 40)
                }
                .foregroundColor(.white)
                .shadow(color: .black.opacity(0.3), radius: 10)
                
                Spacer().frame(height: 50)
                
                Button(action: {
                    navManager.path.append(AppPage.palette)
                }) {
                    Text("Start Journey")
                        .font(.system(size: isPad ? 25 : 18, weight: .bold, design: .rounded))
                        .foregroundColor(.white)
                        .padding(.vertical, isPad ? 20 : 16)
                        .padding(.horizontal, isPad ? 60 : 40)
                        //.background(Capsule().fill(.ultraThinMaterial))
                        .shadow(color: .black.opacity(0.2), radius: 10)
                }
                .glassEffect(.clear.interactive(), in: Capsule())
            }
            .opacity(isActive ? 0 : 1)
            .allowsHitTesting(!isActive)
            
            // Layer 6: Feature Hint Footer
            VStack {
                Spacer()
                HStack(spacing: 8) {
                    Image(systemName: "applepencil.and.scribble")
                        .font(.system(size: isPad ? 20 : 16, weight: .bold))
                    
                    Text("Refined for Apple Pencil")
                        .font(.system(size: isPad ? 20 : 16, weight: .bold, design: .rounded))
                }
                .foregroundStyle(.white)
                .padding(.bottom, 15)
            }
            .opacity(isActive ? 0 : 1)
            .allowsHitTesting(false)
        }
        .animation(.interactiveSpring(response: 0.35, dampingFraction: 0.85), value: pos)
        .animation(.easeInOut(duration: 0.4), value: isActive)   
    }
}

// MARK: - Subviews

struct AnimatedMeshGradientView: View {
    let colors: [Color]
    
    var body: some View {
        TimelineView(.animation) { timeline in
            let t = timeline.date.timeIntervalSinceReferenceDate
            
            // Calculation of irregular movement offsets for the mesh center
            let offsetX = 0.15 * cos(t * 0.7) + 0.1 * sin(t * 1.3)
            let offsetY = 0.15 * sin(t * 0.5) + 0.1 * cos(t * 1.1)
            
            // Secondary offsets for perimeter point fluidity
            let offset2X = 0.1 * sin(t * 0.9)
            let offset2Y = 0.1 * cos(t * 1.4)
            
            MeshGradient(
                width: 3,
                height: 3,
                points: [
                    [0, 0], [0.5 + Float(offset2X), 0], [1, 0],
                    [Float(offset2Y), 0.5],
                    [0.5 + Float(offsetX), 0.5 + Float(offsetY)],
                    [1 + Float(offset2X), 0.5],
                    [0, 1], [0.5, 1], [1, 1]
                ],
                colors: [
                    colors[0], colors[1], colors[0],
                    colors[2], colors[0], colors[1],
                    colors[1], colors[2], colors[2]
                ],
                smoothsColors: true
            )
        }
        .ignoresSafeArea()
        .blur(radius: 40) 
        .scaleEffect(1.2) 
    }
}
