import SwiftUI

enum HeadlyTheme {
    static let background = Color(red: 0.965, green: 0.961, blue: 0.937)
    static let paper = Color(red: 0.998, green: 0.995, blue: 0.974)
    static let forest = Color(red: 0.09, green: 0.23, blue: 0.20)
    static let ink = Color(red: 0.12, green: 0.21, blue: 0.19)
    static let muted = Color(red: 0.38, green: 0.43, blue: 0.40)
    static let sage = Color(red: 0.84, green: 0.88, blue: 0.81)
    static let line = Color(red: 0.87, green: 0.89, blue: 0.84)
    static let amber = Color(red: 0.56, green: 0.36, blue: 0.20)
    static let rose = Color(red: 0.57, green: 0.27, blue: 0.24)
    static func painColor(_ intensity: Int) -> Color { intensity <= 3 ? forest : intensity <= 6 ? amber : rose }
}

struct PaperCard: ViewModifier {
    var padding: CGFloat = 20
    func body(content: Content) -> some View {
        content.padding(padding).background(HeadlyTheme.paper, in: RoundedRectangle(cornerRadius: 24))
            .overlay(RoundedRectangle(cornerRadius: 24).stroke(HeadlyTheme.line.opacity(0.6), lineWidth: 0.6))
    }
}
extension View { func paperCard(_ padding: CGFloat = 20) -> some View { modifier(PaperCard(padding: padding)) } }

struct PrimaryButton: View {
    let title: String
    var symbol = "plus"
    var light = false
    var disabled = false
    let action: () -> Void
    var body: some View {
        Button(action: action) {
            HStack(spacing: 9) { Image(systemName: symbol); Text(title).fontWeight(.semibold) }
                .font(.system(.body)).frame(maxWidth: .infinity).frame(minHeight: 54)
                .foregroundStyle(light ? HeadlyTheme.forest : .white)
                .background(light ? HeadlyTheme.paper : HeadlyTheme.forest, in: RoundedRectangle(cornerRadius: 17))
        }.buttonStyle(.plain).disabled(disabled).opacity(disabled ? 0.4 : 1)
    }
}

struct SectionHeading: View {
    let title: String
    var subtitle: String? = nil
    var body: some View {
        HStack(alignment: .firstTextBaseline) {
            Text(title).font(.system(.headline)).foregroundStyle(HeadlyTheme.ink)
            Spacer()
            if let subtitle { Text(subtitle).font(.system(.caption)).foregroundStyle(HeadlyTheme.muted) }
        }
    }
}

struct OrbitArtwork: View {
    var body: some View {
        Canvas { context, size in
            for index in 0..<9 {
                var path = Path()
                let inset = CGFloat(index) * 6
                path.addEllipse(in: CGRect(x: inset, y: 10 + inset * 0.45, width: size.width - inset * 2, height: size.height - 20 - inset * 0.8))
                var transformed = context
                transformed.translateBy(x: size.width / 2, y: size.height / 2)
                transformed.rotate(by: .degrees(-24))
                transformed.translateBy(x: -size.width / 2, y: -size.height / 2)
                transformed.stroke(path, with: .color(HeadlyTheme.sage.opacity(Double(index) * 0.025 + 0.14)), lineWidth: 0.7)
            }
        }.accessibilityHidden(true)
    }
}

struct RecordRow: View {
    let record: HeadacheRecord
    var body: some View {
        HStack(spacing: 14) {
            ZStack {
                RoundedRectangle(cornerRadius: 14).fill(HeadlyTheme.painColor(record.intensity).opacity(0.09))
                Text("\(record.intensity)").font(.system(.title2, design: .serif)).foregroundStyle(HeadlyTheme.painColor(record.intensity))
            }.frame(width: 46, height: 50)
            VStack(alignment: .leading, spacing: 6) {
                Text(record.title).font(.system(.subheadline, weight: .semibold)).foregroundStyle(HeadlyTheme.ink)
                HStack(spacing: 6) {
                    Text(record.startedAt, format: .dateTime.month(.twoDigits).day(.twoDigits).hour().minute())
                    Text("·")
                    Text(record.isOngoing ? "进行中" : durationText(record.duration()))
                }.font(.system(.caption)).foregroundStyle(HeadlyTheme.muted)
            }
            Spacer(minLength: 2)
            Image(systemName: "chevron.right").font(.system(size: 10, weight: .semibold)).foregroundStyle(HeadlyTheme.muted)
        }.frame(minHeight: 56)
            .accessibilityElement(children: .combine)
    }
}

struct ChipGroup: View {
    let options: [String]
    @Binding var selected: [String]
    var columns = 3
    var single = false
    var body: some View {
        LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 8), count: columns), spacing: 8) {
            ForEach(options, id: \.self) { option in
                let active = selected.contains(option)
                Button {
                    if single { selected = active ? [] : [option] }
                    else if active { selected.removeAll { $0 == option } }
                    else { selected.append(option) }
                } label: {
                    Text(option).font(.system(.subheadline)).frame(maxWidth: .infinity).frame(minHeight: 44)
                        .foregroundStyle(active ? HeadlyTheme.forest : HeadlyTheme.muted)
                        .background(active ? HeadlyTheme.sage.opacity(0.65) : HeadlyTheme.paper, in: RoundedRectangle(cornerRadius: 13))
                        .overlay(RoundedRectangle(cornerRadius: 13).stroke(active ? HeadlyTheme.forest.opacity(0.3) : HeadlyTheme.line, lineWidth: 1))
                }.buttonStyle(.plain).accessibilityAddTraits(active ? .isSelected : [])
            }
        }
    }
}
