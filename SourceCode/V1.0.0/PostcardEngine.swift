import SwiftUI
import UIKit

struct PostcardProcessor {
    @MainActor
    static func generatePostcard(
        size: CGSize,
        starCenter: CGPoint,
        starSize: CGFloat,
        instances: [FragmentInstance],
        displayScale: CGFloat
    ) -> UIImage? {
        guard size.width > 0 && size.height > 0 else { return nil }
        
        let renderSize = CGSize(width: starSize, height: starSize)
        let format = UIGraphicsImageRendererFormat.default()
        format.scale = displayScale
        format.opaque = false
        
        let renderer = UIGraphicsImageRenderer(size: renderSize, format: format)
        
        let postcardImage = renderer.image { ctx in
            let cgContext = ctx.cgContext
            let localCenter = CGPoint(x: starSize / 2, y: starSize / 2)
            
            // 1. Create the mathematical path for a 5-point star
            let path = UIBezierPath()
            let points = 5
            let innerRadius = starSize * 0.22
            let outerRadius = starSize * 0.5 
            let angleIncrement = CGFloat.pi * 2 / CGFloat(points * 2)
            
            for i in 0..<(points * 2) {
                let angle = CGFloat(i) * angleIncrement - .pi / 2
                let radius = i % 2 == 0 ? outerRadius : innerRadius
                let x = localCenter.x + cos(angle) * radius
                let y = localCenter.y + sin(angle) * radius
                if i == 0 { 
                    path.move(to: CGPoint(x: x, y: y)) 
                } else { 
                    path.addLine(to: CGPoint(x: x, y: y)) 
                }
            }
            path.close()
            
            // 2. Draw the background base color for the star shape
            cgContext.saveGState()
            UIColor.white.setFill()
            path.fill()
            cgContext.restoreGState()
            
            // 3. Apply the clipping mask so fragments stay within the star boundaries
            cgContext.addPath(path.cgPath)
            cgContext.clip()
            
            // 4. Render each fragment instance relative to the star's center
            for instance in instances {
                let offsetX = instance.position.x - starCenter.x
                let offsetY = instance.position.y - starCenter.y
                
                let rect = CGRect(
                    x: (starSize / 2 + offsetX) - (instance.size.width / 2),
                    y: (starSize / 2 + offsetY) - (instance.size.height / 2),
                    width: instance.size.width,
                    height: instance.size.height
                )
                instance.image.draw(in: rect)
            }
        }
        
        return postcardImage
    }
}
