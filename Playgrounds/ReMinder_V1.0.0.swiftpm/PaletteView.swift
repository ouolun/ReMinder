import SwiftUI

struct NamedColor: Identifiable, Hashable {
    let id = UUID()
    let name: String
    let color: Color
    let isLight: Bool
}

enum ColorPalette {
    static let options: [NamedColor] = [
        NamedColor(name: "Black", color: .black, isLight: false),
        NamedColor(name: "Gray", color: .gray, isLight: false),
        NamedColor(name: "Light Gray", color: Color(uiColor: .systemGray4), isLight: true),
        NamedColor(name: "Red", color: .red, isLight: false),
        NamedColor(name: "Crimson", color: Color(red: 0.8, green: 0.0, blue: 0.2), isLight: false),
        NamedColor(name: "Pink", color: .pink, isLight: true),
        NamedColor(name: "Coral", color: Color(red: 1.0, green: 0.5, blue: 0.4), isLight: true),
        NamedColor(name: "Orange", color: .orange, isLight: true),
        NamedColor(name: "Yellow", color: .yellow, isLight: true),
        NamedColor(name: "Chartreuse", color: Color(red: 0.5, green: 1.0, blue: 0.0), isLight: true),
        NamedColor(name: "Green", color: .green, isLight: false),
        NamedColor(name: "Mint", color: .mint, isLight: true),
        NamedColor(name: "Teal", color: .teal, isLight: false),
        NamedColor(name: "Dark Green", color: Color(red: 0.0, green: 0.4, blue: 0.0), isLight: false),
        NamedColor(name: "Cyan", color: .cyan, isLight: true),
        NamedColor(name: "Sky Blue", color: Color(red: 0.5, green: 0.8, blue: 1.0), isLight: true),
        NamedColor(name: "Blue", color: .blue, isLight: false),
        NamedColor(name: "Indigo", color: .indigo, isLight: false),
        NamedColor(name: "Navy", color: Color(red: 0.0, green: 0.0, blue: 0.5), isLight: false),
        NamedColor(name: "Purple", color: .purple, isLight: false),
        NamedColor(name: "Magenta", color: Color(red: 1.0, green: 0.0, blue: 1.0), isLight: false),
        NamedColor(name: "Brown", color: Color(uiColor: .systemBrown), isLight: false)
    ]
}

struct Palette: View {
    @Environment(\.horizontalSizeClass) var sizeClass
    var isPad: Bool { sizeClass == .regular }
    
    @EnvironmentObject var navManager: NavigationManager
    @State private var selectedNamedColors: [NamedColor] = []
    
    // Grid configuration adjusted for device screen size
    var rows: [GridItem] {
        isPad ? [GridItem(.fixed(60))] : [GridItem(.fixed(46)), GridItem(.fixed(46))]
    }
    
    var bubbleSize: CGFloat { isPad ? 235 : 135 }
    var spacingFactor: CGFloat { isPad ? 0.8 : 0.6 }
    
    var body: some View {
        ZStack {
            Color.white.ignoresSafeArea()
            
            // Visual representation of selected emotions
            bubblesSection
            
            VStack {
                headerText
                
                Spacer()
                
                HStack {
                    Spacer()
                    
                    // Navigation appears only when the required count is met
                    if selectedNamedColors.count == 3 {
                        Button(action: {
                            navManager.path.append(AppPage.drawing(colors: selectedNamedColors))
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
                        .transition(.move(edge: .trailing).combined(with: .opacity))
                    }
                }
                .padding(.trailing, 15)
                .padding(.bottom, 10)
                
                bottomPicker
            }
        }
        .navigationBarBackButtonHidden(true)
    }
    
    // MARK: - UI Components
    
    private var bubblesSection: some View {
        ZStack {
            ForEach(Array(selectedNamedColors.enumerated()), id: \.element.id) { index, namedColor in
                Circle()
                    .fill(namedColor.color.opacity(0.85))
                    .frame(width: bubbleSize, height: bubbleSize)
                    .shadow(color: namedColor.color.opacity(0.8), radius: 10)
                    .overlay(
                        Text(namedColor.name)
                            .font(.system(size: isPad ? 28 : 18, weight: .black, design: .rounded))
                            .foregroundColor(namedColor.isLight ? .black : .white)
                            .rotationEffect(.degrees(Double(index * 12 - 6)))
                    )
                    .offset(
                        x: CGFloat(index - (selectedNamedColors.count - 1)) * (bubbleSize * spacingFactor)
                        + CGFloat(selectedNamedColors.count - 1) * (bubbleSize * (spacingFactor / 2)),
                        y: index.isMultiple(of: 2) ? -30 : 30
                    )
                    .rotationEffect(.degrees(index.isMultiple(of: 2) ? -8 : 8))
                    .zIndex(Double(index))
                    .transition(.scale.combined(with: .opacity))
            }
        }
        .offset(y: -25)
    }
    
    private var headerText: some View {
        VStack(spacing: 10) {
            Text("Explore your negative emotions")
                .font(.system(size: isPad ? 35 : 24, weight: .black, design: .rounded))
                .multilineTextAlignment(.center)
                .padding(.horizontal, 20)
                .padding(.top, 40)
            
            Text("Choose three colors that best represent the negative emotions you’ve been feeling lately.")
                .font(.system(size: isPad ? 25 : 16, design: .serif))
                .italic()
                .foregroundColor(.black.opacity(0.6))
                .multilineTextAlignment(.center)
                .padding(.horizontal, 20)
        }
    }
    
    private var bottomPicker: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text("Color Palette")
                .frame(maxWidth: .infinity)
                .font(.system(size: isPad ? 16 : 13, weight: .bold))
                .foregroundColor(.gray)
                .padding(.top, 12)
                .padding(.bottom, 2)
            
            ScrollView(.horizontal, showsIndicators: false) {
                LazyHGrid(rows: rows, spacing: 10) {
                    ForEach(ColorPalette.options) { namedColor in
                        Button {
                            handleSelection(namedColor: namedColor)
                        } label: {
                            Circle()
                                .fill(namedColor.color)
                                .frame(width: isPad ? 55 : 44, height: isPad ? 55 : 44)
                                .overlay(
                                    Circle().stroke(
                                        Color.white,
                                        lineWidth: selectedNamedColors.contains(namedColor) ? 3 : 0
                                    )
                                )
                                .overlay(
                                    selectedNamedColors.contains(namedColor)
                                    ? Image(systemName: "checkmark")
                                        .font(.system(size: 20, weight: .black))
                                        .foregroundColor(namedColor.isLight ? .black : .white)
                                    : nil
                                )
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.horizontal, 18)
            }
            .frame(height: isPad ? 90 : 130)
        }
        
        .clipShape(RoundedRectangle(cornerRadius: isPad ? 50 : 35, style: .continuous))
        .glassEffect(.regular, in: RoundedRectangle(cornerRadius: isPad ? 50 : 35, style: .continuous))
        .shadow(color: Color.black.opacity(0.2), radius: 10, x: 0, y: 0)
        .padding(.horizontal, 15)
        .padding(.bottom, 20)
    }
    
    // MARK: - Logic
    
    // Limits selection to 3 colors using a First-In-First-Out approach if limit is exceeded
    private func handleSelection(namedColor: NamedColor) {
        withAnimation(.spring(response: 0.45, dampingFraction: 0.7)) {
            if let index = selectedNamedColors.firstIndex(of: namedColor) {
                selectedNamedColors.remove(at: index)
            } else {
                if selectedNamedColors.count >= 3 {
                    selectedNamedColors.removeFirst()
                }
                selectedNamedColors.append(namedColor)
            }
        }
    }
}
