import SwiftUI

struct AmazonLandscape: View {
    var body: some View {
        Canvas { context, size in
            var canopy = Path()
            canopy.move(to: CGPoint(x: 0, y: size.height * 0.55))
            canopy.addCurve(to: CGPoint(x: size.width * 0.48, y: size.height * 0.62),
                            control1: CGPoint(x: size.width * 0.13, y: size.height * 0.35),
                            control2: CGPoint(x: size.width * 0.35, y: size.height * 0.76))
            canopy.addCurve(to: CGPoint(x: size.width, y: size.height * 0.53),
                            control1: CGPoint(x: size.width * 0.7, y: size.height * 0.47),
                            control2: CGPoint(x: size.width * 0.87, y: size.height * 0.31))
            canopy.addLine(to: CGPoint(x: size.width, y: size.height))
            canopy.addLine(to: CGPoint(x: 0, y: size.height))
            canopy.closeSubpath()
            context.fill(canopy, with: .color(GameTheme.forest.opacity(0.3)))

            var river = Path()
            river.move(to: CGPoint(x: 0, y: size.height * 0.77))
            river.addCurve(to: CGPoint(x: size.width, y: size.height * 0.68),
                           control1: CGPoint(x: size.width * 0.34, y: size.height * 0.67),
                           control2: CGPoint(x: size.width * 0.64, y: size.height * 0.91))
            river.addLine(to: CGPoint(x: size.width, y: size.height * 0.88))
            river.addCurve(to: CGPoint(x: 0, y: size.height * 0.95),
                           control1: CGPoint(x: size.width * 0.67, y: size.height * 0.87),
                           control2: CGPoint(x: size.width * 0.32, y: size.height))
            river.closeSubpath()
            context.fill(river, with: .color(Color(red: 0.15, green: 0.57, blue: 0.68).opacity(0.38)))

            for index in 0..<5 {
                let x = size.width * (0.05 + CGFloat(index) * 0.225)
                let trunk = Path { path in
                    path.move(to: CGPoint(x: x, y: size.height * 0.63))
                    path.addQuadCurve(to: CGPoint(x: x + 12, y: size.height * 0.38),
                                      control: CGPoint(x: x - 5, y: size.height * 0.51))
                }
                context.stroke(trunk, with: .color(GameTheme.forest.opacity(0.35)), lineWidth: 4)
                for leaf in -2...2 {
                    let frond = Path { path in
                        path.move(to: CGPoint(x: x + 12, y: size.height * 0.38))
                        path.addQuadCurve(to: CGPoint(x: x + 12 + CGFloat(leaf) * 23, y: size.height * 0.34),
                                          control: CGPoint(x: x + 12 + CGFloat(leaf) * 16, y: size.height * 0.29))
                    }
                    context.stroke(frond, with: .color(GameTheme.forest.opacity(0.35)), lineWidth: 3)
                }
            }
        }
        .ignoresSafeArea()
        .accessibilityHidden(true)
        .allowsHitTesting(false)
    }
}
