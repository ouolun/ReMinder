import SwiftUI

extension UIImage {
    func withRoundedCorners(radius: CGFloat) -> UIImage {
        let rect = CGRect(origin: .zero, size: self.size)
        UIGraphicsBeginImageContextWithOptions(self.size, false, self.scale)
        UIBezierPath(roundedRect: rect, cornerRadius: radius).addClip()
        self.draw(in: rect)
        let image = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        return image ?? self
    }
}

struct Fragment: Identifiable, Hashable {
    let id: Int 
    let maskPath: Path
    let center: CGPoint
    var offset: CGSize = .zero
    var rotation: Angle = .zero
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
        hasher.combine(offset.width)
        hasher.combine(offset.height)
        hasher.combine(rotation.degrees)
    }
    
    static func == (lhs: Fragment, rhs: Fragment) -> Bool {
        return lhs.id == rhs.id &&
        lhs.offset == rhs.offset &&
        lhs.rotation == rhs.rotation
    }
}

struct BreakImageView: View {
    @Environment(\.horizontalSizeClass) var sizeClass
    var isPad: Bool { sizeClass == .regular }
    
    let image: UIImage
    let selectedNamedColors: [NamedColor] 
    
    @State private var fragments: [Fragment] = []
    @State private var isBroken = false
    @State private var imageSize: CGSize = .zero
    @State private var roundedImage: UIImage? = nil
    @State private var showNextButton = false
    
    @EnvironmentObject var navManager: NavigationManager
    
    var body: some View {
        GeometryReader { geo in
            ZStack {
                Color.white.ignoresSafeArea()
                
                VStack(spacing: isPad ? 40 : 25) {
                    VStack(spacing: 10) {
                        Text("Shatter your worries")
                            .font(.system(size: isPad ? 35 : 24,
                                          weight: .black,
                                          design: .rounded))
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 20)
                        
                        Text("Choose a point on the canvas and simply tap it.")
                            .font(.system(size: isPad ? 25 : 16, design: .serif))
                            .italic()
                            .foregroundColor(.black.opacity(0.6))
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 20)
                    }
                    .padding(.top, 40)
                    
                    ZStack {
                        if !isBroken {
                            // Initial state: Display single rounded image
                            Image(uiImage: image.withRoundedCorners(radius: isPad ? 20 : 12))
                                .resizable()
                                .scaledToFit()
                                .background(GeometryReader { imgGeo in
                                    Color.clear.onAppear { self.imageSize = imgGeo.size }
                                })
                                .shadow(color: Color.black.opacity(0.2), radius: 10)
                                .onTapGesture { location in
                                    fastBreak(at: location)
                                }
                        } else if let displayImage = roundedImage {
                            // Shattered state: Display individual fragments with masks
                            ZStack {
                                ForEach(fragments) { fragment in
                                    Image(uiImage: displayImage)
                                        .resizable()
                                        .scaledToFit()
                                        .mask(fragment.maskPath)
                                        .rotationEffect(
                                            fragment.rotation, 
                                            anchor: UnitPoint(
                                                x: fragment.center.x / imageSize.width, 
                                                y: fragment.center.y / imageSize.height
                                            )
                                        )
                                        .offset(fragment.offset)
                                        .shadow(color: Color.black.opacity(0.2), radius: 10)
                                }
                            }
                        }
                    }
                    .padding(.horizontal, geo.size.width * (isPad ? 0.125 : 0.075))
                    
                    Spacer()
                }
                .frame(width: geo.size.width, height: geo.size.height)
                
                // Navigation button overlay
                VStack {
                    Spacer()
                    HStack {
                        Spacer()
                        if showNextButton {
                            Button(action: { 
                                navManager.path.append(AppPage.soulAssembly(
                                    image: image, 
                                    fragments: fragments, 
                                    colors: selectedNamedColors
                                ))
                            }) {
                                ZStack {
                                    Capsule()
                                        .fill(
                                            LinearGradient(
                                                colors: selectedNamedColors.map { $0.color },
                                                startPoint: .leading,
                                                endPoint: .trailing
                                            )
                                        )
                                        .blur(radius: 10)
                                    
                                    Text("Next")
                                        .font(.system(size: isPad ? 22 : 16, weight: .black, design: .rounded))
                                        .foregroundColor(.black)
                                        .frame(width: isPad ? 150 : 100, height: isPad ? 70 : 60)
                                        .background(
                                            Capsule()
                                                .fill(Color.white)
                                        )
                                        .glassEffect(.regular.interactive())
                                }
                                .frame(width: isPad ? 150 : 100, height: isPad ? 70 : 60)
                            }
                            .transition(.opacity)
                            .padding(.trailing, 25)
                            .padding(.bottom, 30)
                        }
                    }
                }
            }
        }
        .navigationBarHidden(true)
    }
    
    // Calculates fragment paths and trigger explosion animation
    private func fastBreak(at point: CGPoint) {
        self.roundedImage = image.withRoundedCorners(radius: isPad ? 20 : 12)
        let currentImageSize = self.imageSize
        
        DispatchQueue.global(qos: .userInteractive).async {
            let rings = isPad ? 5 : 4
            let sectors = 10
            let diagonal = sqrt(pow(currentImageSize.width, 2) + pow(currentImageSize.height, 2))
            let maxRadius = diagonal * 1.15 
            
            // Create a radial grid for triangulation
            var grid: [[CGPoint]] = []
            for r in 0...rings {
                var row: [CGPoint] = []
                let radius = CGFloat(r) / CGFloat(rings) * maxRadius
                for s in 0..<sectors {
                    let jitter = r == 0 ? 0 : CGFloat.random(in: -0.1...0.1)
                    let angle = (CGFloat(s) / CGFloat(sectors)) * 2 * .pi + jitter
                    row.append(CGPoint(x: point.x + cos(angle) * radius, y: point.y + sin(angle) * radius))
                }
                grid.append(row)
            }
            
            var newFragments: [Fragment] = []
            var count = 0
            for r in 0..<rings {
                for s in 0..<sectors {
                    let sNext = (s + 1) % sectors
                    let p1 = grid[r][s]
                    let p2 = grid[r+1][s]
                    let p3 = grid[r+1][sNext]
                    let p4 = grid[r][sNext]
                    
                    // Divide each quad into two triangles
                    newFragments.append(makeFragment(p1, p2, p3, id: count)); count += 1
                    newFragments.append(makeFragment(p1, p3, p4, id: count)); count += 1
                }
            }
            
            // Calculate displacement for the explosion effect
            var animatedFragments = newFragments
            for i in animatedFragments.indices {
                let dx = animatedFragments[i].center.x - point.x
                let dy = animatedFragments[i].center.y - point.y
                let dist = max(sqrt(dx*dx + dy*dy), 1)
                let move: CGFloat = 12
                animatedFragments[i].offset = CGSize(width: dx/dist * move, height: dy/dist * move)
                animatedFragments[i].rotation = Angle(degrees: Double.random(in: -5...5))
            }
            
            DispatchQueue.main.async {
                self.fragments = newFragments
                self.isBroken = true
                
                withAnimation(.easeOut(duration: 0.3)) {
                    self.fragments = animatedFragments
                }
                
                // Delay button appearance until animation finishes
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                    withAnimation(.easeInOut(duration: 0.5)) {
                        self.showNextButton = true
                    }
                }
            }
        }
    }
    
    // Generates a triangular fragment from three points
    private func makeFragment(_ p1: CGPoint, _ p2: CGPoint, _ p3: CGPoint, id: Int) -> Fragment {
        var path = Path()
        path.move(to: p1)
        path.addLine(to: p2)
        path.addLine(to: p3)
        path.closeSubpath()
        
        let center = CGPoint(x: (p1.x + p2.x + p3.x) / 3, y: (p1.y + p2.y + p3.y) / 3)
        return Fragment(id: id, maskPath: path, center: center)
    }
}
