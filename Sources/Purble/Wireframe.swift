import SwiftUI

enum Theme {
    static let purple = Color(red: 156 / 255, green: 58 / 255, blue: 255 / 255) // #9C3AFF
    static let black = Color.black
    static let white = Color.white
    static let dim = Color.white.opacity(0.55)
    static let line = Color.white.opacity(0.25)
}

// A 1pt frame, solid or dotted, around any view.
struct SelectionFrame: ViewModifier {
    var color: Color
    var dashed: Bool

    func body(content: Content) -> some View {
        content.overlay(
            Rectangle()
                .strokeBorder(color, style: StrokeStyle(lineWidth: 1, dash: dashed ? [6, 4] : []))
                .allowsHitTesting(false)
        )
    }
}

extension View {
    func selectionFrame(color: Color = Theme.purple, dashed: Bool = false) -> some View {
        modifier(SelectionFrame(color: color, dashed: dashed))
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

// Square progress bar: outlined track, solid purple fill.
struct WireProgress: View {
    let value: Double // 0...1

    var body: some View {
        GeometryReader { geo in
            ZStack(alignment: .leading) {
                Rectangle().strokeBorder(Theme.purple, lineWidth: 1)
                Rectangle()
                    .fill(Theme.purple)
                    .frame(width: geo.size.width * CGFloat(min(max(value, 0), 1)))
            }
        }
        .frame(height: 14)
        .animation(.linear(duration: 0.15), value: value)
    }
}