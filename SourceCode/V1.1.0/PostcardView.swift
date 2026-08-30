import SwiftUI
import UIKit
import Photos

struct PostcardView: View {
    let finalImage: UIImage
    let selectedNamedColors: [NamedColor]
    
    @Environment(\.horizontalSizeClass) var sizeClass
    var isPad: Bool { sizeClass == .regular }
    @Environment(\.dismiss) var dismiss
    @Environment(\.displayScale) var displayScale
    
    @State private var isShowing = false
    @State private var rotation: Double = 0.0
    @State private var showSaveAlert = false 
    @State private var showSaveFailedAlert = false
    @State private var randomQuote: String = "" 
    @EnvironmentObject var navManager: NavigationManager
    
    static let quoteLibrary = [
        "In the flow of colors, we eventually find our complete selves.",
        "Every fragment is a guide to the depths of the soul.",
        "Perfection is not required; cracked light still shines through the dark.",
        "The world is a mosaic of fragments, and you are the most unique piece.",
        "Colors need no reason, and neither does a heartbeat.",
        "Scars are just the places where our light was born.",
        "The crack is where the light begins to dance.",
        "A broken soul is just a new shape waiting to be discovered.",
        "Falling apart is the first step toward falling into place.",
        "Your fragments are not flaws; they are the ingredients of your strength.",
        "Even a shattered mirror can still reflect the sunrise.",
        "Blessed are the cracked, for they let the starlight in.",
        "There is a silent dignity in the pieces we pick up.",
        "Healing is not fixing; it is the art of reclaiming every part of you.",
        "Broken things have a story that whole things will never understand.",
        "What was once broken can be rebuilt into something celestial.",
        "Shatter the shadows to find the stardust hidden within.",
        "Transformation begins when you stop fearing the pieces.",
        "The art of living is the art of reassembling our own hearts.",
        "Pain is the raw material for your future hope.",
        "Gather your fragments; they are the map to your rebirth.",
        "You are not ruined; you are in the middle of being remade.",
        "The most beautiful stars are born from the greatest collapses.",
        "Every brushstroke of pain adds depth to the masterpiece of you.",
        "Rebuilding is a quiet revolution of the soul.",
        "Let the old version of you crumble to make room for the light.",
        "In the ruins of yesterday, we find the bricks for tomorrow.",
        "Mending is a sacred conversation between you and your past.",
        "You are the architect of your own emotional galaxy.",
        "Each piece you find is a memory returning home.",
        "Within your darkness, a Star of Hope is quietly forming.",
        "The darker the night, the brighter your inner star shines.",
        "Turn your heaviest burdens into your brightest constellations.",
        "Hope is the gravity that pulls our fragments together.",
        "You were never lost; you were just waiting to be realigned.",
        "The stars don't ask for permission to shine, and neither should you.",
        "Even the smallest spark can ignite a universe of hope.",
        "Follow the glow of your own mended heart.",
        "Your hope is a star that no shadow can extinguish.",
        "We are all made of stardust and second chances.",
        "Look up; your pain has finally become a lighthouse.",
        "A heart that has been rebuilt glows with a different kind of fire.",
        "Let the colors carry away what words cannot express.",
        "The soul speaks in hues that only the heart can hear.",
        "Every shade of you belongs in this universe.",
        "Find the peace that lives between the strokes of your brush.",
        "Colors are the whispers of a healing mind.",
        "Drown the noise in a sea of gentle gradients.",
        "Your emotions are a spectrum, not a cage.",
        "Stay in the flow until the world feels soft again."
    ]
    
    var backgroundGradient: LinearGradient {
        var colors = selectedNamedColors.map { $0.color }
        if colors.count < 1 { colors.append(.blue) }
        if colors.count < 2 { colors.append(.purple) }
        if colors.count < 3 { colors.append(.pink) }
        return LinearGradient(colors: Array(colors.prefix(3)), startPoint: .top, endPoint: .bottom)
    }
    
    var mainGradient: LinearGradient {
        let colors = selectedNamedColors.isEmpty ? [Color.blue, Color.purple] : selectedNamedColors.map { $0.color }
        return LinearGradient(colors: colors, startPoint: .topLeading, endPoint: .bottomTrailing)
    }
    
    // MARK: - Postcard Layouts
    
    private var postcardMainContent: some View {
        Group {
            if isPad {
                // Horizontal layout for iPad
                HStack(spacing: 0) {
                    Image(uiImage: finalImage)
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(maxWidth: 400)
                        .padding(30)
                        .shadow(color: .black.opacity(0.2), radius: 15)
                    
                    VStack(spacing: 30) {
                        Text("\"\(randomQuote)\"")
                            .font(.system(size: 22, weight: .medium, design: .serif))
                            .italic()
                            .foregroundColor(.primary.opacity(0.7))
                            .multilineTextAlignment(.leading)
                            .fixedSize(horizontal: false, vertical: true)
                        
                        HStack {
                            VStack(alignment: .leading, spacing: 6) {
                                Text("ReMinder")
                                    .font(.system(size: 24, weight: .black, design: .rounded))
                                    .tracking(1.5)
                                Text(getFormattedDate())
                                    .font(.system(size: 18, design: .monospaced))
                                    .foregroundColor(.secondary)
                            }
                            Spacer()
                            Image(systemName: "seal.fill")
                                .foregroundStyle(mainGradient)
                                .font(.system(size: 42))
                        }
                    }
                    .padding(40)
                }
                .frame(width: 800, height: 450)
            } else {
                // Vertical layout for iPhone
                VStack(spacing: 0) {
                    Image(uiImage: finalImage)
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(maxWidth: .infinity)
                        .padding(20)
                        .padding(.top, 10)
                        .shadow(color: .black.opacity(0.2), radius: 10)
                    
                    VStack(spacing: 25) {
                        Text("\"\(randomQuote)\"")
                            .font(.system(size: 16, weight: .medium, design: .serif))
                            .italic()
                            .foregroundColor(.primary.opacity(0.7))
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 20)
                            .fixedSize(horizontal: false, vertical: true)
                        
                        HStack(alignment: .bottom) {
                            VStack(alignment: .leading, spacing: 4) {
                                Text("ReMinder")
                                    .font(.system(size: 18, weight: .black, design: .rounded))
                                    .tracking(1.2)
                                Text(getFormattedDate())
                                    .font(.system(size: 12, design: .monospaced))
                                    .foregroundColor(.secondary)
                            }
                            Spacer()
                            Image(systemName: "seal.fill")
                                .foregroundStyle(mainGradient)
                                .font(.system(size: 32))
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.bottom, 20)
                }
                .frame(width: 320)
            }
        }
        .background(Color.white)
        //.glassEffect(.clear, in: RoundedRectangle(cornerRadius: 16))
        //.glassEffect(.regular)
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }
    
    var body: some View {
        ZStack {
            ZStack {
                Color.white.ignoresSafeArea()
                backgroundGradient.ignoresSafeArea().opacity(0.15) 
            }
            
            VStack {
                Spacer()
                
                postcardMainContent
                    .shadow(color: .black.opacity(0.1), radius: 30, x: 0, y: 15)
                    .rotationEffect(.degrees(rotation))
                    .scaleEffect(isShowing ? 1 : 0.85)
                    .opacity(isShowing ? 1 : 0)
                
                Spacer()
                
                buttonGroup.padding(.bottom, isPad ? 60 : 40)
            }
        }
        .onAppear {
            if randomQuote.isEmpty {
                randomQuote = Self.quoteLibrary.randomElement() ?? "Beauty is in the fragments."
            }
            rotation = Double.random(in: -1.0...1.0)
            withAnimation(.spring(response: 0.6, dampingFraction: 0.7)) {
                isShowing = true
            }
        }
        .overlay(alignment: .top) {
            if showSaveAlert {
                HStack(spacing: 12) {
                    Image(systemName: "checkmark.seal.fill")
                        .foregroundStyle(mainGradient)
                        .font(.title3)
                    
                    Text("Postcard Saved to Photos")
                        .font(.system(size: isPad ? 20 : 15, weight: .bold, design: .rounded))
                        .foregroundColor(.primary.opacity(0.8))
                }
                .padding(.vertical, 14)
                .padding(.horizontal, 24)
                .background(
                    Capsule()
                        .fill(.clear)
                        .glassEffect(.regular)
                )
                .transition(.move(edge: .top).combined(with: .opacity))
                .padding(.top, 20)
                .zIndex(100)
            }
            
            if showSaveFailedAlert {
                HStack(spacing: 12) {
                    Image(systemName: "xmark.seal.fill")
                        .foregroundStyle(.red)
                        .font(.title3)
                    
                    Text("Unable to Save — Check Photos Permission")
                        .font(.system(size: isPad ? 20 : 15, weight: .bold, design: .rounded))
                        .foregroundColor(.primary.opacity(0.8))
                }
                .padding(.vertical, 14)
                .padding(.horizontal, 24)
                .background(
                    Capsule()
                        .fill(.clear)
                        .glassEffect(.regular)
                )
                .transition(.move(edge: .top).combined(with: .opacity))
                .padding(.top, 20)
                .zIndex(100)
            }
        }
        .navigationBarHidden(true)
    }
    
    private var buttonGroup: some View {
        GlassEffectContainer(spacing: isPad ? 70 : 40) {
            HStack(spacing: isPad ? 70 : 40) {
                Button(action: saveCompletePostcard) {
                    VStack(spacing: isPad ? 12 : 8) {
                        capsuleButton(icon: "arrow.down.to.line")
                        Text("Save")
                            .font(.system(size: isPad ? 16 : 13, weight: .bold))
                            .foregroundColor(.gray)
                    }
                }
                
                Button(action: { dismiss() }) {
                    VStack(spacing: isPad ? 12 : 8) {
                        capsuleButton(icon: "chevron.left")
                        Text("Back")
                            .font(.system(size: isPad ? 16 : 13, weight: .bold))
                            .foregroundColor(.gray)
                    }
                }
                
                Button(action: { navManager.popToRoot() }) {
                    VStack(spacing: isPad ? 12 : 8) {
                        capsuleButton(icon: "house.fill")
                        Text("Home")
                            .font(.system(size: isPad ? 16 : 13, weight: .bold))
                            .foregroundColor(.gray)
                    }
                }
            }
        }
        .foregroundColor(.white)
    }
    
    private func capsuleButton(icon: String) -> some View {
        ZStack {
            Capsule()
                .fill(mainGradient)
                .blur(radius: 10)
            Image(systemName: icon)
                .font(.system(size: isPad ? 28 : 22, weight: .bold))
                .foregroundColor(.black)
                .frame(width: isPad ? 70 : 50, height: isPad ? 70 : 50)
                .background(
                    Capsule()
                        .fill(Color.white)
                )
                .glassEffect(.regular.interactive())
        }
        .frame(width: isPad ? 70 : 50, height: isPad ? 70 : 50)
    }
    
    // MARK: - Export Logic
    
    @MainActor
    
    private func saveCompletePostcard() {
        let renderer = ImageRenderer(content: postcardMainContent)
        renderer.scale = displayScale
        guard let uiImage = renderer.uiImage else { return }
        
        PHPhotoLibrary.shared().performChanges({
            PHAssetChangeRequest.creationRequestForAsset(from: uiImage)
        }) { success, error in
            DispatchQueue.main.async {
                if success {
                    UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                    withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                        showSaveAlert = true
                    }
                    DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                        withAnimation(.easeInOut) {
                            showSaveAlert = false
                        }
                    }
                } else {
                    UINotificationFeedbackGenerator().notificationOccurred(.error)
                    withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                        showSaveFailedAlert = true
                    }
                    DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) {
                        withAnimation(.easeInOut) {
                            showSaveFailedAlert = false
                        }
                    }
                }
            }
        }
    }
    
    private func getFormattedDate() -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d, yyyy" 
        return formatter.string(from: Date())
    }
}
