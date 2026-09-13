import SwiftUI
import PencilKit
import AudioToolbox

struct DrawingView: View {
    @Environment(\.horizontalSizeClass) var sizeClass
    var isPad: Bool { sizeClass == .regular }
    
    let selectedNamedColors: [NamedColor]
    @Environment(\.dismiss) var dismiss
    
    @State private var canvasView = PKCanvasView()
    @State private var undoManager: UndoManager? = nil
    
    @State private var selectedColor: Color
    @State private var selectedColorName: String
    
    @State private var capturedImage: UIImage? = nil
    @EnvironmentObject var navManager: NavigationManager
    
    private let crayonWidth: CGFloat = 30
    
    init(selectedNamedColors: [NamedColor]) {
        self.selectedNamedColors = selectedNamedColors
        let firstColor = selectedNamedColors.first ?? 
        NamedColor(name: "Black", color: .black, isLight: false)
        _selectedColor = State(initialValue: firstColor.color)
        _selectedColorName = State(initialValue: firstColor.name)
    }
    
    var body: some View {
        ZStack(alignment: .bottom) {
            
            // Core drawing canvas using PencilKit
            PencilKitView(
                canvasView: $canvasView,
                selectedColor: $selectedColor,
                width: crayonWidth
            )
            .ignoresSafeArea()
            .onAppear {
                undoManager = canvasView.undoManager
            }
            
            // Bottom gradient overlay to improve UI legibility
            LinearGradient(
                gradient: Gradient(colors: [.white.opacity(0),
                                            .white.opacity(0.4),
                                            .white]),
                startPoint: .top,
                endPoint: .bottom
            )
            .frame(height: isPad ? 280 : 240)
            .allowsHitTesting(false)
            .offset(y: 30)
            
            // Instructional header text
            VStack {
                VStack(spacing: 10) {
                    Text("Paint your soul out")
                        .font(.system(size: isPad ? 35 : 24,
                                      weight: .black,
                                      design: .rounded))
                        .shadow(color: .white, radius: 15)
                        .shadow(color: .white, radius: 10)
                        .shadow(color: .white, radius: 5)
                        .padding(.horizontal, 20)
                        .multilineTextAlignment(.center)
                    
                    Text("Select one of the colors you chose below, and paint directly on the canvas using a pencil or your finger. Try to fill the entire canvas.")
                        .font(.system(size: isPad ? 25:16, design: .serif))
                        .italic()
                        .foregroundColor(.black.opacity(0.6))
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 20)
                        .shadow(color: .white, radius: 15)
                        .shadow(color: .white, radius: 10)
                        .shadow(color: .white, radius: 5)
                }
                .padding(.top, 40)
                Spacer()
            }
            .allowsHitTesting(false)
            
            // Bottom control bar with tools and color selection
            HStack(alignment: .bottom) {
                
                // History controls: Reset, Undo, Redo
                GlassEffectContainer(spacing: isPad ? 20 : 15) {
                    VStack(spacing: isPad ? 20 : 15) {
                        controlButton(icon: "trash", color: .red.opacity(0.8)) {
                            canvasView.drawing = PKDrawing()
                        }
                        controlButton(icon: "arrow.uturn.backward", color: .primary) {
                            undoManager?.undo()
                        }
                        controlButton(icon: "arrow.uturn.forward", color: .primary) {
                            undoManager?.redo()
                        }
                    }
                    .offset(y: -20)
                }
                                
                Spacer()
                
                // Crayon selection area
                HStack(alignment: .bottom, spacing: isPad ? 40 : 20) {
                    ForEach(selectedNamedColors) { namedColor in
                        CrayonButton(
                            namedColor: namedColor,
                            isSelected: selectedColorName == namedColor.name
                        ) {
                            selectedColor = namedColor.color
                            selectedColorName = namedColor.name
                        }
                    }
                }
                .padding(.bottom, 10)
                
                Spacer()
                
                // Navigation to the next step (Capture and proceed)
                Button {
                    let img = canvasView.snapshotImageWithoutHomeIndicator()
                    self.capturedImage = img
                    navManager.path.append(AppPage.breakImage(image: img, colors: selectedNamedColors))
                } label: {
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
                        
                        Image(systemName: "chevron.right")
                            .font(.system(size: isPad ? 28 : 22, weight: .bold))
                            .foregroundColor(.black)
                            .frame(width: isPad ? 70 : 50, height: isPad ? 70 : 50)
                            .background(
                                Circle()
                                    .fill(Color.white)
                            )
                            .glassEffect(.regular.interactive())
                    }
                    .frame(width: isPad ? 70 : 50, height: isPad ? 70 : 50)
                    .offset(y: -20)
                }
            }
            .padding(.horizontal, 25)
        }
        .navigationBarHidden(true)
    }
    
    // Helper function to create circular control buttons
    func controlButton(icon: String, color: Color, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            ZStack{
                Capsule()
                    .fill(Color.black.opacity(0.2))
                    .frame(width: isPad ? 70 : 50, height: isPad ? 70 : 50)
                    .blur(radius: 10)
                
                Image(systemName: icon)
                    .font(.system(size: isPad ? 28 : 22, weight: .bold))
                    .foregroundColor(color)
                    .frame(width: isPad ? 70 : 50, height: isPad ? 70 : 50)
                    .background(
                        Circle()
                            .fill(Color.white)
                    )
                    .glassEffect(.regular.interactive())
            }
        }
    }
}

// MARK: - Crayon UI Component

struct CrayonButton: View {
    @Environment(\.horizontalSizeClass) var sizeClass
    var isPad: Bool { sizeClass == .regular }
    let namedColor: NamedColor
    let isSelected: Bool
    let action: () -> Void
    
    var crayonWidth: CGFloat { isPad ? 70 : 40 }
    var crayonHeight: CGFloat { isPad ? 250 : 200 }
    var labelHeight: CGFloat { isPad ? 215 : 165 }
    var whiteBarWidth: CGFloat { isPad ? 32 : 18 }
    
    var body: some View {
        Button(action: {
            FeedbackManager.shared.playTapSound()
            action()
        }) {
            VStack(spacing: 0) {
                ZStack(alignment: .top) {
                    Rectangle()
                        .fill(namedColor.color)
                        .frame(width: crayonWidth, height: crayonHeight)
                        .shadow(color: namedColor.color.opacity(0.3), radius: 5)
                    
                    VStack(spacing: 0) {
                        Spacer().frame(height: 35)
                        
                        ZStack {
                            Rectangle()
                                .fill(Color.white.opacity(0.6))
                                .frame(width: crayonWidth)
                            
                            GeometryReader { geo in
                                Text("ReMinder Oil Pastels")
                                    .font(.system(size: isPad ? 15 : 9, weight: .black))
                                    .foregroundColor(.black)
                                    .fixedSize()
                                    .rotationEffect(.degrees(-90))
                                    .frame(width: geo.size.width - whiteBarWidth, height: geo.size.height)
                            }
                            
                            Rectangle()
                                .fill(Color.white)
                                .frame(width: whiteBarWidth)
                                .overlay(
                                    HStack(spacing: isPad ? 12 : 8) {
                                        Text("CRAYON")
                                            .font(.custom("MarkerFelt-Wide", size: isPad ? 18 : 10))
                                            .opacity(0.6)
                                        Text(namedColor.name)
                                            .font(.system(size: isPad ? 22 : 13, weight: .black, design: .rounded))
                                    }
                                        .foregroundColor(namedColor.color)
                                        .fixedSize()
                                        .rotationEffect(.degrees(-90))
                                )
                                .offset(x: isPad ? 10 : 6)
                        }
                        .frame(width: crayonWidth, height: labelHeight)
                        .clipShape(Rectangle())
                    }
                }
                .offset(y: isPad ? (isSelected ? 50 : 150) : (isSelected ? 40 : 120))
            }
        }
        .buttonStyle(PlainButtonStyle())
        .animation(.spring(response: 0.3, dampingFraction: 0.6), value: isSelected)
    }
}

// MARK: - PencilKit Bridge

struct PencilKitView: UIViewRepresentable {
    @Binding var canvasView: PKCanvasView
    @Binding var selectedColor: Color
    let width: CGFloat
    
    func makeUIView(context: Context) -> PKCanvasView {
        canvasView.drawingPolicy = .anyInput
        canvasView.backgroundColor = .clear
        canvasView.isOpaque = false
        
        let crayonInk = PKInkingTool(.crayon, color: UIColor(selectedColor), width: width)
        canvasView.tool = crayonInk
        
        return canvasView
    }
    
    func updateUIView(_ uiView: PKCanvasView, context: Context) {
        let crayonInk = PKInkingTool(.crayon, color: UIColor(selectedColor), width: width)
        uiView.tool = crayonInk
    }
}

// MARK: - Audio Feedback Manager

class FeedbackManager {
    static let shared = FeedbackManager()
    func playTapSound() {
        AudioServicesPlaySystemSound(1104)
    }
}

// MARK: - Drawing Snapshot Extensions

extension PKCanvasView {
    func snapshotImageWithoutHomeIndicator() -> UIImage {
        let drawing = self.drawing
        let bottomInset = self.safeAreaInsets.bottom
        
        // Exclude UI controls and system indicators from the final crop
        let captureRect = CGRect(
            x: 0,
            y: 0,
            width: bounds.width,
            height: bounds.height - bottomInset - 100
        )
        
        // Generate high-resolution image from vector data
        let image = drawing.image(from: captureRect, scale: self.traitCollection.displayScale)

        
        // Flatten onto a white background to finalize the image
        let renderer = UIGraphicsImageRenderer(size: captureRect.size)
        return renderer.image { context in
            UIColor.white.setFill()
            context.fill(CGRect(origin: .zero, size: captureRect.size))
            image.draw(in: CGRect(origin: .zero, size: captureRect.size))
        }
    }
}
