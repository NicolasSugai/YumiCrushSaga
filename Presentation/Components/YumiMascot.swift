import SwiftUI

enum YumiMood { case happy, neutral, encouraging, celebration }

/// Original, replaceable vector portrait drawn after inspecting the private photo reference.
/// The photo itself is never bundled or copied into the application.
struct YumiMascot: View {
    var mood: YumiMood = .happy
    var scale: CGFloat = 1
    private let skin = Color(red: 0.91, green: 0.70, blue: 0.57)
    private let hair = Color(red: 0.12, green: 0.085, blue: 0.09)
    var body: some View {
        ZStack {
            Circle().fill(GameTheme.tucupi.opacity(0.18)).frame(width: 190, height: 190)
            Ellipse().fill(hair).frame(width: 133, height: 151).offset(x: 1, y: -15)
            HStack(spacing: 0) {
                WaveLock(color: hair).frame(width: 38, height: 106).rotationEffect(.degrees(-11))
                WaveLock(color: hair).frame(width: 39, height: 113).rotationEffect(.degrees(8))
            }.offset(x: 4, y: 21)
            HStack(spacing: 87) {
                Circle().fill(skin).frame(width: 16, height: 23)
                Circle().fill(skin).frame(width: 16, height: 23)
            }.offset(y: -12)
            Ellipse().fill(skin).frame(width: 101, height: 119).offset(y: -12)
            TopHair(color: hair).frame(width: 104, height: 58).offset(y: -48)
            // Gentle swept-back strands echo the hairstyle in the photo without adding bangs.
            HairStrand().stroke(Color.white.opacity(0.13), style: StrokeStyle(lineWidth: 1.4, lineCap: .round))
                .frame(width: 47, height: 19).offset(x: 1, y: -67)
            HStack(spacing: 25) {
                Eye().frame(width: 12, height: 9)
                Eye().frame(width: 12, height: 9)
            }.offset(y: -12)
            HStack(spacing: 20) {
                Capsule().fill(hair).frame(width: 19, height: 2.5).rotationEffect(.degrees(-7))
                Capsule().fill(hair).frame(width: 19, height: 2.5).rotationEffect(.degrees(7))
            }.offset(y: -25)
            Ellipse().fill(Color(red: 0.78, green: 0.48, blue: 0.40).opacity(0.45))
                .frame(width: 5, height: 7).offset(y: 3)
            if mood == .neutral {
                Capsule().fill(Color(red: 0.47, green: 0.19, blue: 0.18)).frame(width: 20, height: 3).offset(y: 20)
            } else {
                Smile().fill(Color(red: 0.34, green: 0.12, blue: 0.13)).frame(width: 37, height: 24).offset(y: 19)
                RoundedRectangle(cornerRadius: 4).fill(Color(red: 1, green: 0.96, blue: 0.88))
                    .frame(width: 27, height: 6).offset(y: 13)
                if mood == .encouraging {
                    Circle().fill(Color(red: 0.82, green: 0.38, blue: 0.34).opacity(0.35)).frame(width: 19, height: 9).offset(x: -31, y: 12)
                    Circle().fill(Color(red: 0.82, green: 0.38, blue: 0.34).opacity(0.35)).frame(width: 19, height: 9).offset(x: 31, y: 12)
                }
            }
            Ellipse().fill(GameTheme.forest).frame(width: 145, height: 72).offset(y: 83)
            Ellipse().fill(GameTheme.tucupi).frame(width: 27, height: 8).offset(y: 56)
            Text("Y").font(.system(size: 19, weight: .black, design: .rounded)).foregroundStyle(GameTheme.cupuacu).offset(y: 82)
            if mood == .celebration {
                Text("✦").font(.system(size: 34)).foregroundStyle(GameTheme.tucupi).offset(x: 73, y: -70)
                Text("✦").font(.system(size: 24)).foregroundStyle(.white).offset(x: -75, y: -38)
            }
        }
        .frame(width: 200, height: 210)
        .scaleEffect(scale)
        .accessibilityLabel("Yumi, mascote cartoon original baseado na fotografia de referência")
    }
}

private struct Eye: View {
    var body: some View {
        Ellipse().fill(Color(red: 0.20, green: 0.12, blue: 0.12))
            .overlay(alignment: .topTrailing) { Circle().fill(.white.opacity(0.9)).frame(width: 3, height: 3).padding(2) }
    }
}

private struct WaveLock: Shape {
    let color: Color
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: rect.width * 0.65, y: 0))
        path.addCurve(to: CGPoint(x: rect.width * 0.48, y: rect.height * 0.43), control1: CGPoint(x: rect.width * 1.2, y: rect.height * 0.2), control2: CGPoint(x: -rect.width * 0.1, y: rect.height * 0.18))
        path.addCurve(to: CGPoint(x: rect.width * 0.62, y: rect.height * 0.79), control1: CGPoint(x: rect.width * 1.25, y: rect.height * 0.59), control2: CGPoint(x: -rect.width * 0.02, y: rect.height * 0.62))
        path.addCurve(to: CGPoint(x: rect.width * 0.31, y: rect.height), control1: CGPoint(x: rect.width * 1.1, y: rect.height * 0.91), control2: CGPoint(x: rect.width * 0.49, y: rect.height * 0.93))
        path.addLine(to: CGPoint(x: rect.width * 0.04, y: rect.height * 0.94))
        path.addCurve(to: CGPoint(x: rect.width * 0.22, y: rect.height * 0.08), control1: CGPoint(x: -rect.width * 0.2, y: rect.height * 0.72), control2: CGPoint(x: rect.width * 0.23, y: rect.height * 0.32))
        path.closeSubpath()
        return path
    }
}

private struct TopHair: Shape {
    let color: Color
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: rect.width * 0.03, y: rect.height))
        path.addCurve(to: CGPoint(x: rect.width * 0.18, y: rect.height * 0.13), control1: CGPoint(x: rect.width * 0.03, y: rect.height * 0.33), control2: CGPoint(x: rect.width * 0.20, y: rect.height * 0.07))
        path.addCurve(to: CGPoint(x: rect.width * 0.87, y: rect.height * 0.12), control1: CGPoint(x: rect.width * 0.34, y: -rect.height * 0.04), control2: CGPoint(x: rect.width * 0.73, y: -rect.height * 0.03))
        path.addCurve(to: CGPoint(x: rect.width * 0.97, y: rect.height), control1: CGPoint(x: rect.width * 0.88, y: rect.height * 0.13), control2: CGPoint(x: rect.width * 0.99, y: rect.height * 0.45))
        path.addCurve(to: CGPoint(x: rect.width * 0.03, y: rect.height), control1: CGPoint(x: rect.width * 0.73, y: rect.height * 0.75), control2: CGPoint(x: rect.width * 0.28, y: rect.height * 0.75))
        path.closeSubpath()
        return path
    }
}

private struct HairStrand: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: 0, y: rect.height * 0.8))
        path.addCurve(to: CGPoint(x: rect.width, y: rect.height * 0.55), control1: CGPoint(x: rect.width * 0.3, y: 0), control2: CGPoint(x: rect.width * 0.7, y: rect.height * 0.1))
        return path
    }
}

private struct Smile: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: 0, y: rect.height * 0.12))
        path.addQuadCurve(to: CGPoint(x: rect.width, y: rect.height * 0.12), control: CGPoint(x: rect.width / 2, y: rect.height * 0.5))
        path.addQuadCurve(to: CGPoint(x: rect.width / 2, y: rect.height), control: CGPoint(x: rect.width * 0.55, y: rect.height * 1.05))
        path.addQuadCurve(to: CGPoint(x: 0, y: rect.height * 0.12), control: CGPoint(x: rect.width * 0.42, y: rect.height * 1.05))
        path.closeSubpath()
        return path
    }
}
