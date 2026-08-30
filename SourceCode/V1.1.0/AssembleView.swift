import SwiftUI
import CoreTransferable
import UniformTypeIdentifiers

struct FragmentInstance: Identifiable {
    let id = UUID()
    let fragment: Fragment
    var position: CGPoint
    var offset: CGSize = .zero
    var image: UIImage      
    var size: CGSize        
    var relativePath: Path
    
    // Scale and rotation states
    var scale: CGFloat = 1.0
    var rotation: Angle = .zero
    var activeScale: CGFloat = 1.0
    var activeRotation: Angle = .zero
}

struct SoulAssemblyView: View {
    @Environment(\.horizontalSizeClass) var sizeClass
    @Environment(\.displayScale) var displayScale
    // Check device type for layout scaling
    var isPad: Bool { sizeClass == .regular }
    
    // Standard size for fragments based on device
    var unifiedSize: CGSize {
        isPad ? CGSize(width: 150, height: 150) : CGSize(width: 100, height: 100)
    }
    
    let originalImage: UIImage
    let fragments: [Fragment]
    let selectedNamedColors: [NamedColor]
    
    @State private var placedInstances: [FragmentInstance] = []
    @State private var processedFragments: [ProcessedFragment] = []
    @State private var isProcessing = true
    @State private var draggingItem: ProcessedFragment? = nil
    @State private var dragLocation: CGPoint = .zero
    @State private var dragOffset: CGSize = .zero
    @State private var currentTipIndex = 0
    @State private var timerTask: Task<Void, Never>? = nil
    @State private var processingProgress: Double = 0.0
    @State private var finalPostcard: UIImage? = nil
    
    @EnvironmentObject var navManager: NavigationManager
    
    struct ProcessedFragment: Identifiable {
        let id = UUID()
        let fragment: Fragment
        let croppedImage: UIImage
        let relativeMaskPath: Path
    }
    
    var body: some View {
        GeometryReader { geo in
            let starSize: CGFloat = isPad ? 400 : 300
            let starCenter = CGPoint(x: geo.size.width / 2, y: geo.size.height / 2.15)
            
            ZStack {
                Color.white.ignoresSafeArea()
                
                // Main canvas area with guide lines and clipping mask
                ZStack {
                    StarShape()
                        .stroke(Color.gray.opacity(0.3), style: StrokeStyle(lineWidth: 2, lineCap: .round, lineJoin: .round, dash: [5]))
                        .frame(width: starSize, height: starSize)
                        .position(starCenter)
                    
                    piecesContainer.opacity(0.3)
                    
                    piecesContainer
                        .mask(
                            StarShape()
                                .frame(width: starSize, height: starSize)
                                .position(starCenter)
                        )
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                
                VStack {
                    headerText
                    
                    Spacer()
                    
                    // Control bar containing Reset, Instruction, and Navigation
                    HStack(alignment: .center) {
                        Button(action: {
                            UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                            placedInstances.removeAll()
                        }) {
                            ZStack{
                                Capsule()
                                    .fill(Color.black.opacity(0.2))
                                    .frame(width: isPad ? 70 : 50, height: isPad ? 70 : 50)
                                    .blur(radius: 10)
                                
                                Image(systemName: "trash")
                                    .font(.system(size: isPad ? 28 : 22, weight: .bold))
                                    .foregroundColor(.red.opacity(0.8))
                                    .frame(width: isPad ? 70 : 50, height: isPad ? 70 : 50)
                                    .background(
                                        Circle()
                                            .fill(Color.white)
                                    )
                                    .glassEffect(.regular.interactive())
                            }
                        }
                        
                        Spacer()
                        
                        ZStack {
                            if currentTipIndex == 0 {
                                Text("Double-tap a fragment to remove it")
                                    .font(.system(size: isPad ? 18 : 14, design: .serif))
                                    .italic()
                                    .foregroundColor(.black.opacity(0.6))
                                    .padding(.horizontal, 20)
                                    .transition(.asymmetric(
                                        insertion: .opacity.combined(with: .move(edge: .bottom)),
                                        removal: .opacity.combined(with: .move(edge: .top))
                                    ))
                                    .multilineTextAlignment(.center)
                            } else {
                                Text("Pinch & rotate with two fingers to resize and turn")
                                    .font(.system(size: isPad ? 18 : 14, design: .serif))
                                    .italic()
                                    .foregroundColor(.black.opacity(0.6))
                                    .padding(.horizontal, 20)
                                    .transition(.asymmetric(
                                        insertion: .opacity.combined(with: .move(edge: .bottom)),
                                        removal: .opacity.combined(with: .move(edge: .top))
                                    ))
                                    .multilineTextAlignment(.center)
                            }
                        }
                        .frame(height: 50)
                        .onAppear {
                            startTimer()
                        }
                        .onDisappear {
                            stopTimer()
                        }
                        
                        Spacer()
                        
                        Button(action: {
                            let currentStarSize: CGFloat = isPad ? 400 : 300
                            let currentStarCenter = CGPoint(x: geo.size.width / 2, y: geo.size.height / 2.15)
                            
                            // Render the final composition into an image
                            if let result = PostcardProcessor.generatePostcard(
                                size: geo.size, 
                                starCenter: currentStarCenter, 
                                starSize: currentStarSize, 
                                instances: placedInstances,
                                displayScale: displayScale
                            ) {
                                self.finalPostcard = result
                                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                                    navManager.path.append(AppPage.postcard(image: result, colors: selectedNamedColors))
                                }
                            }
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
                        }
                    }
                    .padding(.horizontal, 25)
                    .padding(.bottom, 10)
                    
                    if !isProcessing {
                        fragmentPicker(geo: geo)
                    }
                }
                
                if isProcessing {
                    loadingOverlay
                }
                
                if let dragItem = draggingItem {
                    let imgSize = dragItem.croppedImage.size
                    let scale = min(unifiedSize.width / imgSize.width, unifiedSize.height / imgSize.height)
                    let actualSize = CGSize(width: imgSize.width * scale, height: imgSize.height * scale)
                    
                    Image(uiImage: dragItem.croppedImage)
                        .resizable()
                        .scaledToFit()
                        .frame(width: actualSize.width, height: actualSize.height)
                        .position(dragLocation)
                        .opacity(0.8)
                        .zIndex(999)
                }
            }
            .coordinateSpace(name: "canvas")
            .navigationBarHidden(true)
            .onAppear {
                startProcessing()
            }
        }
    }
    
    // MARK: - UI Components
    
    private var headerText: some View {
        VStack(spacing: 10) {
            Text("Build your star of hope")
                .font(.system(size: isPad ? 35 : 24, weight: .black, design: .rounded))
                .multilineTextAlignment(.center)
                .padding(.horizontal, 20)
                .padding(.top, 40)
            
            Text("Drag a fragment from the bar below and drop it onto the canvas. Arrange them to rebuild your Star of Hope.")
                .font(.system(size: isPad ? 25 : 16, design: .serif))
                .italic()
                .foregroundColor(.black.opacity(0.6))
                .multilineTextAlignment(.center)
                .padding(.horizontal, 20)
        }
    }
    
    private var piecesContainer: some View {
        ZStack {
            ForEach(placedInstances) { instance in
                fragmentNode(instance: instance)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    @ViewBuilder
    private func fragmentNode(instance: FragmentInstance) -> some View {
        let instanceID = instance.id
        Image(uiImage: instance.image)
            .resizable()
            .scaledToFit()
            .frame(width: instance.size.width, height: instance.size.height)
            .contentShape(instance.relativePath)
            .scaleEffect(instance.offset == .zero ? 1.0 : 1.05) // Drag lift scale
            .scaleEffect(instance.scale * instance.activeScale) // Custom zoom scale
            .rotationEffect(instance.rotation + instance.activeRotation) // Custom rotation
            .shadow(
                color: Color.black.opacity(instance.offset == .zero ? 0.1 : 0.3), 
                radius: instance.offset == .zero ? 3 : 10
            )
            .position(
                x: instance.position.x + instance.offset.width, 
                y: instance.position.y + instance.offset.height
            )
            .animation(.interactiveSpring(), value: instance.offset)
            .gesture(
                DragGesture()
                    .onChanged { value in
                        guard let i = placedInstances.firstIndex(where: { $0.id == instanceID }) else { return }
                        placedInstances[i].offset = value.translation
                    }
                    .onEnded { value in
                        guard let i = placedInstances.firstIndex(where: { $0.id == instanceID }) else { return }
                        placedInstances[i].position.x += value.translation.width
                        placedInstances[i].position.y += value.translation.height
                        placedInstances[i].offset = .zero
                        
                        // Move selected item to front of ZStack
                        let movedItem = placedInstances.remove(at: i)
                        placedInstances.append(movedItem)
                    }
                    .simultaneously(with: 
                                        MagnificationGesture()
                        .onChanged { value in
                            guard let i = placedInstances.firstIndex(where: { $0.id == instanceID }) else { return }
                            placedInstances[i].activeScale = value
                        }
                        .onEnded { value in
                            guard let i = placedInstances.firstIndex(where: { $0.id == instanceID }) else { return }
                            placedInstances[i].scale *= value
                            placedInstances[i].activeScale = 1.0
                        }
                                   )
                    .simultaneously(with:
                                        RotationGesture()
                        .onChanged { value in
                            guard let i = placedInstances.firstIndex(where: { $0.id == instanceID }) else { return }
                            placedInstances[i].activeRotation = value
                        }
                        .onEnded { value in
                            guard let i = placedInstances.firstIndex(where: { $0.id == instanceID }) else { return }
                            placedInstances[i].rotation += value
                            placedInstances[i].activeRotation = .zero
                        }
                                   )
            )
            .onTapGesture(count: 2) {
                placedInstances.removeAll(where: { $0.id == instanceID })
            }
    }
    
    private var loadingOverlay: some View {
        ZStack {
            Color.white.ignoresSafeArea()
            VStack(spacing: 25) {
                ZStack {
                    Circle()
                        .stroke(Color.gray.opacity(0.1), lineWidth: 12)
                        .frame(width: isPad ? 150 : 120, height: isPad ? 150 : 120)
                    
                    Circle()
                        .trim(from: 0, to: CGFloat(processingProgress / Double(fragments.count)))
                        .stroke(
                            LinearGradient(
                                colors: selectedNamedColors.map { $0.color },
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            style: StrokeStyle(lineWidth: isPad ? 15 : 12, lineCap: .round)
                        )
                        .frame(width: isPad ? 150 : 120, height: isPad ? 150 : 120)
                        .rotationEffect(.degrees(-90))
                        .animation(.linear(duration: 0.1), value: processingProgress)
                    
                    Text("\(Int((processingProgress / Double(fragments.count)) * 100))%")
                        .monospacedDigit()
                        .font(.system(size: isPad ? 28 : 24, weight: .black, design: .rounded))
                        .foregroundColor(.black)
                        .contentTransition(.identity) 
                }
                
                Text("Fragments is processing")
                    .font(.system(size: isPad ? 20 : 16, weight: .bold, design: .rounded))
                    .foregroundColor(.black)
            }
        }
        .transition(.opacity)
    }
    
    private func fragmentPicker(geo: GeometryProxy) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            Text("Your Emotion Fragments")
                .frame(maxWidth: .infinity)
                .font(.system(size: isPad ? 16 : 13, weight: .bold))
                .foregroundColor(.gray)
                .padding(.top, 12)
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 15) {
                    ForEach(processedFragments) { item in
                        GeometryReader { itemGeo in
                            ZStack {
                                RoundedRectangle(cornerRadius: 15)
                                    .fill(Color.clear)
                                    .frame(width: isPad ? 70 : 60, height: isPad ? 70 : 60)
                                
                                Image(uiImage: item.croppedImage)
                                    .resizable()
                                    .scaledToFit()
                                    .frame(width: isPad ? 50 : 44, height: isPad ? 50 : 44)
                                    .shadow(color: Color.black.opacity(0.35), radius: 5)
                            }
                            .contentShape(Rectangle())
                            .onTapGesture {
                                let starCenter = CGPoint(x: geo.size.width / 2, y: geo.size.height / 2.15)
                                let imgSize = item.croppedImage.size
                                let scale = min(unifiedSize.width / imgSize.width, unifiedSize.height / imgSize.height)
                                let actualSize = CGSize(width: imgSize.width * scale, height: imgSize.height * scale)
                                
                                let scaleX = actualSize.width / imgSize.width
                                let scaleY = actualSize.height / imgSize.height
                                let scaledPath = item.relativeMaskPath.applying(CGAffineTransform(scaleX: scaleX, y: scaleY))
                                
                                let new = FragmentInstance(
                                    fragment: item.fragment,
                                    position: starCenter,
                                    image: item.croppedImage,
                                    size: actualSize,
                                    relativePath: scaledPath
                                )
                                UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                                withAnimation(.spring(response: 0.35, dampingFraction: 0.75)) {
                                    placedInstances.append(new)
                                }
                            }
                            .simultaneousGesture(
                                DragGesture(minimumDistance: 24, coordinateSpace: .named("canvas"))
                                    .onChanged { value in
                                        if draggingItem == nil {
                                            // Only trigger dragging if moving upwards and mostly vertically
                                            if value.translation.height < -5 && abs(value.translation.height) > abs(value.translation.width) {
                                                draggingItem = item
                                                let frame = itemGeo.frame(in: .named("canvas"))
                                                let itemCenter = CGPoint(x: frame.midX, y: frame.midY)
                                                let rawOffset = CGSize(
                                                    width: value.startLocation.x - itemCenter.x,
                                                    height: value.startLocation.y - itemCenter.y
                                                )
                                                
                                                let pickerLimit: CGFloat = isPad ? 50 : 44
                                                let unifiedLimit: CGFloat = isPad ? 150 : 100
                                                let imgSize = item.croppedImage.size
                                                
                                                let pickerScale = min(pickerLimit / imgSize.width, pickerLimit / imgSize.height)
                                                let canvasScale = min(unifiedLimit / imgSize.width, unifiedLimit / imgSize.height)
                                                let ratio = canvasScale / pickerScale
                                                
                                                dragOffset = CGSize(
                                                    width: rawOffset.width * ratio,
                                                    height: rawOffset.height * ratio
                                                )
                                                UIImpactFeedbackGenerator(style: .light).impactOccurred()
                                            } else {
                                                return
                                            }
                                        }
                                        
                                        if draggingItem?.id == item.id {
                                            dragLocation = CGPoint(
                                                x: value.location.x - dragOffset.width,
                                                y: value.location.y - dragOffset.height
                                            )
                                        }
                                    }
                                    .onEnded { value in
                                        if draggingItem?.id == item.id {
                                            let finalDropLocation = CGPoint(
                                                x: value.location.x - dragOffset.width,
                                                y: value.location.y - dragOffset.height
                                            )
                                            
                                            if finalDropLocation.y < geo.size.height - 160 {
                                                let imgSize = item.croppedImage.size
                                                let scale = min(unifiedSize.width / imgSize.width, unifiedSize.height / imgSize.height)
                                                let actualSize = CGSize(width: imgSize.width * scale, height: imgSize.height * scale)
                                                
                                                let scaleX = actualSize.width / imgSize.width
                                                let scaleY = actualSize.height / imgSize.height
                                                let scaledPath = item.relativeMaskPath.applying(CGAffineTransform(scaleX: scaleX, y: scaleY))
                                                
                                                let new = FragmentInstance(
                                                    fragment: item.fragment,
                                                    position: finalDropLocation,
                                                    image: item.croppedImage,
                                                    size: actualSize,
                                                    relativePath: scaledPath
                                                )
                                                withAnimation(.spring(response: 0.35, dampingFraction: 0.75)) {
                                                    placedInstances.append(new)
                                                }
                                            }
                                        }
                                        
                                        draggingItem = nil
                                        dragLocation = .zero
                                        dragOffset = .zero
                                    }
                            )
                        }
                        .frame(width: isPad ? 70 : 60, height: isPad ? 70 : 60)
                    }
                }
                .padding(.horizontal, 18)
                .padding(.bottom, 10)
            }
            .frame(height: isPad ? 100 : 90)
            .scrollDisabled(draggingItem != nil)
        }
        .background(.ultraThinMaterial)
        .clipShape(
            RoundedRectangle(cornerRadius: isPad ? 50 : 35, style: .continuous)
        )
        .glassEffect(.regular, in: RoundedRectangle(cornerRadius: isPad ? 50 : 35, style: .continuous))
        .shadow(color: Color.black.opacity(0.2), radius: 10, x: 0, y: 0)
        .padding(.horizontal, 15)
        .padding(.bottom, 20)
    }
    
    struct StarShape: Shape {
        func path(in rect: CGRect) -> Path {
            var path = Path()
            let center = CGPoint(x: rect.midX, y: rect.midY)
            let points = 5
            let innerRadius = rect.width * 0.22
            let outerRadius = rect.width * 0.5
            let angleIncrement = .pi * 2 / CGFloat(points * 2)
            
            for i in 0..<(points * 2) {
                let angle = CGFloat(i) * angleIncrement - .pi / 2
                let radius = i % 2 == 0 ? outerRadius : innerRadius
                let x = center.x + cos(angle) * radius
                let y = center.y + sin(angle) * radius
                if i == 0 { path.move(to: CGPoint(x: x, y: y)) } else { path.addLine(to: CGPoint(x: x, y: y)) }
            }
            path.closeSubpath()
            return path
        }
    }
    
    // Asynchronously process fragment masking and cropping
    private func startProcessing() {
        let imgScale = originalImage.scale
        DispatchQueue.global(qos: .userInitiated).async {
            var results: [ProcessedFragment] = []
            for (index, frag) in fragments.enumerated() {
                DispatchQueue.main.async { 
                    withAnimation(.linear(duration: 0.1)) { self.processingProgress = Double(index + 1) } 
                }
                
                let bounds = frag.maskPath.boundingRect
                if bounds.width < 1 || bounds.height < 1 { continue }
                
                let format = UIGraphicsImageRendererFormat()
                format.scale = imgScale
                
                let renderer = UIGraphicsImageRenderer(size: bounds.size, format: format)
                let uncropped = renderer.image { ctx in
                    ctx.cgContext.translateBy(x: -bounds.origin.x, y: -bounds.origin.y)
                    ctx.cgContext.addPath(frag.maskPath.cgPath)
                    ctx.cgContext.clip()
                    originalImage.draw(at: .zero)
                }
                
                // Crop the transparent edges to get the tightest content box
                if let contentBox = uncropped.findActualContentRect(), contentBox.width >= 25, contentBox.height >= 25 {
                    if let cg = uncropped.cgImage?.cropping(to: contentBox) {
                        let croppedImg = UIImage(cgImage: cg, scale: imgScale, orientation: .up)
                        let pathInUncropped = frag.maskPath.applying(CGAffineTransform(translationX: -bounds.origin.x, y: -bounds.origin.y))
                        let pathInCropped = pathInUncropped.applying(CGAffineTransform(translationX: -contentBox.origin.x / imgScale, y: -contentBox.origin.y / imgScale))
                        
                        results.append(ProcessedFragment(
                            fragment: frag, 
                            croppedImage: croppedImg,
                            relativeMaskPath: pathInCropped
                        ))
                    }
                }
            }
            DispatchQueue.main.async { 
                withAnimation { 
                    self.processedFragments = results
                    self.isProcessing = false 
                } 
            }
        }
    }
    
    private func startTimer() {
        timerTask?.cancel()
        timerTask = Task {
            while !Task.isCancelled {
                do {
                    try await Task.sleep(nanoseconds: 5_000_000_000)
                    if Task.isCancelled { break }
                    await MainActor.run {
                        withAnimation(.easeInOut(duration: 0.5)) {
                            currentTipIndex = (currentTipIndex + 1) % 2
                        }
                    }
                } catch {
                    break
                }
            }
        }
    }
    
    private func stopTimer() {
        timerTask?.cancel()
        timerTask = nil
    }
}

extension UIImage {
    // Scans image pixels to find the non-transparent bounding box
    func findActualContentRect() -> CGRect? {
        guard let cgImage = self.cgImage else { return nil }
        let width = cgImage.width
        let height = cgImage.height
        let bytesPerPixel = 4
        let bytesPerRow = width * bytesPerPixel
        var rawData = [UInt8](repeating: 0, count: width * height * bytesPerPixel)
        
        guard let context = CGContext(
            data: &rawData, 
            width: width, 
            height: height, 
            bitsPerComponent: 8, 
            bytesPerRow: bytesPerRow, 
            space: CGColorSpaceCreateDeviceRGB(), 
            bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
        ) else { return nil }
        
        context.draw(cgImage, in: CGRect(x: 0, y: 0, width: width, height: height))
        
        var minX = width, minY = height, maxX = 0, maxY = 0
        var found = false
        
        for y in 0..<height {
            for x in 0..<width {
                // Threshold of 10 for alpha channel detection
                if rawData[((y * width) + x) * 4 + 3] > 10 {
                    if x < minX { minX = x }
                    if x > maxX { maxX = x }
                    if y < minY { minY = y }
                    if y > maxY { maxY = y }
                    found = true
                }
            }
        }
        
        return found ? CGRect(
            x: CGFloat(minX), 
            y: CGFloat(minY), 
            width: CGFloat(maxX - minX + 1), 
            height: CGFloat(maxY - minY + 1)
        ) : nil
    }
}
