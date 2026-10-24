import SwiftUI

enum Theme {
    static let purple = Color(red: 156 / 255, green: 58 / 255, blue: 255 / 255) // #9C3AFF
    static let black = Color.black
    static let white = Color.white
    static let dim = Color.white.opacity(0.55)
    static let line = Color.white.opacity(0.25)
}

// The little square grab-handle.
struct SquareHandle: View {
    var filled = false

    var body: some View {
        Rectangle()
            .fill(filled ? Theme.purple : Theme.white)
            .overlay(Rectangle().strokeBorder(Theme.purple, lineWidth: 1))
            .frame(width: 8, height: 8)
    }
}

enum HandleStyle { case all, corners, none }

// Draws a 1pt frame plus handles around any view.
struct SelectionFrame: ViewModifier {
    var handles: HandleStyle
    var color: Color
    var dashed: Bool
    var highlighted: Bool

    func body(content: Content) -> some View {
        content.overlay(
            GeometryReader { geo in
                let w = geo.size.width
                let h = geo.size.height
                ZStack(alignment: .topLeading) {
                    Rectangle()
                        .strokeBorder(color, style: StrokeStyle(lineWidth: 1, dash: dashed ? [6, 4] : []))
                    ForEach(Array(points(w, h).enumerated()), id: \.offset) { _, p in
                        SquareHandle(filled: highlighted)
                            .position(x: p.x, y: p.y)
                    }
                }
            }
            .allowsHitTesting(false)
        )
    }

    private func points(_ w: CGFloat, _ h: CGFloat) -> [CGPoint] {
        let corners = [CGPoint(x: 0, y: 0), CGPoint(x: w, y: 0),
                       CGPoint(x: 0, y: h), CGPoint(x: w, y: h)]
        let edges = [CGPoint(x: w / 2, y: 0), CGPoint(x: 0, y: h / 2),
                     CGPoint(x: w, y: h / 2), CGPoint(x: w / 2, y: h)]
        switch handles {
        case .all: return corners + edges
        case .corners: return corners
        case .none: return []
        }
    }
}

extension View {
    func selectionFrame(_ handles: HandleStyle = .all,
                        color: Color = Theme.purple,
                        dashed: Bool = false,
                        highlighted: Bool = false) -> some View {
        modifier(SelectionFrame(handles: handles, color: color, dashed: dashed, highlighted: highlighted))
    }
}

// Small uppercase label above each section.
struct SectionLabel: View {
    let text: String

    var body: some View {
        Text(text.uppercased())
            .font(.system(size: 10, weight: .semibold, design: .monospaced))
            .tracking(1.5)
            .foregroundStyle(Theme.purple)
            .frame(maxWidth: .infinity, alignment: .leading)
    }
}

// Square, outlined button. `prominent` fills it purple.
struct WireButton: ButtonStyle {
    var prominent = false

    func makeBody(configuration: ButtonStyleConfiguration) -> some View {
        WireButtonBody(configuration: configuration, prominent: prominent)
    }
}

private struct WireButtonBody: View {
    let configuration: ButtonStyleConfiguration
    let prominent: Bool
    @Environment(\.isEnabled) private var isEnabled

    var body: some View {
        configuration.label
            .font(.system(size: 12, weight: .semibold, design: .monospaced))
            .textCase(.uppercase)
            .foregroundStyle(prominent ? Theme.white : Theme.purple)
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
            .background(prominent ? Theme.purple : Color.clear)
            .overlay(Rectangle().strokeBorder(Theme.purple, lineWidth: 1))
            .opacity(isEnabled ? (configuration.isPressed ? 0.7 : 1) : 0.35)
            .contentShape(Rectangle())
    }
}

// Progress bar with a square handle riding the leading edge, like a slider.
struct WireProgress: View {
    let value: Double // 0...1

    var body: some View {
        GeometryReader { geo in
            let w = geo.size.width
            let fraction = CGFloat(min(max(value, 0), 1))
            ZStack(alignment: .topLeading) {
                Rectangle().strokeBorder(Theme.purple, lineWidth: 1)
                Rectangle()
                    .fill(Theme.purple)
                    .frame(width: w * fraction)
                SquareHandle()
                    .position(x: min(max(w * fraction, 4), w - 4), y: geo.size.height / 2)
            }
        }
        .frame(height: 14)
        .animation(.linear(duration: 0.15), value: value)
    }
}